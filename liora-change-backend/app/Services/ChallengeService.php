<?php

namespace App\Services;

use App\Exceptions\InvalidStatusTransitionException;
use App\Models\Challenge;
use App\Shared\Enums\ChallengeDifficulty;
use App\Shared\Enums\ChallengeStatus;
use App\Shared\Enums\ChallengeVisibility;
use Carbon\Carbon;
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
        $data['difficulty'] = $data['difficulty'] ?? ChallengeDifficulty::Beginner->value;
        $data['visibility'] = $data['visibility'] ?? ChallengeVisibility::Private->value;
        $data['duration_days'] = $data['duration_days'] ?? 7;

        return Challenge::create($data);
    }

    /**
     * Activate a challenge (draft/ready -> active) for the MVP demo flow.
     *
     * Sets `start_date` to "today" in the owner's timezone and derives
     * `end_date` from `duration_days`. Throws when the current status does
     * not allow activation; callers render that as 422 INVALID_STATUS_TRANSITION.
     */
    public function activate(Challenge $challenge): Challenge
    {
        $current = ChallengeStatus::from($challenge->status);

        if (! $this->canTransition($current, ChallengeStatus::Active)) {
            throw new InvalidStatusTransitionException(
                "Challenge cannot be activated from {$current->value}"
            );
        }

        $timezone = $challenge->user?->timezone ?: 'UTC';
        $startDate = Carbon::now($timezone)->startOfDay();
        $endDate = $startDate->copy()->addDays(max(1, (int) $challenge->duration_days) - 1);

        $challenge->forceFill([
            'status' => ChallengeStatus::Active->value,
            'start_date' => $startDate->toDateString(),
            'end_date' => $endDate->toDateString(),
        ])->save();

        return $challenge->refresh();
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
            ChallengeStatus::Draft => in_array($new, [ChallengeStatus::Ready, ChallengeStatus::Active, ChallengeStatus::Archived]),
            ChallengeStatus::Ready => in_array($new, [ChallengeStatus::Active, ChallengeStatus::Draft, ChallengeStatus::Archived]),
            ChallengeStatus::Active => in_array($new, [ChallengeStatus::Paused, ChallengeStatus::Completed, ChallengeStatus::Cancelled, ChallengeStatus::Archived]),
            ChallengeStatus::Paused => in_array($new, [ChallengeStatus::Active, ChallengeStatus::Cancelled, ChallengeStatus::Archived]),
            ChallengeStatus::Completed, ChallengeStatus::Cancelled, ChallengeStatus::Archived => false, // Terminal states
        };
    }
}
