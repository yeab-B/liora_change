<?php

namespace App\Services;

use App\Models\User;

class XPService
{
    /**
     * XP awarded for a single completed check-in
     * (docs/mvp/teams/SHARED-DATA-CONTRACT.md §5 "Business numbers").
     */
    public const CHECK_IN_XP = 10;

    /**
     * Award XP to a user and recompute their level.
     *
     * Level = floor(xp_total / 100) + 1 — exact formula from the shared
     * data contract's business numbers table. Persists the user record.
     */
    public function award(User $user, int $amount): User
    {
        $user->xp_total = $user->xp_total + $amount;
        $user->level = intdiv($user->xp_total, 100) + 1;
        $user->save();

        return $user;
    }
}
