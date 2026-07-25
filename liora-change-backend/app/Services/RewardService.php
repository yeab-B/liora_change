<?php

namespace App\Services;

use App\Models\User;
use App\Models\XpLedger;
use Illuminate\Support\Carbon;

/**
 * Daily reward claim (docs/mvp/issues/06-gamification-admin.md
 * "POST /api/v1/rewards/daily/claim"). Reuses xp_ledgers with
 * reason=daily_reward instead of a dedicated claims table.
 */
class RewardService
{
    public const DAILY_REWARD_XP = 5;

    public const DAILY_REWARD_REASON = 'daily_reward';

    public function __construct(
        private readonly XPService $xpService,
    ) {
    }

    /**
     * Whether the user already claimed their daily reward "today" in their
     * own timezone. Compares against the UTC instant range for that
     * calendar day so it's correct regardless of app/server timezone.
     */
    public function hasClaimedToday(User $user): bool
    {
        $timezone = $user->timezone ?: 'UTC';
        $startOfDay = Carbon::now($timezone)->startOfDay()->utc();
        $endOfDay = Carbon::now($timezone)->endOfDay()->utc();

        return XpLedger::where('user_id', $user->id)
            ->where('reason', self::DAILY_REWARD_REASON)
            ->whereBetween('created_at', [$startOfDay, $endOfDay])
            ->exists();
    }

    /**
     * Award the daily reward XP and log it. Caller must check
     * hasClaimedToday() first.
     */
    public function claimDaily(User $user): int
    {
        $this->xpService->award($user, self::DAILY_REWARD_XP);

        XpLedger::create([
            'user_id' => $user->id,
            'challenge_id' => null,
            'amount' => self::DAILY_REWARD_XP,
            'reason' => self::DAILY_REWARD_REASON,
        ]);

        return self::DAILY_REWARD_XP;
    }
}
