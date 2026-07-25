<?php

namespace App\Services;

use App\Models\Challenge;
use App\Models\CheckIn;
use App\Models\User;
use App\Shared\Enums\ChallengeStatus;
use Illuminate\Support\Carbon;

/**
 * Single source of truth for the "recovery" business rule
 * (docs/mvp/issues/05-dashboard-recovery-api.md "GET /api/v1/recovery/current"),
 * shared by DashboardController and RecoveryController so the rule is never
 * duplicated.
 */
class RecoveryService
{
    private const RECOVERY_WINDOW_DAYS = 3;

    private const QUALIFYING_STATUSES = ['skipped', 'missed'];

    /**
     * Static, non-shaming template copy keyed by check-in reason. No AI call
     * required — Issue #7 may enrich this later, but it must work standalone.
     *
     * @var array<string, array{title: string, message: string}>
     */
    private const TEMPLATES = [
        'skipped' => [
            'title' => "Let's restart gently",
            'message' => 'You skipped {date}. Today, do the smallest version of "{challenge}": just 5 minutes.',
        ],
        'missed' => [
            'title' => 'Missed day — restart small',
            'message' => 'One missed day does not erase your progress with "{challenge}". Try a small version today.',
        ],
    ];

    /**
     * Determine whether recovery is currently active for the user.
     *
     * Rule: active if the user has an active challenge whose latest check-in
     * is skipped/missed, dated within the last 3 calendar days. Multiple
     * qualifying challenges resolve to the one with the most recent
     * qualifying check-in.
     *
     * @return array{active: bool, challenge_id?: int, challenge_title?: string, reason?: string, title?: string, message?: string, suggested_action?: array{type: string, challenge_id: int, label: string}}
     */
    public function currentFor(User $user): array
    {
        $todayStr = Carbon::now($user->timezone ?: 'UTC')->toDateString();
        $windowStartStr = Carbon::parse($todayStr)->subDays(self::RECOVERY_WINDOW_DAYS)->toDateString();

        $bestChallenge = null;
        $bestCheckIn = null;

        foreach ($this->activeChallenges($user) as $challenge) {
            $latestCheckIn = $challenge->checkIns()->orderByDesc('check_in_date')->first();

            if (! $this->qualifies($latestCheckIn, $windowStartStr)) {
                continue;
            }

            if ($bestCheckIn === null || $latestCheckIn->check_in_date->toDateString() > $bestCheckIn->check_in_date->toDateString()) {
                $bestChallenge = $challenge;
                $bestCheckIn = $latestCheckIn;
            }
        }

        if ($bestChallenge === null || $bestCheckIn === null) {
            return ['active' => false];
        }

        return $this->buildActivePayload($bestChallenge, $bestCheckIn, $todayStr);
    }

    private function qualifies(?CheckIn $checkIn, string $windowStartStr): bool
    {
        if ($checkIn === null) {
            return false;
        }

        if (! in_array($checkIn->status, self::QUALIFYING_STATUSES, true)) {
            return false;
        }

        return $checkIn->check_in_date->toDateString() >= $windowStartStr;
    }

    private function activeChallenges(User $user)
    {
        return $user->challenges()->where('status', ChallengeStatus::Active->value)->get();
    }

    private function buildActivePayload(Challenge $challenge, CheckIn $checkIn, string $todayStr): array
    {
        $reason = $checkIn->status;
        $template = self::TEMPLATES[$reason] ?? self::TEMPLATES['skipped'];

        $message = str_replace(
            ['{date}', '{challenge}'],
            [$this->relativeDate($checkIn->check_in_date->toDateString(), $todayStr), $challenge->title],
            $template['message']
        );

        return [
            'active' => true,
            'challenge_id' => $challenge->id,
            'challenge_title' => $challenge->title,
            'reason' => $reason,
            'title' => $template['title'],
            'message' => $message,
            'suggested_action' => [
                'type' => 'check_in',
                'challenge_id' => $challenge->id,
                'label' => 'Check in now',
            ],
        ];
    }

    private function relativeDate(string $dateStr, string $todayStr): string
    {
        $daysAgo = Carbon::parse($dateStr)->diffInDays(Carbon::parse($todayStr));

        return match ($daysAgo) {
            0 => 'today',
            1 => 'yesterday',
            default => "{$daysAgo} days ago",
        };
    }
}
