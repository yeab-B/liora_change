<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Carbon;

/**
 * Canonical ChatSession shape for the mobile API contract.
 *
 * Field names/order are frozen by docs/mvp/teams/SHARED-DATA-CONTRACT.md
 * §3.15 — do not add or rename keys without updating that document first.
 *
 * @mixin \App\Models\ChatSession
 */
class ChatSessionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'challenge_id' => $this->challenge_id,
            'created_at' => $this->formatDateTime($this->created_at),
            'updated_at' => $this->formatDateTime($this->updated_at),
        ];
    }

    private function formatDateTime(?Carbon $date): ?string
    {
        return $date?->clone()->utc()->format('Y-m-d\TH:i:s\Z');
    }
}
