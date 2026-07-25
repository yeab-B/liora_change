<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Canonical ChallengeCategory shape for the mobile API contract.
 *
 * Field names are frozen by docs/mvp/teams/SHARED-DATA-CONTRACT.md §3.12 —
 * do not add or rename keys without updating that document first.
 *
 * @mixin \App\Models\ChallengeCategory
 */
class ChallengeCategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'slug' => $this->slug,
        ];
    }
}
