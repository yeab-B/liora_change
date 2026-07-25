<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;

class ProfileTest extends TestCase
{
    use RefreshDatabase;
    protected $seed = true;

    public function test_user_can_view_profile()
    {
        $user = User::factory()->create();
        $user->profile()->create(['first_name' => 'John']);

        $response = $this->actingAs($user)->getJson('/api/v1/profile');

        $response->assertStatus(200)
                 ->assertJsonPath('data.profile.first_name', 'John');
    }

    public function test_user_can_update_profile()
    {
        $user = User::factory()->create();
        $user->profile()->create();

        $response = $this->actingAs($user)->putJson('/api/v1/profile', [
            'first_name' => 'Jane',
            'last_name' => 'Smith',
        ]);

        $response->assertStatus(200)
                 ->assertJsonPath('data.profile.first_name', 'Jane')
                 ->assertJsonPath('data.profile.last_name', 'Smith');
    }
}
