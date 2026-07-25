<?php

namespace App\Http\Resources\Api\V1;

use App\Services\ProgressService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Canonical Challenge shape for the mobile API contract.
 *
 * Field names/order are frozen by docs/mvp/teams/SHARED-DATA-CONTRACT.md —
 * do not add or rename keys without updating that document first.
 *
 * `completed_checkins`, `missed_checkins`, `checked_in_today` and
 * `progress_percent` are computed defensively: the `check_ins` table does
 * not exist until Issue #4 (Check-ins API) is merged, so they safely
 * default to 0/false until then instead of erroring.
 *
 * @mixin \App\Models\Challenge
 */
class ChallengeResource extends JsonResource
{
    /**
     * Cached per-request so we only run Schema::hasTable() once even when
     * rendering a collection of challenges.
     */
    private static ?bool $checkInsTableExists = null;

    public function toArray(Request $request): array
    {
        $completedCheckIns = $this->completedCheckIns();

        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'status' => $this->status,
            'difficulty' => $this->difficulty,
            'visibility' => $this->visibility,
            'category_id' => $this->category_id,
            'start_date' => $this->start_date?->toDateString(),
            'end_date' => $this->end_date?->toDateString(),
            'duration_days' => $this->duration_days,
            'progress_percent' => (new ProgressService())->calculateProgressPercentage(
                $completedCheckIns,
                max(1, (int) $this->duration_days)
            ),
            'current_streak' => $this->current_streak,
            'longest_streak' => $this->longest_streak,
            'completed_checkins' => $completedCheckIns,
            'missed_checkins' => $this->missedCheckIns(),
            'checked_in_today' => $this->checkedInToday(),
            'created_at' => $this->formatDateTime($this->created_at),
            'updated_at' => $this->formatDateTime($this->updated_at),
        ];
    }

    private function hasCheckInsTable(): bool
    {
        return self::$checkInsTableExists ??= Schema::hasTable('check_ins');
    }

    private function completedCheckIns(): int
    {
        if (! $this->hasCheckInsTable()) {
            return 0;
        }

        return DB::table('check_ins')
            ->where('challenge_id', $this->id)
            ->where('status', 'completed')
            ->count();
    }

    private function missedCheckIns(): int
    {
        if (! $this->hasCheckInsTable()) {
            return 0;
        }

        return DB::table('check_ins')
            ->where('challenge_id', $this->id)
            ->whereIn('status', ['skipped', 'missed'])
            ->count();
    }

    private function checkedInToday(): bool
    {
        if (! $this->hasCheckInsTable()) {
            return false;
        }

        $timezone = $this->user?->timezone ?: 'UTC';
        $today = Carbon::now($timezone)->toDateString();

        return DB::table('check_ins')
            ->where('challenge_id', $this->id)
            ->where('check_in_date', $today)
            ->exists();
    }

    private function formatDateTime(?Carbon $date): ?string
    {
        return $date?->clone()->utc()->format('Y-m-d\TH:i:s\Z');
    }
}
