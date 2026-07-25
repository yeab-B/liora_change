<?php

namespace Tests\Feature\Api\V1;

use App\Models\Badge;
use App\Models\Challenge;
use App\Models\User;
use App\Models\XpLedger;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GamificationApiTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(array $overrides = []): array
    {
        $user = User::factory()->create(array_merge(['timezone' => 'UTC', 'xp_total' => 0, 'level' => 1], $overrides));
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

    private function seedBadges(): void
    {
        Badge::factory()->create(['code' => 'first_checkin', 'name' => 'First Step']);
        Badge::factory()->create(['code' => 'streak_3', 'name' => 'On a Roll']);
        Badge::factory()->create(['code' => 'comeback', 'name' => 'The Comeback']);
    }

    private function checkIn(string $token, Challenge $challenge, array $payload): void
    {
        $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/check-ins", $payload)
            ->assertStatus(201);
    }

    public function test_xp_history_returns_ledger_newest_first_for_authenticated_user_only(): void
    {
        [$userA, $tokenA] = $this->actingUser();
        [$userB] = $this->actingUser();

        XpLedger::factory()->create([
            'user_id' => $userA->id,
            'amount' => 10,
            'reason' => 'check_in_completed',
            'created_at' => now()->subMinutes(10),
        ]);
        XpLedger::factory()->create([
            'user_id' => $userA->id,
            'amount' => 5,
            'reason' => 'daily_reward',
            'created_at' => now(),
        ]);
        XpLedger::factory()->create([
            'user_id' => $userB->id,
            'amount' => 10,
            'reason' => 'check_in_completed',
        ]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$tokenA])
            ->getJson('/api/v1/xp/history');

        $response->assertStatus(200);
        $data = $response->json('data');
        $this->assertCount(2, $data);
        $this->assertSame('daily_reward', $data[0]['reason']);
        $this->assertSame('check_in_completed', $data[1]['reason']);
    }

    public function test_badges_unlocked_returns_only_authenticated_users_badges(): void
    {
        [$userA, $tokenA] = $this->actingUser();
        [$userB, $tokenB] = $this->actingUser();
        $this->seedBadges();
        $badge = Badge::where('code', 'first_checkin')->first();

        $challengeA = $this->activeChallenge($userA->id);
        $this->checkIn($tokenA, $challengeA, ['status' => 'completed']);

        $responseA = $this->withHeaders(['Authorization' => 'Bearer '.$tokenA])->getJson('/api/v1/badges/unlocked');
        $responseA->assertStatus(200);
        $this->assertCount(1, $responseA->json('data'));
        $this->assertSame($badge->code, $responseA->json('data.0.code'));

        $responseB = $this->withHeaders(['Authorization' => 'Bearer '.$tokenB])->getJson('/api/v1/badges/unlocked');
        $responseB->assertStatus(200);
        $this->assertCount(0, $responseB->json('data'));
    }

    public function test_first_completed_check_in_unlocks_first_checkin_badge(): void
    {
        [$user, $token] = $this->actingUser();
        $this->seedBadges();
        $challenge = $this->activeChallenge($user->id);

        $this->checkIn($token, $challenge, ['status' => 'completed']);

        $badge = Badge::where('code', 'first_checkin')->first();
        $this->assertDatabaseHas('user_badges', [
            'user_id' => $user->id,
            'badge_id' => $badge->id,
        ]);
    }

    public function test_reaching_streak_of_three_unlocks_streak_3_badge(): void
    {
        [$user, $token] = $this->actingUser();
        $this->seedBadges();
        $challenge = $this->activeChallenge($user->id);

        $this->checkIn($token, $challenge, ['status' => 'completed', 'check_in_date' => '2026-07-20']);
        $this->checkIn($token, $challenge, ['status' => 'completed', 'check_in_date' => '2026-07-21']);
        $this->checkIn($token, $challenge, ['status' => 'completed', 'check_in_date' => '2026-07-22']);

        $badge = Badge::where('code', 'streak_3')->first();
        $this->assertDatabaseHas('user_badges', [
            'user_id' => $user->id,
            'badge_id' => $badge->id,
        ]);
    }

    public function test_completed_check_in_right_after_a_skipped_one_unlocks_comeback_badge(): void
    {
        [$user, $token] = $this->actingUser();
        $this->seedBadges();
        $challenge = $this->activeChallenge($user->id);

        $this->checkIn($token, $challenge, ['status' => 'skipped', 'check_in_date' => '2026-07-24']);
        $this->checkIn($token, $challenge, ['status' => 'completed', 'check_in_date' => '2026-07-25']);

        $badge = Badge::where('code', 'comeback')->first();
        $this->assertDatabaseHas('user_badges', [
            'user_id' => $user->id,
            'badge_id' => $badge->id,
        ]);
    }

    public function test_daily_reward_claim_succeeds_once_then_rejects_second_claim_same_day(): void
    {
        [$user, $token] = $this->actingUser();

        $first = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/rewards/daily/claim');

        $first->assertStatus(200)
            ->assertJson([
                'data' => ['claimed' => true, 'xp_earned' => 5, 'xp_total' => 5],
            ]);

        $second = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/rewards/daily/claim');

        $second->assertStatus(422)
            ->assertJson(['code' => 'ALREADY_CLAIMED']);

        $this->assertSame(5, $user->refresh()->xp_total);
    }

    public function test_gamification_routes_require_authentication(): void
    {
        $this->getJson('/api/v1/xp/history')->assertStatus(401);
        $this->getJson('/api/v1/badges/unlocked')->assertStatus(401);
        $this->postJson('/api/v1/rewards/daily/claim')->assertStatus(401);
    }
}
