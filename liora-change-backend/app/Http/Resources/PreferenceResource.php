<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PreferenceResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'notifications_enabled' => $this->notifications_enabled,
            'dark_mode' => $this->dark_mode,
            'weekly_reports' => $this->weekly_reports,
            'reminder_time' => $this->reminder_time,
            'measurement_units' => $this->measurement_units,
            'theme' => $this->theme,
            'privacy_settings' => $this->privacy_settings,
        ];
    }
}
