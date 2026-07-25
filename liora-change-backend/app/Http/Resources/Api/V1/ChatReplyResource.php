<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Canonical ChatReply shape for the mobile API contract.
 *
 * Field names/order are frozen by docs/mvp/teams/SHARED-DATA-CONTRACT.md
 * §3.18 — do not add or rename keys without updating that document first.
 *
 * Wraps the plain array already shaped correctly by
 * App\Services\Ai\ChatService::respond(). `sources` is already a plain
 * array of {title, snippet} pairs (ChatSource, §3.17).
 */
class ChatReplyResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'session_id' => $this->resource['session_id'],
            'message' => new ChatMessageResource($this->resource['message']),
            'sources' => $this->resource['sources'],
            'used_challenge_id' => $this->resource['used_challenge_id'],
        ];
    }
}
