<?php

namespace App\Services;

use App\Models\Challenge;
use App\Shared\Enums\ChallengeStatus;
use Exception;
use Illuminate\Support\Facades\DB;

class ChallengeService
{
    /**
     * Create a new challenge (Wizard Step 1-2).
     */
    public function createDraft(array $data, $userId): Challenge
    {
        $data['user_id'] = $userId;
        $data['status'] = ChallengeStatus::Draft->value;
        
        return Challenge::create($data);
    }

    /**
     * Handle strict state transitions based on business rules.
     */
    public function changeStatus(Challenge $challenge, ChallengeStatus $newStatus): void
    {
        $currentStatus = ChallengeStatus::tryFrom($challenge->status);

        if (!$this->canTransition($currentStatus, $newStatus)) {
            throw new Exception("Invalid state transition from {$currentStatus->value} to {$newStatus->value}");
        }

        $challenge->update(['status' => $newStatus->value]);
        
        // Log action
        $challenge->logs()->create([
            'user_id' => auth()->id() ?? $challenge->user_id,
            'action_type' => 'status_changed',
            'properties' => ['from' => $currentStatus->value, 'to' => $newStatus->value]
        ]);
    }

    /**
     * Define the state machine logic.
     */
    private function canTransition(ChallengeStatus $current, ChallengeStatus $new): bool
    {
        return match ($current) {
            ChallengeStatus::Draft => in_array($new, [ChallengeStatus::Ready, ChallengeStatus::Archived]),
            ChallengeStatus::Ready => in_array($new, [ChallengeStatus::Active, ChallengeStatus::Draft, ChallengeStatus::Archived]),
            ChallengeStatus::Active => in_array($new, [ChallengeStatus::Paused, ChallengeStatus::Completed, ChallengeStatus::Cancelled, ChallengeStatus::Archived]),
            ChallengeStatus::Paused => in_array($new, [ChallengeStatus::Active, ChallengeStatus::Cancelled, ChallengeStatus::Archived]),
            ChallengeStatus::Completed, ChallengeStatus::Cancelled, ChallengeStatus::Archived => false, // Terminal states
        };
    }
}
