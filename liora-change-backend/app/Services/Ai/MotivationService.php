<?php

namespace App\Services\Ai;

use App\Models\Challenge;
use App\Models\User;
use App\Services\ProgressService;

/**
 * Builds a personalized motivational message from real user/challenge data,
 * calls OpenAI, and falls back to a static template on any failure
 * (docs/mvp/issues/07-ai-motivation.md).
 */
class MotivationService
{
    private const SYSTEM_PROMPT = <<<'TEXT'
        You are Liora Change, a supportive habit coach. You are not a doctor or therapist.
        Write under 60 words. Mention the challenge by name. Be warm, specific, and actionable.
        If context is "recovery", be gentle about the setback and suggest one tiny next step.
        Never use guilt, shame, or clinical language.
        TEXT;

    /**
     * Static per-difficulty hint used only by the template fallback.
     *
     * @var array<string, string>
     */
    private const DIFFICULTY_HINTS = [
        'beginner' => 'Even 5 minutes counts',
        'easy' => 'Even 5 minutes counts',
        'medium' => 'A short, honest effort is enough today',
        'hard' => 'Pick the smallest version you can manage',
        'expert' => 'Even one small consistent step keeps it alive',
    ];

    public function __construct(
        private readonly OpenAiClient $openAiClient,
        private readonly ProgressService $progressService,
    ) {
    }

    /**
     * @return array{message: string, tone: string, source: string, challenge_id: int|null, challenge_title: string|null}
     */
    public function generate(User $user, ?Challenge $challenge, string $context): array
    {
        $aiMessage = $this->openAiClient->chat($this->buildMessages($user, $challenge, $context));

        return [
            'message' => $aiMessage ?? $this->templateMessage($user, $challenge),
            'tone' => 'encouraging',
            'source' => $aiMessage !== null ? 'openai' : 'template',
            'challenge_id' => $challenge?->id,
            'challenge_title' => $challenge?->title,
        ];
    }

    /**
     * @return array<int, array{role: string, content: string}>
     */
    private function buildMessages(User $user, ?Challenge $challenge, string $context): array
    {
        return [
            ['role' => 'system', 'content' => self::SYSTEM_PROMPT],
            ['role' => 'user', 'content' => $this->buildUserMessage($user, $challenge, $context)],
        ];
    }

    /**
     * Follows the exact template from docs/mvp/issues/07-ai-motivation.md
     * "Prompt construction" § "User message template".
     */
    private function buildUserMessage(User $user, ?Challenge $challenge, string $context): string
    {
        if ($challenge === null) {
            return sprintf(
                "User: %s\nChallenge: none yet\nContext: %s\n\nWrite one short motivational message encouraging this user to start their first habit challenge.",
                $user->name,
                $context
            );
        }

        $progressPercent = $this->progressService->calculateProgressPercentage(
            $challenge->checkIns()->where('status', 'completed')->count(),
            max(1, (int) $challenge->duration_days)
        );
        $lastCheckIn = $challenge->checkIns()->orderByDesc('check_in_date')->first();

        return sprintf(
            "User: %s\nChallenge: %s — %s\nDifficulty: %s\nCurrent streak: %d days\nProgress: %s%%\nLast check-in: %s\nContext: %s\n\nWrite one short motivational message for this user right now.",
            $user->name,
            $challenge->title,
            $challenge->description ?: 'no description',
            $challenge->difficulty,
            $challenge->current_streak,
            $progressPercent,
            $lastCheckIn?->status ?? 'none yet',
            $context
        );
    }

    /**
     * Follows the exact template from docs/mvp/issues/07-ai-motivation.md
     * "Template fallback".
     */
    private function templateMessage(User $user, ?Challenge $challenge): string
    {
        if ($challenge === null) {
            return sprintf(
                "%s, starting one small challenge today is enough to build momentum. You've got this.",
                $user->name
            );
        }

        $hint = self::DIFFICULTY_HINTS[$challenge->difficulty] ?? 'Even a tiny step counts';

        return sprintf(
            "%s, your %s only needs a small step today. %s. You've got this.",
            $user->name,
            $challenge->title,
            $hint
        );
    }
}
