<?php

namespace Tests\Feature\Api\V1;

use App\Models\Challenge;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ChallengeApiTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, $token];
    }

    public function test_create_challenge_returns_draft_with_defaults(): void
    {
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/challenges', [
                'title' => 'Morning Walk',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'data' => [
                    'title' => 'Morning Walk',
                    'status' => 'draft',
                    'difficulty' => 'beginner',
                    'visibility' => 'private',
                    'duration_days' => 7,
                    'current_streak' => 0,
                    'longest_streak' => 0,
                    'completed_checkins' => 0,
                    'missed_checkins' => 0,
                    'checked_in_today' => false,
                    'progress_percent' => 0,
                ],
            ])
            ->assertJsonStructure([
                'data' => [
                    'id', 'title', 'description', 'status', 'difficulty', 'visibility',
                    'category_id', 'start_date', 'end_date', 'duration_days',
                    'progress_percent', 'current_streak', 'longest_streak',
                    'completed_checkins', 'missed_checkins', 'checked_in_today',
                    'created_at', 'updated_at',
                ],
            ]);

        $this->assertDatabaseHas('challenges', ['title' => 'Morning Walk', 'status' => 'draft']);
    }

    public function test_create_challenge_accepts_legacy_difficulty_score_alias(): void
    {
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/challenges', [
                'title' => 'Read 10 pages',
                'difficulty_score' => 'hard',
            ]);

        $response->assertStatus(201)
            ->assertJson(['data' => ['difficulty' => 'hard']]);
    }

    public function test_create_challenge_with_missing_title_returns_validation_error(): void
    {
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/v1/challenges', []);

        $response->assertStatus(422)
            ->assertJsonStructure(['message', 'code', 'errors' => ['title']])
            ->assertJsonValidationErrors(['title']);
    }

    public function test_index_returns_only_the_authenticated_users_challenges(): void
    {
        [$userA, $tokenA] = $this->actingUser();
        [$userB] = $this->actingUser();

        Challenge::factory()->count(2)->create(['user_id' => $userA->id]);
        Challenge::factory()->count(3)->create(['user_id' => $userB->id]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$tokenA])
            ->getJson('/api/v1/challenges');

        $response->assertStatus(200);
        $this->assertCount(2, $response->json('data'));
    }

    public function test_show_challenge_belonging_to_another_user_is_forbidden(): void
    {
        [$owner] = $this->actingUser();
        [, $otherToken] = $this->actingUser();

        $challenge = Challenge::factory()->create(['user_id' => $owner->id]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$otherToken])
            ->getJson("/api/v1/challenges/{$challenge->id}");

        $this->assertContains($response->status(), [403, 404]);
    }

    public function test_show_own_challenge_returns_it(): void
    {
        [$owner, $token] = $this->actingUser();
        $challenge = Challenge::factory()->create(['user_id' => $owner->id, 'title' => 'Morning Walk']);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson("/api/v1/challenges/{$challenge->id}");

        $response->assertStatus(200)
            ->assertJson(['data' => ['id' => $challenge->id, 'title' => 'Morning Walk']]);
    }

    public function test_activate_draft_challenge_sets_active_status_and_dates(): void
    {
        [$owner, $token] = $this->actingUser();
        $challenge = Challenge::factory()->create([
            'user_id' => $owner->id,
            'status' => 'draft',
            'duration_days' => 7,
        ]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/activate");

        $response->assertStatus(200)
            ->assertJson(['data' => ['status' => 'active']]);

        $this->assertNotNull($response->json('data.start_date'));
        $this->assertNotNull($response->json('data.end_date'));

        $this->assertDatabaseHas('challenges', [
            'id' => $challenge->id,
            'status' => 'active',
        ]);
    }

    public function test_activate_completed_challenge_returns_invalid_status_transition(): void
    {
        [$owner, $token] = $this->actingUser();
        $challenge = Challenge::factory()->create([
            'user_id' => $owner->id,
            'status' => 'completed',
        ]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/activate");

        $response->assertStatus(422)
            ->assertJson([
                'code' => 'INVALID_STATUS_TRANSITION',
                'message' => 'Challenge cannot be activated from completed',
            ]);
    }

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $challenge = Challenge::factory()->create();

        $this->getJson('/api/v1/challenges')->assertStatus(401);
        $this->postJson('/api/v1/challenges', ['title' => 'X'])->assertStatus(401);
        $this->getJson("/api/v1/challenges/{$challenge->id}")->assertStatus(401);
        $this->postJson("/api/v1/challenges/{$challenge->id}/activate")->assertStatus(401);
    }
}
