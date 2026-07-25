<?php

namespace Tests\Feature\Api\V1;

use App\Models\Challenge;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class MotivationApiTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(array $overrides = []): array
    {
        $user = User::factory()->create(array_merge(['timezone' => 'UTC'], $overrides));
        $token = $user->createToken('api')->plainTextToken;

        return [$user, $token];
    }

    private function activeChallenge(int $userId, array $overrides = []): Challenge
    {
        return Challenge::factory()->create(array_merge([
            'user_id' => $userId,
            'status' => 'active',
            'title' => 'Morning Walk',
            'duration_days' => 7,
        ], $overrides));
    }

    public function test_without_openai_key_falls_back_to_template_mentioning_challenge(): void
    {
        config(['services.openai.key' => null]);
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/motivation', ['challenge_id' => $challenge->id]);

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'source' => 'template',
                    'challenge_id' => $challenge->id,
                    'challenge_title' => 'Morning Walk',
                ],
            ]);

        $this->assertStringContainsString('Morning Walk', $response->json('data.message'));
    }

    public function test_successful_openai_response_is_used_as_the_message(): void
    {
        config(['services.openai.key' => 'test-key']);
        Http::fake([
            'api.openai.com/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Keep walking, you are doing great!']],
                ],
            ], 200),
        ]);

        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/motivation', ['challenge_id' => $challenge->id]);

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'message' => 'Keep walking, you are doing great!',
                    'source' => 'openai',
                    'challenge_id' => $challenge->id,
                ],
            ]);
    }

    public function test_openai_error_falls_back_to_template_gracefully(): void
    {
        config(['services.openai.key' => 'test-key']);
        Http::fake([
            'api.openai.com/*' => Http::response(['error' => 'boom'], 500),
        ]);

        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/motivation', ['challenge_id' => $challenge->id]);

        $response->assertStatus(200)
            ->assertJson(['data' => ['source' => 'template']]);

        $this->assertStringContainsString('Morning Walk', $response->json('data.message'));
    }

    public function test_omitted_challenge_id_auto_selects_users_active_challenge(): void
    {
        config(['services.openai.key' => null]);
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/motivation', []);

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'challenge_id' => $challenge->id,
                    'challenge_title' => $challenge->title,
                ],
            ]);
    }

    public function test_omitted_challenge_id_with_no_challenges_returns_generic_message(): void
    {
        config(['services.openai.key' => null]);
        [$user, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/motivation', []);

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'challenge_id' => null,
                    'challenge_title' => null,
                    'source' => 'template',
                ],
            ]);

        $this->assertNotEmpty($response->json('data.message'));
    }

    public function test_challenge_id_belonging_to_another_user_is_forbidden(): void
    {
        [$owner] = $this->actingUser();
        [, $otherToken] = $this->actingUser();
        $challenge = $this->activeChallenge($owner->id);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$otherToken])
            ->postJson('/api/v1/ai/motivation', ['challenge_id' => $challenge->id]);

        $this->assertContains($response->status(), [403, 404]);
    }

    public function test_missing_challenge_id_returns_404(): void
    {
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/motivation', ['challenge_id' => 999999]);

        $response->assertStatus(404);
    }

    public function test_invalid_context_value_returns_validation_error(): void
    {
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/ai/motivation', ['context' => 'invalid']);

        $response->assertStatus(422)->assertJsonValidationErrors(['context']);
    }

    public function test_motivation_requires_authentication(): void
    {
        $this->postJson('/api/v1/ai/motivation', [])->assertStatus(401);
    }
}
