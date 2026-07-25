<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Carbon;

/**
 * Canonical XpLedgerItem shape for the mobile API contract.
 *
 * Field names/order are frozen by docs/mvp/teams/SHARED-DATA-CONTRACT.md
 * §3.20 — do not add or rename keys without updating that document first.
 *
 * @mixin \App\Models\XpLedger
 */
class XpLedgerResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'amount' => $this->amount,
            'reason' => $this->reason,
            'challenge_id' => $this->challenge_id,
            'created_at' => $this->formatDateTime($this->created_at),
        ];
    }

    private function formatDateTime(?Carbon $date): ?string
    {
        return $date?->clone()->utc()->format('Y-m-d\TH:i:s\Z');
    }
}
