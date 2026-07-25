<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\RewardService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RewardController extends Controller
{
    public function __construct(
        private readonly RewardService $rewardService,
    ) {
    }

    /**
     * POST /api/v1/rewards/daily/claim — fixed +5 XP, once per user per
     * calendar day (in the user's own timezone).
     */
    public function claimDaily(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($this->rewardService->hasClaimedToday($user)) {
            return response()->json([
                'message' => 'Daily reward already claimed',
                'code' => 'ALREADY_CLAIMED',
            ], 422);
        }

        $xpEarned = $this->rewardService->claimDaily($user);

        return response()->json([
            'data' => [
                'claimed' => true,
                'xp_earned' => $xpEarned,
                'xp_total' => $user->xp_total,
            ],
        ]);
    }
}
