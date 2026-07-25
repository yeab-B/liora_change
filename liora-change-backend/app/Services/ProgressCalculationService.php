<?php

namespace App\Services;

use App\Models\DailyCheckIn;
use App\Models\ChallengeProgress;

class ProgressCalculationService
{
    /**
     * Re-calculate the progress for a specific challenge and user.
     * Often dispatched to a Queue.
     */
    public function calculateProgress($userId, $challengeId): void
    {
        $progress = ChallengeProgress::firstOrCreate(
            ['user_id' => $userId, 'challenge_id' => $challengeId],
            ['current_day' => 1]
        );

        $checkIns = DailyCheckIn::where('user_id', $userId)
            ->where('challenge_id', $challengeId)
            ->orderBy('date', 'asc')
            ->get();

        $completedCount = $checkIns->where('is_completed', true)->count();
        $missedCount = $checkIns->where('is_completed', false)->count();
        
        // Simple streak logic
        $currentStreak = 0;
        $longestStreak = $progress->longest_streak;

        foreach ($checkIns as $checkIn) {
            if ($checkIn->is_completed) {
                $currentStreak++;
                if ($currentStreak > $longestStreak) {
                    $longestStreak = $currentStreak;
                }
            } else {
                $currentStreak = 0; // Reset streak
            }
        }

        $progress->update([
            'completed_days' => $completedCount,
            'missed_days' => $missedCount,
            'current_streak' => $currentStreak,
            'longest_streak' => $longestStreak,
            // Assuming 30 days default for MVP, in real implementation this comes from Schedule
            'completion_percentage' => min(100, ($completedCount / 30) * 100), 
            'last_activity' => now(),
        ]);
    }
}
