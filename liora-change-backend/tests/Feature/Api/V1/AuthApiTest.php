<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_with_valid_data_returns_created_user_and_token(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Alex Demo',
            'email' => 'alex@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
            'timezone' => 'Africa/Addis_Ababa',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'data' => [
                    'user' => [
                        'name' => 'Alex Demo',
                        'email' => 'alex@example.com',
                        'timezone' => 'Africa/Addis_Ababa',
                        'xp_total' => 0,
                        'level' => 1,
                        'current_streak' => 0,
                        'longest_streak' => 0,
                    ],
                ],
            ])
            ->assertJsonStructure([
                'data' => [
                    'user' => ['id', 'name', 'email', 'timezone', 'xp_total', 'level', 'current_streak', 'longest_streak'],
                    'token',
                ],
            ]);

        $this->assertNotEmpty($response->json('data.token'));
        $this->assertDatabaseHas('users', ['email' => 'alex@example.com']);
    }

    public function test_register_with_duplicate_email_returns_validation_error(): void
    {
        User::factory()->create(['email' => 'duplicate@example.com']);

        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Someone Else',
            'email' => 'duplicate@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);

        $response->assertStatus(422)
            ->assertJsonStructure(['message', 'code', 'errors' => ['email']])
            ->assertJsonValidationErrors(['email']);
    }

    public function test_register_with_mismatched_password_confirmation_returns_validation_error(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Alex Demo',
            'email' => 'alex2@example.com',
            'password' => 'password',
            'password_confirmation' => 'different',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    public function test_login_with_correct_credentials_returns_token(): void
    {
        $user = User::factory()->create([
            'email' => 'alex@example.com',
            'password' => 'password',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'password',
            'device_name' => 'flutter_android',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => ['user' => ['id', 'name', 'email', 'timezone', 'xp_total', 'level', 'current_streak', 'longest_streak'], 'token'],
            ]);

        $this->assertNotEmpty($response->json('data.token'));
    }

    public function test_login_with_wrong_password_returns_error(): void
    {
        $user = User::factory()->create([
            'email' => 'alex@example.com',
            'password' => 'password',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'wrong-password',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'code' => 'INVALID_CREDENTIALS',
            ])
            ->assertJsonValidationErrors(['email']);
    }

    public function test_login_with_unknown_email_returns_error(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'nobody@example.com',
            'password' => 'password',
        ]);

        $response->assertStatus(422)
            ->assertJson(['code' => 'INVALID_CREDENTIALS']);
    }

    public function test_me_without_token_returns_unauthenticated(): void
    {
        $response = $this->getJson('/api/v1/me');

        $response->assertStatus(401)
            ->assertJson(['code' => 'UNAUTHENTICATED']);
    }

    public function test_me_with_valid_token_returns_user(): void
    {
        $user = User::factory()->create([
            'name' => 'Alex Demo',
            'timezone' => 'Africa/Addis_Ababa',
        ]);
        $token = $user->createToken('api')->plainTextToken;

        $response = $this->withHeaders([
            'Authorization' => 'Bearer '.$token,
        ])->getJson('/api/v1/me');

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'id' => $user->id,
                    'name' => 'Alex Demo',
                    'email' => $user->email,
                    'timezone' => 'Africa/Addis_Ababa',
                ],
            ]);
    }

    public function test_update_me_persists_name_and_timezone(): void
    {
        $user = User::factory()->create(['name' => 'Old Name']);
        $token = $user->createToken('api')->plainTextToken;

        $response = $this->withHeaders([
            'Authorization' => 'Bearer '.$token,
        ])->patchJson('/api/v1/me', [
            'name' => 'Alex',
            'timezone' => 'Africa/Addis_Ababa',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'name' => 'Alex',
                    'timezone' => 'Africa/Addis_Ababa',
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Alex',
            'timezone' => 'Africa/Addis_Ababa',
        ]);
    }

    public function test_logout_revokes_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        $response = $this->withHeaders([
            'Authorization' => 'Bearer '.$token,
        ])->postJson('/api/v1/auth/logout');

        $response->assertStatus(200)
            ->assertJson(['message' => 'Logged out']);

        $this->assertSame(0, PersonalAccessToken::count());

        $reuse = $this->withHeaders([
            'Authorization' => 'Bearer '.$token,
        ])->getJson('/api/v1/me');

        $reuse->assertStatus(401);
    }
}
