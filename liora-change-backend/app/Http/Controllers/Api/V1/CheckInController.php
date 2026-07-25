<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreCheckInRequest;
use App\Http\Resources\Api\V1\CheckInResource;
use App\Models\Challenge;
use App\Models\CheckIn;
use App\Models\XpLedger;
use App\Services\BadgeService;
use App\Services\ProgressService;
use App\Services\StreakService;
use App\Services\XPService;
use App\Shared\Enums\ChallengeStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class CheckInController extends Controller
{
    public function __construct(
        private readonly StreakService $streakService,
        private readonly XPService $xpService,
        private readonly ProgressService $progressService,
        private readonly BadgeService $badgeService,
    ) {
    }

    /**
     * GET /api/v1/challenges/{challenge}/check-ins — owner only, newest
     * check-in date first.
     */
    public function index(Challenge $challenge): JsonResponse
    {
        $this->authorize('view', $challenge);

        $checkIns = $challenge->checkIns()->orderByDesc('check_in_date')->get();

        return response()->json([
            'data' => CheckInResource::collection($checkIns),
        ]);
    }

    /**
     * POST /api/v1/challenges/{challenge}/check-ins — owner only.
     *
     * Upserts on (challenge_id, check_in_date) so mobile can safely retry a
     * double-tap. Applies the exact XP/streak/recovery rules from
     * docs/mvp/issues/04-checkins-api.md "Business rules (implement exactly)".
     */
    public function store(StoreCheckInRequest $request, Challenge $challenge): JsonResponse
    {
        $this->authorize('update', $challenge);

        if ($challenge->status !== ChallengeStatus::Active->value) {
            return response()->json([
                'message' => 'Challenge is not active',
                'code' => 'CHALLENGE_NOT_ACTIVE',
            ], 422);
        }

        $data = $request->validated();
        $user = $request->user();
        $isCompleted = $data['status'] === 'completed';

        $checkIn = DB::transaction(function () use ($challenge, $user, $data, $isCompleted) {
            $xpEarned = $isCompleted ? XPService::CHECK_IN_XP : 0;

            if ($isCompleted) {
                $streak = $this->streakService->incrementStreak($challenge->current_streak, $challenge->longest_streak);
                $challenge->current_streak = $streak['current_streak'];
                $challenge->longest_streak = $streak['longest_streak'];
            } else {
                $challenge->current_streak = $this->streakService->breakStreak();
            }
            $challenge->save();

            $checkIn = CheckIn::updateOrCreate(
                [
                    'challenge_id' => $challenge->id,
                    'check_in_date' => $data['check_in_date'],
                ],
                [
                    'user_id' => $user->id,
                    'status' => $data['status'],
                    'note' => $data['note'] ?? null,
                    'mood' => $data['mood'] ?? null,
                    'energy' => $data['energy'] ?? null,
                    'xp_earned' => $xpEarned,
                    'streak_after' => $challenge->current_streak,
                ]
            );

            if ($isCompleted) {
                $this->xpService->award($user, $xpEarned);

                XpLedger::create([
                    'user_id' => $user->id,
                    'challenge_id' => $challenge->id,
                    'amount' => $xpEarned,
                    'reason' => 'check_in_completed',
                ]);
            }

            $this->badgeService->evaluateAndUnlock($user, $challenge, $checkIn);

            return $checkIn;
        });

        $completedCheckIns = $challenge->checkIns()->where('status', 'completed')->count();

        return response()->json([
            'data' => [
                'check_in' => new CheckInResource($checkIn),
                'summary' => [
                    'current_streak' => $challenge->current_streak,
                    'longest_streak' => $challenge->longest_streak,
                    'xp_total' => $user->xp_total,
                    'xp_earned' => $checkIn->xp_earned,
                    'challenge_progress_percent' => $this->progressService->calculateProgressPercentage(
                        $completedCheckIns,
                        max(1, (int) $challenge->duration_days)
                    ),
                    'recovery_available' => ! $isCompleted,
                ],
            ],
        ], 201);
    }
}
