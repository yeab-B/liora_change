<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Carbon;

/**
 * Canonical CheckIn shape for the mobile API contract.
 *
 * Field names/order are frozen by docs/mvp/teams/SHARED-DATA-CONTRACT.md
 * §3.4 — do not add or rename keys without updating that document first.
 *
 * @mixin \App\Models\CheckIn
 */
class CheckInResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'challenge_id' => $this->challenge_id,
            'check_in_date' => $this->check_in_date?->toDateString(),
            'status' => $this->status,
            'note' => $this->note,
            'mood' => $this->mood,
            'energy' => $this->energy,
            'xp_earned' => $this->xp_earned,
            'streak_after' => $this->streak_after,
            'created_at' => $this->formatDateTime($this->created_at),
        ];
    }

    private function formatDateTime(?Carbon $date): ?string
    {
        return $date?->clone()->utc()->format('Y-m-d\TH:i:s\Z');
    }
}
