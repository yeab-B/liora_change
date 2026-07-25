<?php

namespace Database\Factories;

use App\Models\Challenge;
use App\Models\CheckIn;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CheckIn>
 */
class CheckInFactory extends Factory
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
            'challenge_id' => Challenge::factory(),
            'check_in_date' => now()->toDateString(),
            'status' => 'completed',
            'note' => null,
            'mood' => null,
            'energy' => null,
            'xp_earned' => 10,
            'streak_after' => 1,
        ];
    }
}
