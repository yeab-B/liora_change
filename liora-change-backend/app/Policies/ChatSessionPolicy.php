<?php

namespace App\Policies;

use App\Models\ChatSession;
use App\Models\User;

class ChatSessionPolicy
{
    /**
     * Determine whether the user can view the model.
     *
     * MVP rule: a member may only view/use their own chat sessions.
     */
    public function view(User $user, ChatSession $session): bool
    {
        return $user->id === $session->user_id;
    }
}
