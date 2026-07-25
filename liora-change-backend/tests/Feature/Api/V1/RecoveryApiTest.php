<?php

namespace Tests\Feature\Api\V1;

use App\Models\Challenge;
use App\Models\CheckIn;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RecoveryApiTest extends TestCase
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

    public function test_recovery_inactive_when_everything_is_on_track(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        CheckIn::factory()->create([
            'user_id' => $user->id,
            'challenge_id' => $challenge->id,
            'check_in_date' => now()->toDateString(),
            'status' => 'completed',
        ]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/recovery/current');

        $response->assertStatus(200)->assertJson(['data' => ['active' => false]]);
    }

    public function test_recovery_active_immediately_after_a_skipped_check_in(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id, ['title' => 'Morning Walk']);

        CheckIn::factory()->create([
            'user_id' => $user->id,
            'challenge_id' => $challenge->id,
            'check_in_date' => now()->subDay()->toDateString(),
            'status' => 'skipped',
            'xp_earned' => 0,
            'streak_after' => 0,
        ]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/recovery/current');

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'active' => true,
                    'challenge_id' => $challenge->id,
                    'challenge_title' => 'Morning Walk',
                    'reason' => 'skipped',
                    'suggested_action' => [
                        'type' => 'check_in',
                        'challenge_id' => $challenge->id,
                        'label' => 'Check in now',
                    ],
                ],
            ]);

        $this->assertNotEmpty($response->json('data.title'));
        $this->assertNotEmpty($response->json('data.message'));
    }

    public function test_recovery_becomes_inactive_after_completing_a_new_check_in(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        CheckIn::factory()->create([
            'user_id' => $user->id,
            'challenge_id' => $challenge->id,
            'check_in_date' => now()->subDay()->toDateString(),
            'status' => 'skipped',
            'xp_earned' => 0,
            'streak_after' => 0,
        ]);

        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", ['status' => 'completed'])
            ->assertStatus(201);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/recovery/current');

        $response->assertStatus(200)->assertJson(['data' => ['active' => false]]);
    }

    public function test_recovery_ignores_skips_older_than_three_days(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        CheckIn::factory()->create([
            'user_id' => $user->id,
            'challenge_id' => $challenge->id,
            'check_in_date' => now()->subDays(5)->toDateString(),
            'status' => 'skipped',
            'xp_earned' => 0,
            'streak_after' => 0,
        ]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/recovery/current');

        $response->assertStatus(200)->assertJson(['data' => ['active' => false]]);
    }

    public function test_recovery_stays_active_at_exactly_three_days_old(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        CheckIn::factory()->create([
            'user_id' => $user->id,
            'challenge_id' => $challenge->id,
            'check_in_date' => now()->subDays(3)->toDateString(),
            'status' => 'skipped',
            'xp_earned' => 0,
            'streak_after' => 0,
        ]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/recovery/current');

        $response->assertStatus(200)->assertJson(['data' => ['active' => true]]);
    }

    public function test_recovery_requires_authentication(): void
    {
        $this->getJson('/api/v1/recovery/current')->assertStatus(401);
    }
}
