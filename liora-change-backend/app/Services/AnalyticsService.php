<?php

namespace App\Services;

class AnalyticsService
{
    /**
     * Calculate consistency score.
     */
    public function calculateConsistency(int $activeDays, int $totalDays): float
    {
        if ($totalDays === 0) return 0.0;
        return round(($activeDays / $totalDays) * 100, 2);
    }

    /**
     * Generate calendar matrix for GitHub style view.
     */
    public function generateCalendarMatrix(array $dailyLogs): array
    {
        // Maps daily logs into a structured calendar matrix array
        return [];
    }
}
