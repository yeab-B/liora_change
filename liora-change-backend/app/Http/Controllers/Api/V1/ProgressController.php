<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\CheckIn;
use App\Services\ProgressService;
use App\Shared\Enums\ChallengeStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProgressController extends Controller
{
    public function __construct(
        private readonly ProgressService $progressService,
    ) {
    }

    /**
     * GET /api/v1/progress — nice-to-have aggregate stats. Reuses
     * ProgressService::calculateSuccessRate() rather than reimplementing it.
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        $challengeIds = $user->challenges()->pluck('id');

        $completedCheckIns = CheckIn::whereIn('challenge_id', $challengeIds)->where('status', 'completed')->count();
        $skippedCheckIns = CheckIn::whereIn('challenge_id', $challengeIds)->where('status', 'skipped')->count();

        return response()->json([
            'data' => [
                'xp_total' => $user->xp_total,
                'level' => $user->level,
                'current_streak' => $user->current_streak,
                'longest_streak' => $user->longest_streak,
                'success_rate' => $this->progressService->calculateSuccessRate($completedCheckIns, $skippedCheckIns),
                'completed_checkins' => $completedCheckIns,
                'skipped_checkins' => $skippedCheckIns,
                'active_challenges' => $user->challenges()->where('status', ChallengeStatus::Active->value)->count(),
                'completed_challenges' => $user->challenges()->where('status', ChallengeStatus::Completed->value)->count(),
            ],
        ]);
    }
}
