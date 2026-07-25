<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;

class PreferencesTest extends TestCase
{
    use RefreshDatabase;
    protected $seed = true;

    public function test_user_can_view_preferences()
    {
        $user = User::factory()->create();
        $user->preferences()->create(['dark_mode' => true]);

        $response = $this->actingAs($user)->getJson('/api/v1/preferences');

        $response->assertStatus(200)
                 ->assertJsonPath('data.preferences.dark_mode', true);
    }

    public function test_user_can_update_preferences()
    {
        $user = User::factory()->create();
        $user->preferences()->create();

        $response = $this->actingAs($user)->putJson('/api/v1/preferences', [
            'dark_mode' => true,
            'theme' => 'dark_theme',
        ]);

        $response->assertStatus(200)
                 ->assertJsonPath('data.preferences.dark_mode', true)
                 ->assertJsonPath('data.preferences.theme', 'dark_theme');
    }
}
