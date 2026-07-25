<?php

namespace App\Services;

class ProgressService
{
    /**
     * Calculate Progress Percentage
     * Progress Percentage = (Completed Tasks / Total Tasks) × 100
     */
    public function calculateProgressPercentage(int $completedTasks, int $totalTasks): float
    {
        if ($totalTasks === 0) {
            return 0.0;
        }
        return round(($completedTasks / $totalTasks) * 100, 2);
    }

    /**
     * Calculate Success Rate
     * Success Rate = Completed Tasks / (Completed Tasks + Missed Tasks) × 100
     */
    public function calculateSuccessRate(int $completedTasks, int $missedTasks): float
    {
        $totalAttempted = $completedTasks + $missedTasks;
        if ($totalAttempted === 0) {
            return 0.0;
        }
        return round(($completedTasks / $totalAttempted) * 100, 2);
    }

    /**
     * Determine Challenge Status based on progress
     */
    public function determineStatus(float $progressPercentage): string
    {
        if ($progressPercentage === 0.0) {
            return 'Not Started';
        }
        if ($progressPercentage > 0 && $progressPercentage < 80) {
            return 'In Progress';
        }
        if ($progressPercentage >= 80 && $progressPercentage < 100) {
            return 'Almost Complete';
        }
        return 'Completed';
    }
}
