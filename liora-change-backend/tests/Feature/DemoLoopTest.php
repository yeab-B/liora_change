<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/**
 * Runs the full hackathon demo story end-to-end against real HTTP endpoints
 * in one sequence (docs/mvp/issues/09-testing-qa.md Part 2). This is the
 * ground truth that the whole product works together, independent of any
 * single dev's own Feature tests.
 */
class DemoLoopTest extends TestCase
{
    use RefreshDatabase;

    public function test_full_demo_story_end_to_end(): void
    {
        config(['services.openai.key' => null]);

        // 1. POST /api/v1/auth/register -> 201, get token
        $register = $this->postJson('/api/v1/auth/register', [
            'name' => 'Demo User',
            'email' => 'demo-loop@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
            'timezone' => 'UTC',
        ]);
        $register->assertStatus(201);
        $token = $register->json('data.token');
        $this->assertNotEmpty($token);
        $authHeader = ['Authorization' => 'Bearer '.$token];

        // 2. GET /api/v1/me -> 200, xp_total=0
        $this->withHeaders($authHeader)
            ->getJson('/api/v1/me')
            ->assertStatus(200)
            ->assertJson(['data' => ['xp_total' => 0]]);

        // 3. POST /api/v1/challenges -> 201, status=draft
        $createChallenge = $this->withHeaders($authHeader)->postJson('/api/v1/challenges', [
            'title' => 'Morning Walk',
            'duration_days' => 7,
        ]);
        $createChallenge->assertStatus(201)->assertJson(['data' => ['status' => 'draft']]);
        $challengeId = $createChallenge->json('data.id');
        $this->assertNotEmpty($challengeId);

        // 4. POST /api/v1/challenges/{id}/activate -> 200, status=active
        $this->withHeaders($authHeader)
            ->postJson("/api/v1/challenges/{$challengeId}/activate")
            ->assertStatus(200)
            ->assertJson(['data' => ['status' => 'active']]);

        // 5. POST check-ins {status: completed} -> 201, streak=1, xp_earned=10
        $this->withHeaders($authHeader)
            ->postJson("/api/v1/challenges/{$challengeId}/check-ins", ['status' => 'completed'])
            ->assertStatus(201)
            ->assertJson([
                'data' => [
                    'summary' => [
                        'current_streak' => 1,
                        'xp_earned' => 10,
                    ],
                ],
            ]);

        // 6. GET /api/v1/dashboard -> 200, active_challenges[0].checked_in_today=true
        $dashboard = $this->withHeaders($authHeader)->getJson('/api/v1/dashboard');
        $dashboard->assertStatus(200);
        $this->assertTrue($dashboard->json('data.active_challenges.0.checked_in_today'));

        // 7. POST check-ins {status: skipped, check_in_date: tomorrow} -> 201, streak reset
        $tomorrow = Carbon::now('UTC')->addDay()->toDateString();
        $this->withHeaders($authHeader)
            ->postJson("/api/v1/challenges/{$challengeId}/check-ins", [
                'status' => 'skipped',
                'check_in_date' => $tomorrow,
            ])
            ->assertStatus(201)
            ->assertJson(['data' => ['summary' => ['current_streak' => 0]]]);

        // 8. GET /api/v1/recovery/current -> 200, active=true
        $this->withHeaders($authHeader)
            ->getJson('/api/v1/recovery/current')
            ->assertStatus(200)
            ->assertJson(['data' => ['active' => true, 'challenge_id' => $challengeId]]);

        // 9. POST check-ins {status: completed, check_in_date: day after} -> 201
        $dayAfter = Carbon::now('UTC')->addDays(2)->toDateString();
        $this->withHeaders($authHeader)
            ->postJson("/api/v1/challenges/{$challengeId}/check-ins", [
                'status' => 'completed',
                'check_in_date' => $dayAfter,
            ])
            ->assertStatus(201);

        // 10. GET /api/v1/recovery/current -> 200, active=false
        $this->withHeaders($authHeader)
            ->getJson('/api/v1/recovery/current')
            ->assertStatus(200)
            ->assertJson(['data' => ['active' => false]]);

        // 11. POST /api/v1/ai/motivation {challenge_id} -> 200, message mentions
        // challenge title, source in [openai, template]
        $motivation = $this->withHeaders($authHeader)
            ->postJson('/api/v1/ai/motivation', ['challenge_id' => $challengeId]);
        $motivation->assertStatus(200);
        $this->assertContains($motivation->json('data.source'), ['openai', 'template']);
        $this->assertStringContainsString('Morning Walk', $motivation->json('data.message'));

        // 12. POST /api/v1/ai/chat {message} -> 200, session_id present, message.role=assistant
        $chat = $this->withHeaders($authHeader)
            ->postJson('/api/v1/ai/chat', ['message' => 'What if I miss a day?']);
        $chat->assertStatus(200);
        $this->assertNotEmpty($chat->json('data.session_id'));
        $this->assertSame('assistant', $chat->json('data.message.role'));

        // 13. POST /api/v1/auth/logout -> 200
        $this->withHeaders($authHeader)
            ->postJson('/api/v1/auth/logout')
            ->assertStatus(200);

        // 14. GET /api/v1/me (same token) -> 401
        $this->withHeaders($authHeader)
            ->getJson('/api/v1/me')
            ->assertStatus(401);
    }

    /**
     * Same story, but forcing the OpenAI path (mocked) for step 11/12
     * instead of the template fallback, so both AI code paths are proven to
     * work end-to-end at least once.
     */
    public function test_full_demo_story_with_openai_mocked(): void
    {
        config(['services.openai.key' => 'test-key']);
        Http::fake([
            'api.openai.com/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Keep going with Morning Walk, you are doing great!']],
                ],
            ], 200),
        ]);

        $register = $this->postJson('/api/v1/auth/register', [
            'name' => 'Demo User Two',
            'email' => 'demo-loop-openai@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
            'timezone' => 'UTC',
        ]);
        $token = $register->json('data.token');
        $authHeader = ['Authorization' => 'Bearer '.$token];

        $challenge = $this->withHeaders($authHeader)->postJson('/api/v1/challenges', [
            'title' => 'Morning Walk',
            'duration_days' => 7,
        ]);
        $challengeId = $challenge->json('data.id');

        $this->withHeaders($authHeader)->postJson("/api/v1/challenges/{$challengeId}/activate");

        $motivation = $this->withHeaders($authHeader)
            ->postJson('/api/v1/ai/motivation', ['challenge_id' => $challengeId]);
        $motivation->assertStatus(200)->assertJson([
            'data' => [
                'source' => 'openai',
                'message' => 'Keep going with Morning Walk, you are doing great!',
            ],
        ]);

        $chat = $this->withHeaders($authHeader)
            ->postJson('/api/v1/ai/chat', ['message' => 'What if I miss a day?']);
        $chat->assertStatus(200);
        $this->assertSame('assistant', $chat->json('data.message.role'));
        $this->assertNotEmpty($chat->json('data.message.content'));
    }
}
