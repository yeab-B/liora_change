<?php

namespace Database\Factories;

use App\Models\ChallengeCategory;
use App\Models\ChallengeTemplate;
use App\Shared\Enums\ChallengeDifficulty;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ChallengeTemplate>
 */
class ChallengeTemplateFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'category_id' => ChallengeCategory::factory(),
            'title' => fake()->sentence(3),
            'description' => fake()->optional()->paragraph(),
            'difficulty' => ChallengeDifficulty::Beginner->value,
            'duration_days' => 7,
        ];
    }
}
