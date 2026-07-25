<?php

namespace Tests\Feature;

use App\Models\Challenge;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Verifies the global `{ message, code, [errors] }` envelope registered in
 * bootstrap/app.php (docs/mvp/issues/09-testing-qa.md Part 1) is actually
 * applied for every exception type it claims to cover.
 */
class ErrorFormatTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(array $overrides = []): array
    {
        $user = User::factory()->create(array_merge(['timezone' => 'UTC'], $overrides));
        $token = $user->createToken('api')->plainTextToken;

        return [$user, $token];
    }

    public function test_invalid_payload_returns_validation_error_envelope(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'email' => 'not-an-email',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'message' => 'The given data was invalid.',
                'code' => 'VALIDATION_ERROR',
            ])
            ->assertJsonStructure(['message', 'code', 'errors']);

        $this->assertArrayHasKey('name', $response->json('errors'));
        $this->assertArrayHasKey('email', $response->json('errors'));
        $this->assertArrayHasKey('password', $response->json('errors'));
    }

    public function test_unauthenticated_request_returns_unauthenticated_envelope(): void
    {
        $response = $this->getJson('/api/v1/me');

        $response->assertStatus(401)->assertExactJson([
            'message' => 'Unauthenticated.',
            'code' => 'UNAUTHENTICATED',
        ]);
    }

    public function test_nonexistent_resource_returns_not_found_envelope(): void
    {
        [, $token] = $this->actingUser();

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->getJson('/api/v1/challenges/999999');

        $response->assertStatus(404)->assertExactJson([
            'message' => 'Resource not found.',
            'code' => 'NOT_FOUND',
        ]);
    }

    public function test_forbidden_action_returns_forbidden_envelope(): void
    {
        [$owner] = $this->actingUser();
        [, $otherToken] = $this->actingUser();
        $challenge = Challenge::factory()->create(['user_id' => $owner->id]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$otherToken])
            ->getJson("/api/v1/challenges/{$challenge->id}");

        $response->assertStatus(403)->assertExactJson([
            'message' => 'This action is unauthorized.',
            'code' => 'FORBIDDEN',
        ]);
    }

    public function test_business_rule_exception_returns_its_own_envelope(): void
    {
        [$user, $token] = $this->actingUser();
        $challenge = Challenge::factory()->create(['user_id' => $user->id, 'status' => 'active']);

        // Active -> Active is not an allowed transition (ChallengeService::canTransition),
        // so this exercises InvalidStatusTransitionException's existing ad-hoc 422 envelope.
        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson("/api/v1/challenges/{$challenge->id}/activate");

        $response->assertStatus(422)->assertJson([
            'code' => 'INVALID_STATUS_TRANSITION',
        ]);
        $this->assertArrayHasKey('message', $response->json());
    }
}
