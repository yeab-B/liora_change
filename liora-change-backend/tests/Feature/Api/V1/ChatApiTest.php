<?php

namespace Tests\Feature\Api\V1;

use App\Models\Challenge;
use App\Models\ChatMessage;
use App\Models\ChatSession;
use App\Models\KnowledgeArticle;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class ChatApiTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(array $overrides = []): array
    {
        $user = User::factory()->create(array_merge(['timezone' => 'UTC'], $overrides));
        $token = $user->createToken('api')->plainTextToken;

        return [$user, $token];
    }

    /**
     * Creating this via the model (rather than raw DB insert) exercises
     * App\Models\KnowledgeArticle's `saved` event -> KnowledgeChunker, so
     * `knowledge_chunks` is populated exactly as it would be in production.
     */
    private function seedRecoveryArticle(): KnowledgeArticle
    {
        return KnowledgeArticle::create([
            'title' => 'Recovery basics',
            'category' => 'recovery',
            'body' => "After a miss, restart with a tiny action instead of quitting; one miss is not a failure.\n\n"
                ."The best way to recover is to make the very next check-in easier than usual, not harder.",
            'is_active' => true,
        ]);
    }

    public function test_first_message_with_no_session_id_creates_a_new_session(): void
    {
        config(['services.openai.key' => null]);
        [$user, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/chat', ['message' => 'Hello there']);

        $response->assertStatus(200)->assertJsonStructure([
            'data' => [
                'session_id',
                'message' => ['id', 'session_id', 'role', 'content', 'created_at'],
                'sources',
                'used_challenge_id',
            ],
        ]);

        $sessionId = $response->json('data.session_id');

        $this->assertDatabaseHas('chat_sessions', ['id' => $sessionId, 'user_id' => $user->id]);
        $this->assertDatabaseHas('chat_messages', [
            'chat_session_id' => $sessionId,
            'role' => 'user',
            'content' => 'Hello there',
        ]);
        $this->assertDatabaseHas('chat_messages', [
            'chat_session_id' => $sessionId,
            'role' => 'assistant',
        ]);
    }

    public function test_follow_up_with_session_id_appends_to_same_session(): void
    {
        config(['services.openai.key' => null]);
        [$user, $token] = $this->actingUser();

        $first = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/chat', ['message' => 'Hello there']);
        $sessionId = $first->json('data.session_id');

        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/chat', ['message' => 'Follow-up question', 'session_id' => $sessionId])
            ->assertStatus(200)
            ->assertJson(['data' => ['session_id' => $sessionId]]);

        $this->assertSame(1, ChatSession::where('user_id', $user->id)->count());
        $this->assertSame(4, ChatMessage::where('chat_session_id', $sessionId)->count());
    }

    public function test_recovery_question_returns_matching_source_via_template_fallback(): void
    {
        config(['services.openai.key' => null]);
        $this->seedRecoveryArticle();
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/chat', ['message' => 'What should I do if I miss a day?']);

        $response->assertStatus(200);
        $this->assertNotEmpty($response->json('data.sources'));
        $this->assertSame('Recovery basics', $response->json('data.sources.0.title'));
        $this->assertStringContainsString('miss', strtolower($response->json('data.message.content')));
    }

    public function test_recovery_question_returns_matching_source_via_openai(): void
    {
        config(['services.openai.key' => 'test-key']);
        Http::fake([
            'api.openai.com/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Missing a day is normal — restart with a tiny action today.']],
                ],
            ], 200),
        ]);

        $this->seedRecoveryArticle();
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/chat', ['message' => 'What should I do if I miss a day?']);

        $response->assertStatus(200)->assertJson([
            'data' => [
                'message' => ['content' => 'Missing a day is normal — restart with a tiny action today.'],
            ],
        ]);
        $this->assertSame('Recovery basics', $response->json('data.sources.0.title'));
    }

    public function test_openai_failure_still_returns_200_with_fallback_reply(): void
    {
        config(['services.openai.key' => 'test-key']);
        Http::fake([
            'api.openai.com/*' => Http::response(['error' => 'boom'], 500),
        ]);

        $this->seedRecoveryArticle();
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/chat', ['message' => 'What should I do if I miss a day?']);

        $response->assertStatus(200);
        $this->assertNotEmpty($response->json('data.message.content'));
    }

    public function test_no_openai_key_never_returns_500(): void
    {
        config(['services.openai.key' => null]);
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/chat', ['message' => 'Hello, is anyone there?']);

        $response->assertStatus(200);
        $this->assertNotEmpty($response->json('data.message.content'));
    }

    public function test_message_over_1000_chars_returns_422(): void
    {
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/chat', ['message' => str_repeat('a', 1001)]);

        $response->assertStatus(422)->assertJsonValidationErrors(['message']);
    }

    public function test_session_id_belonging_to_another_user_is_forbidden(): void
    {
        config(['services.openai.key' => null]);
        [, $ownerToken] = $this->actingUser();
        [, $otherToken] = $this->actingUser();

        $ownerSession = $this->withHeaders(['Authorization' => 'Bearer '.$ownerToken])
            ->postJson('/api/v1/ai/chat', ['message' => 'Hello']);
        $sessionId = $ownerSession->json('data.session_id');

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$otherToken])
            ->postJson('/api/v1/ai/chat', ['message' => 'Hi', 'session_id' => $sessionId]);

        $this->assertContains($response->status(), [403, 404]);
    }

    public function test_unknown_session_id_returns_404(): void
    {
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/chat', ['message' => 'Hi', 'session_id' => 999999]);

        $response->assertStatus(404);
    }

    public function test_challenge_id_belonging_to_another_user_is_forbidden(): void
    {
        config(['services.openai.key' => null]);
        [$owner] = $this->actingUser();
        [, $otherToken] = $this->actingUser();
        $challenge = Challenge::factory()->create(['user_id' => $owner->id, 'status' => 'active']);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$otherToken])
            ->postJson('/api/v1/ai/chat', ['message' => 'Hi', 'challenge_id' => $challenge->id]);

        $this->assertContains($response->status(), [403, 404]);
    }

    public function test_chat_requires_authentication(): void
    {
        $this->postJson('/api/v1/ai/chat', ['message' => 'Hi'])->assertStatus(401);
    }

    /**
     * Added by Issue #9's endpoint coverage audit — the nice-to-have
     * history endpoints only had happy-path/ownership-forbidden tests,
     * not an unauthenticated or unknown-id case.
     */
    public function test_chat_history_endpoints_require_authentication(): void
    {
        $this->getJson('/api/v1/ai/chat/sessions')->assertStatus(401);
        $this->getJson('/api/v1/ai/chat/sessions/1/messages')->assertStatus(401);
    }

    public function test_messages_endpoint_returns_404_for_unknown_session(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/ai/chat/sessions/999999/messages')
            ->assertStatus(404);
    }

    public function test_sessions_and_messages_history_endpoints_return_owned_data(): void
    {
        config(['services.openai.key' => null]);
        [, $token] = $this->actingUser();

        $chat = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/chat', ['message' => 'Hello there']);
        $sessionId = $chat->json('data.session_id');

        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/ai/chat/sessions')
            ->assertStatus(200)
            ->assertJsonFragment(['id' => $sessionId]);

        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson("/api/v1/ai/chat/sessions/{$sessionId}/messages")
            ->assertStatus(200)
            ->assertJsonCount(2, 'data');
    }

    public function test_messages_endpoint_forbids_other_users_session(): void
    {
        config(['services.openai.key' => null]);
        [, $ownerToken] = $this->actingUser();
        [, $otherToken] = $this->actingUser();

        $chat = $this->withHeaders(['Authorization' => 'Bearer '.$ownerToken])
            ->postJson('/api/v1/ai/chat', ['message' => 'Hello there']);
        $sessionId = $chat->json('data.session_id');

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$otherToken])
            ->getJson("/api/v1/ai/chat/sessions/{$sessionId}/messages");

        $this->assertContains($response->status(), [403, 404]);
    }
}
