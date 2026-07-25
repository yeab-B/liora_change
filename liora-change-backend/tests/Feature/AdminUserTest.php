<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Shared\Enums\RoleName;

class AdminUserTest extends TestCase
{
    use RefreshDatabase;
    protected $seed = true;

    public function test_admin_can_list_users()
    {
        $admin = User::where('email', 'admin@liorachange.com')->first();
        
        $response = $this->actingAs($admin)->getJson('/api/v1/admin/users');

        $response->assertStatus(200)
                 ->assertJsonStructure(['data' => ['users']]);
    }

    public function test_regular_user_cannot_list_users()
    {
        $user = User::factory()->create();
        $user->assignRole(RoleName::FreeUser->value);

        $response = $this->actingAs($user)->getJson('/api/v1/admin/users');

        $response->assertStatus(403);
    }

    public function test_admin_can_create_user()
    {
        $admin = User::where('email', 'admin@liorachange.com')->first();
        
        $response = $this->actingAs($admin)->postJson('/api/v1/admin/users', [
            'name' => 'New User',
            'email' => 'new@user.com',
            'password' => 'password',
            'role' => RoleName::PremiumUser->value,
            'status' => 'active',
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('users', ['email' => 'new@user.com']);
        $this->assertTrue(User::where('email', 'new@user.com')->first()->hasRole(RoleName::PremiumUser->value));
    }

    public function test_admin_can_update_user()
    {
        $admin = User::where('email', 'admin@liorachange.com')->first();
        $user = User::factory()->create();

        $response = $this->actingAs($admin)->putJson('/api/v1/admin/users/' . $user->id, [
            'name' => 'Updated Name',
            'status' => 'inactive',
        ]);

        $response->assertStatus(200)
                 ->assertJsonPath('data.user.name', 'Updated Name')
                 ->assertJsonPath('data.user.status', 'inactive');
    }

    public function test_admin_can_delete_user()
    {
        $admin = User::where('email', 'admin@liorachange.com')->first();
        $user = User::factory()->create();

        $response = $this->actingAs($admin)->deleteJson('/api/v1/admin/users/' . $user->id);

        $response->assertStatus(200)
                 ->assertJsonPath('success', true);
                 
        $this->assertSoftDeleted('users', ['id' => $user->id]);
    }
}
