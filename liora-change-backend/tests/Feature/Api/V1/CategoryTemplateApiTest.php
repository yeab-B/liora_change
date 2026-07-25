<?php

namespace Tests\Feature\Api\V1;

use App\Models\ChallengeCategory;
use App\Models\ChallengeTemplate;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CategoryTemplateApiTest extends TestCase
{
    use RefreshDatabase;

    private function tokenFor(User $user): string
    {
        return $user->createToken('api')->plainTextToken;
    }

    public function test_index_returns_seeded_categories_with_correct_shape(): void
    {
        $user = User::factory()->create();
        $health = ChallengeCategory::factory()->create(['name' => 'Health', 'slug' => 'health']);
        $focus = ChallengeCategory::factory()->create(['name' => 'Focus', 'slug' => 'focus']);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$this->tokenFor($user)])
            ->getJson('/api/v1/challenge-categories');

        $response->assertStatus(200)
            ->assertJsonStructure(['data' => [['id', 'name', 'slug']]])
            ->assertJson([
                'data' => [
                    ['id' => $health->id, 'name' => 'Health', 'slug' => 'health'],
                    ['id' => $focus->id, 'name' => 'Focus', 'slug' => 'focus'],
                ],
            ]);
    }

    public function test_index_returns_seeded_templates_with_correct_shape(): void
    {
        $user = User::factory()->create();
        $category = ChallengeCategory::factory()->create(['name' => 'Health', 'slug' => 'health']);
        $template = ChallengeTemplate::factory()->create([
            'title' => '7-Day Morning Walk',
            'description' => 'Walk 10 minutes each morning',
            'difficulty' => 'beginner',
            'duration_days' => 7,
            'category_id' => $category->id,
        ]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$this->tokenFor($user)])
            ->getJson('/api/v1/challenge-templates');

        $response->assertStatus(200)
            ->assertJsonStructure(['data' => [['id', 'title', 'description', 'difficulty', 'duration_days', 'category_id']]])
            ->assertJson([
                'data' => [
                    [
                        'id' => $template->id,
                        'title' => '7-Day Morning Walk',
                        'description' => 'Walk 10 minutes each morning',
                        'difficulty' => 'beginner',
                        'duration_days' => 7,
                        'category_id' => $category->id,
                    ],
                ],
            ]);
    }

    public function test_templates_can_be_filtered_by_category_id(): void
    {
        $user = User::factory()->create();
        $health = ChallengeCategory::factory()->create(['slug' => 'health']);
        $focus = ChallengeCategory::factory()->create(['slug' => 'focus']);

        ChallengeTemplate::factory()->count(2)->create(['category_id' => $health->id]);
        ChallengeTemplate::factory()->count(3)->create(['category_id' => $focus->id]);

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$this->tokenFor($user)])
            ->getJson("/api/v1/challenge-templates?category_id={$health->id}");

        $response->assertStatus(200);
        $this->assertCount(2, $response->json('data'));

        foreach ($response->json('data') as $template) {
            $this->assertSame($health->id, $template['category_id']);
        }
    }

    public function test_categories_endpoint_requires_authentication(): void
    {
        $this->getJson('/api/v1/challenge-categories')->assertStatus(401);
    }

    public function test_templates_endpoint_requires_authentication(): void
    {
        $this->getJson('/api/v1/challenge-templates')->assertStatus(401);
    }

    public function test_creating_a_category_via_model_persists_correctly(): void
    {
        // Filament's ChallengeCategoryResource form ultimately creates a
        // ChallengeCategory model record; full Filament/Livewire browser
        // testing is out of scope for the hackathon, so we assert the
        // model-level contract Filament relies on instead.
        $category = ChallengeCategory::create([
            'name' => 'Wellbeing',
            'slug' => 'wellbeing',
        ]);

        $this->assertDatabaseHas('challenge_categories', [
            'id' => $category->id,
            'name' => 'Wellbeing',
            'slug' => 'wellbeing',
        ]);
    }
}
