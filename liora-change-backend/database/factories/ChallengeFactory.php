<?php

namespace Database\Factories;

use App\Models\Challenge;
use App\Models\User;
use App\Shared\Enums\ChallengeDifficulty;
use App\Shared\Enums\ChallengeStatus;
use App\Shared\Enums\ChallengeVisibility;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Challenge>
 */
class ChallengeFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'category_id' => null,
            'title' => fake()->sentence(3),
            'description' => fake()->optional()->paragraph(),
            'status' => ChallengeStatus::Draft->value,
            'difficulty' => ChallengeDifficulty::Beginner->value,
            'visibility' => ChallengeVisibility::Private->value,
            'start_date' => null,
            'end_date' => null,
            'duration_days' => 7,
            'current_streak' => 0,
            'longest_streak' => 0,
        ];
    }
}
