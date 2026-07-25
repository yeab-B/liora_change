<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ChallengeResource;
use App\Models\Challenge;
use App\Services\RecoveryService;
use App\Shared\Enums\ChallengeStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Carbon;

class DashboardController extends Controller
{
    /**
     * Fields from the full ChallengeResource shape kept in the dashboard's
     * slim "active_challenges" entries (issue's "GET /api/v1/dashboard").
     */
    private const SLIM_CHALLENGE_FIELDS = [
        'id', 'title', 'status', 'progress_percent', 'current_streak', 'checked_in_today',
    ];

    public function __construct(
        private readonly RecoveryService $recoveryService,
    ) {
    }

    /**
     * GET /api/v1/dashboard — the single aggregate payload that powers
     * Mobile Home, per docs/mvp/issues/05-dashboard-recovery-api.md.
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        $today = Carbon::now($user->timezone ?: 'UTC')->toDateString();

        $activeChallenges = $user->challenges()
            ->where('status', ChallengeStatus::Active->value)
            ->get();

        $activeChallengesPayload = [];
        $completedTodayCount = 0;

        foreach ($activeChallenges as $challenge) {
            $activeChallengesPayload[] = $this->slimChallenge($challenge, $request);

            if ($this->completedToday($challenge, $today)) {
                $completedTodayCount++;
            }
        }

        $activeCount = $activeChallenges->count();

        return response()->json([
            'data' => [
                'user' => [
                    'name' => $user->name,
                    'xp_total' => $user->xp_total,
                    'level' => $user->level,
                    'current_streak' => $user->current_streak,
                    'longest_streak' => $user->longest_streak,
                ],
                'today' => [
                    'date' => $today,
                    'active_challenges_count' => $activeCount,
                    'completed_checkins_count' => $completedTodayCount,
                    'pending_checkins_count' => max(0, $activeCount - $completedTodayCount),
                ],
                'active_challenges' => $activeChallengesPayload,
                'recovery' => $this->recoveryService->currentFor($user),
                'motivation_preview' => null,
            ],
        ]);
    }

    /**
     * Reuses ChallengeResource (issue #2) for progress_percent/checked_in_today
     * math instead of recomputing it, then trims to the dashboard's slim shape.
     *
     * @return array<string, mixed>
     */
    private function slimChallenge(Challenge $challenge, Request $request): array
    {
        $full = (new ChallengeResource($challenge))->toArray($request);

        return Arr::only($full, self::SLIM_CHALLENGE_FIELDS);
    }

    private function completedToday(Challenge $challenge, string $today): bool
    {
        return $challenge->checkIns()
            ->where('check_in_date', $today)
            ->where('status', 'completed')
            ->exists();
    }
}
