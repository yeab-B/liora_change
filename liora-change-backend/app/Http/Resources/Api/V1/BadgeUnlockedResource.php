<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Carbon;

/**
 * Canonical BadgeUnlocked shape for the mobile API contract.
 *
 * Field names/order are frozen by docs/mvp/teams/SHARED-DATA-CONTRACT.md
 * §3.21 — do not add or rename keys without updating that document first.
 *
 * @mixin \App\Models\UserBadge
 */
class BadgeUnlockedResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->badge_id,
            'code' => $this->badge->code,
            'name' => $this->badge->name,
            'description' => $this->badge->description,
            'unlocked_at' => $this->formatDateTime($this->unlocked_at),
        ];
    }

    private function formatDateTime(?Carbon $date): ?string
    {
        return $date?->clone()->utc()->format('Y-m-d\TH:i:s\Z');
    }
}
