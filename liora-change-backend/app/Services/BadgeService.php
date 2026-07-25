<?php

namespace App\Services;

use App\Models\Badge;
use App\Models\Challenge;
use App\Models\CheckIn;
use App\Models\User;
use App\Models\UserBadge;
use Illuminate\Support\Carbon;

/**
 * Badge auto-unlock rules (docs/mvp/issues/06-gamification-admin.md
 * "Badge auto-unlock"). Called from CheckInController::store() right after
 * a check-in is persisted.
 */
class BadgeService
{
    public const FIRST_CHECKIN = 'first_checkin';

    public const STREAK_3 = 'streak_3';

    public const COMEBACK = 'comeback';

    private const PRIOR_QUALIFYING_STATUSES = ['skipped', 'missed'];

    /**
     * Evaluate every badge rule for a just-persisted check-in and unlock any
     * that newly qualify. Only completed check-ins can unlock a badge.
     *
     * Idempotent: relies on the (user_id, badge_id) unique constraint via
     * firstOrCreate, so calling this repeatedly for the same user/challenge
     * never double-unlocks.
     *
     * @return array<int, Badge> newly unlocked badges (empty if none)
     */
    public function evaluateAndUnlock(User $user, Challenge $challenge, CheckIn $checkIn): array
    {
        if ($checkIn->status !== 'completed') {
            return [];
        }

        $unlocked = [];

        if ($this->isUsersFirstCompletedCheckIn($user)) {
            $this->collectUnlock($unlocked, $user, self::FIRST_CHECKIN);
        }

        if ($challenge->current_streak >= 3) {
            $this->collectUnlock($unlocked, $user, self::STREAK_3);
        }

        if ($this->isComeback($challenge, $checkIn)) {
            $this->collectUnlock($unlocked, $user, self::COMEBACK);
        }

        return $unlocked;
    }

    private function isUsersFirstCompletedCheckIn(User $user): bool
    {
        return CheckIn::where('user_id', $user->id)->where('status', 'completed')->count() === 1;
    }

    /**
     * True when the check-in immediately preceding this one (by date, for
     * the same challenge) was skipped/missed — i.e. recovery worked.
     */
    private function isComeback(Challenge $challenge, CheckIn $checkIn): bool
    {
        $previous = $challenge->checkIns()
            ->where('check_in_date', '<', $checkIn->check_in_date)
            ->orderByDesc('check_in_date')
            ->first();

        return $previous !== null && in_array($previous->status, self::PRIOR_QUALIFYING_STATUSES, true);
    }

    /**
     * @param array<int, Badge> $unlocked
     */
    private function collectUnlock(array &$unlocked, User $user, string $badgeCode): void
    {
        $badge = $this->unlock($user, $badgeCode);

        if ($badge !== null) {
            $unlocked[] = $badge;
        }
    }

    private function unlock(User $user, string $badgeCode): ?Badge
    {
        $badge = Badge::where('code', $badgeCode)->first();

        if ($badge === null) {
            return null;
        }

        $userBadge = UserBadge::firstOrCreate(
            ['user_id' => $user->id, 'badge_id' => $badge->id],
            ['unlocked_at' => Carbon::now()]
        );

        return $userBadge->wasRecentlyCreated ? $badge : null;
    }
}
