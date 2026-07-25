<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Canonical Motivation shape for the mobile API contract.
 *
 * Field names/order are frozen by docs/mvp/teams/SHARED-DATA-CONTRACT.md
 * §3.14 — do not add or rename keys without updating that document first.
 *
 * Wraps the plain array already shaped correctly by
 * App\Services\Ai\MotivationService::generate().
 */
class MotivationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'message' => $this->resource['message'],
            'tone' => $this->resource['tone'],
            'source' => $this->resource['source'],
            'challenge_id' => $this->resource['challenge_id'],
            'challenge_title' => $this->resource['challenge_title'],
        ];
    }
}
