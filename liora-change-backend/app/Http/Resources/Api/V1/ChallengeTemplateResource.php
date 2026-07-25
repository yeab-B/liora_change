<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Canonical ChallengeTemplate shape for the mobile API contract.
 *
 * Field names are frozen by docs/mvp/teams/SHARED-DATA-CONTRACT.md §3.13 —
 * do not add or rename keys without updating that document first.
 *
 * @mixin \App\Models\ChallengeTemplate
 */
class ChallengeTemplateResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'difficulty' => $this->difficulty,
            'duration_days' => $this->duration_days,
            'category_id' => $this->category_id,
        ];
    }
}
