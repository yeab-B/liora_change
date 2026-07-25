<?php

namespace App\Services;

class StreakService
{
    /**
     * Calculate streak changes based on a completed task.
     */
    public function incrementStreak(int $currentStreak, int $longestStreak): array
    {
        $newCurrent = $currentStreak + 1;
        $newLongest = $newCurrent > $longestStreak ? $newCurrent : $longestStreak;
        
        return [
            'current_streak' => $newCurrent,
            'longest_streak' => $newLongest
        ];
    }

    /**
     * Break the streak when a task is skipped or missed.
     */
    public function breakStreak(): int
    {
        return 0; // The current streak resets to 0.
    }
}
