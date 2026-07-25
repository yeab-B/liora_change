<?php

namespace Database\Factories;

use App\Models\User;
use App\Models\XpLedger;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<XpLedger>
 */
class XpLedgerFactory extends Factory
{
    protected $model = XpLedger::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'challenge_id' => null,
            'amount' => 10,
            'reason' => 'check_in_completed',
        ];
    }
}
