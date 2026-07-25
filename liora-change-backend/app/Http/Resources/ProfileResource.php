<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProfileResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'phone' => $this->phone,
            'country_id' => $this->country_id,
            'language_id' => $this->language_id,
            'timezone' => $this->timezone,
            'date_format' => $this->date_format,
            'biography' => $this->biography,
            'birth_date' => $this->birth_date,
            'gender' => $this->gender,
            'occupation' => $this->occupation,
            'personal_goals' => $this->personal_goals,
        ];
    }
}
