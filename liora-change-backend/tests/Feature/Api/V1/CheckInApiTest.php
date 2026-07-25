<?php

namespace Tests\Feature\Api\V1;

use App\Models\Challenge;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CheckInApiTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(): array
    {
        $user = User::factory()->create(['xp_total' => 0, 'level' => 1]);
        $token = $user->createToken('api')->plainTextToken;

        return [$user, $token];
    }

    private function activeChallenge(int $userId, array $overrides = []): Challenge
    {
        return Challenge::factory()->create(array_merge([
            'user_id' => $userId,
            'status' => 'active',
            'duration_days' => 7,
            'current_streak' => 0,
            'longest_streak' => 0,
        ], $overrides));
    }

    public function test_completed_check_in_awards_xp_and_increments_streak(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", [
                'status' => 'completed',
                'note' => 'Felt great',
                'mood' => 4,
                'energy' => 3,
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'data' => [
                    'check_in' => [
                        'challenge_id' => $challenge->id,
                        'status' => 'completed',
                        'note' => 'Felt great',
                        'mood' => 4,
                        'energy' => 3,
                        'xp_earned' => 10,
                        'streak_after' => 1,
                    ],
                    'summary' => [
                        'current_streak' => 1,
                        'longest_streak' => 1,
                        'xp_total' => 10,
                        'xp_earned' => 10,
                        'recovery_available' => false,
                    ],
                ],
            ]);

        $this->assertSame(10, $user->refresh()->xp_total);
        $this->assertSame(1, $user->level);
        $this->assertDatabaseHas('xp_ledgers', [
            'user_id' => $user->id,
            'challenge_id' => $challenge->id,
            'amount' => 10,
            'reason' => 'check_in_completed',
        ]);
    }

    public function test_two_completed_check_ins_on_consecutive_days_gives_streak_of_two(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", [
                'status' => 'completed',
                'check_in_date' => '2026-07-24',
            ])->assertStatus(201);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", [
                'status' => 'completed',
                'check_in_date' => '2026-07-25',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'data' => [
                    'check_in' => ['streak_after' => 2],
                    'summary' => ['current_streak' => 2, 'longest_streak' => 2, 'xp_total' => 20],
                ],
            ]);
    }

    public function test_skipped_check_in_resets_streak_and_flags_recovery(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id, ['current_streak' => 3, 'longest_streak' => 3]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", [
                'status' => 'skipped',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'data' => [
                    'check_in' => ['status' => 'skipped', 'xp_earned' => 0, 'streak_after' => 0],
                    'summary' => [
                        'current_streak' => 0,
                        'longest_streak' => 3,
                        'xp_earned' => 0,
                        'recovery_available' => true,
                    ],
                ],
            ]);

        $this->assertSame(0, $user->refresh()->xp_total);
    }

    public function test_check_in_on_non_active_challenge_returns_challenge_not_active(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id, ['status' => 'draft']);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", [
                'status' => 'completed',
            ]);

        $response->assertStatus(422)
            ->assertJson(['code' => 'CHALLENGE_NOT_ACTIVE']);
    }

    public function test_second_check_in_same_date_upserts_consistently(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", [
                'status' => 'completed',
                'check_in_date' => '2026-07-25',
            ])->assertStatus(201);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", [
                'status' => 'skipped',
                'check_in_date' => '2026-07-25',
                'note' => 'Changed my mind',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'data' => ['check_in' => ['status' => 'skipped', 'note' => 'Changed my mind']],
            ]);

        $this->assertDatabaseCount('check_ins', 1);
    }

    public function test_index_returns_only_that_challenges_check_ins_newest_first(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);
        $otherChallenge = $this->activeChallenge($user->id);

        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", ['status' => 'completed', 'check_in_date' => '2026-07-20']);
        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", ['status' => 'completed', 'check_in_date' => '2026-07-21']);
        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$otherChallenge->id}/check-ins", ['status' => 'completed', 'check_in_date' => '2026-07-20']);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson("/api/v1/challenges/{$challenge->id}/check-ins");

        $response->assertStatus(200);
        $data = $response->json('data');
        $this->assertCount(2, $data);
        $this->assertSame('2026-07-21', $data[0]['check_in_date']);
        $this->assertSame('2026-07-20', $data[1]['check_in_date']);
    }

    public function test_check_in_on_another_users_challenge_is_forbidden(): void
    {
        [$owner] = $this->actingUser();
        [, $otherToken] = $this->actingUser();
        $challenge = $this->activeChallenge($owner->id);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$otherToken])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", ['status' => 'completed']);

        $this->assertContains($response->status(), [403, 404]);
    }

    public function test_invalid_status_value_returns_validation_error(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = $this->activeChallenge($user->id);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", ['status' => 'missed']);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['status']);
    }

    public function test_check_ins_require_authentication(): void
    {
        $challenge = Challenge::factory()->create(['status' => 'active']);

        $this->postJson("/api/v1/challenges/{$challenge->id}/check-ins", ['status' => 'completed'])
            ->assertStatus(401);
        $this->getJson("/api/v1/challenges/{$challenge->id}/check-ins")
            ->assertStatus(401);
    }
}
