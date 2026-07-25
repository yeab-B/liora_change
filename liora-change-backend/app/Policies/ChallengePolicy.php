<?php

namespace App\Policies;

use App\Models\Challenge;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class ChallengePolicy
{
    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return false;
    }

    /**
     * Determine whether the user can view the model.
     *
     * MVP rule: a member may only view their own challenges
     * (docs/mvp/issues/02-challenges-api.md).
     */
    public function view(User $user, Challenge $challenge): bool
    {
        return $user->id === $challenge->user_id;
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return false;
    }

    /**
     * Determine whether the user can update the model.
     *
     * Also gates status-changing actions like `activate` for the MVP API.
     */
    public function update(User $user, Challenge $challenge): bool
    {
        return $user->id === $challenge->user_id;
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Challenge $challenge): bool
    {
        return false;
    }

    /**
     * Determine whether the user can restore the model.
     */
    public function restore(User $user, Challenge $challenge): bool
    {
        return false;
    }

    /**
     * Determine whether the user can permanently delete the model.
     */
    public function forceDelete(User $user, Challenge $challenge): bool
    {
        return false;
    }
}
