<?php

namespace Tests\Feature\Api\V1;

use App\Models\Challenge;
use App\Models\CheckIn;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardApiTest extends TestCase
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
            'duration_days' => 7,
        ], $overrides));
    }

    public function test_dashboard_with_no_challenges_returns_empty_state(): void
    {
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/dashboard');

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'today' => [
                        'active_challenges_count' => 0,
                        'completed_checkins_count' => 0,
                        'pending_checkins_count' => 0,
                    ],
                    'active_challenges' => [],
                    'recovery' => ['active' => false],
                    'motivation_preview' => null,
                ],
            ]);
    }

    public function test_dashboard_with_one_active_challenge_and_no_check_in_today_has_one_pending(): void
    {
        [$user, $token] = $this->actingUser();
        $this->activeChallenge($user->id);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/dashboard');

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'today' => [
                        'active_challenges_count' => 1,
                        'completed_checkins_count' => 0,
                        'pending_checkins_count' => 1,
                    ],
                ],
            ]);

        $this->assertCount(1, $response->json('data.active_challenges'));
        $this->assertFalse($response->json('data.active_challenges.0.checked_in_today'));
    }

    public function test_dashboard_after_completing_todays_check_in_shows_checked_in_and_no_pending(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", ['status' => 'completed'])
            ->assertStatus(201);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/dashboard');

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'today' => [
                        'active_challenges_count' => 1,
                        'completed_checkins_count' => 1,
                        'pending_checkins_count' => 0,
                    ],
                    'active_challenges' => [
                        ['checked_in_today' => true],
                    ],
                ],
            ]);
    }

    public function test_dashboard_reflects_active_recovery(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id, ['current_streak' => 0]);

        CheckIn::factory()->create([
            'user_id' => $user->id,
            'challenge_id' => $challenge->id,
            'check_in_date' => now()->subDay()->toDateString(),
            'status' => 'skipped',
            'xp_earned' => 0,
            'streak_after' => 0,
        ]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/dashboard');

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'recovery' => [
                        'active' => true,
                        'challenge_id' => $challenge->id,
                        'reason' => 'skipped',
                    ],
                ],
            ]);
    }

    /**
     * Added by Issue #9's endpoint coverage audit — GET /progress had no
     * happy-path test anywhere in the suite before this.
     */
    public function test_progress_returns_aggregate_stats_across_challenges(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", ['status' => 'completed'])
            ->assertStatus(201);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/progress');

        $response->assertStatus(200)->assertJson([
            'data' => [
                'xp_total' => 10,
                'completed_checkins' => 1,
                'skipped_checkins' => 0,
                'active_challenges' => 1,
                'completed_challenges' => 0,
            ],
        ]);
    }

    public function test_progress_requires_authentication(): void
    {
        $this->getJson('/api/v1/progress')->assertStatus(401);
    }

    public function test_dashboard_requires_authentication(): void
    {
        $this->getJson('/api/v1/dashboard')->assertStatus(401);
    }
}
