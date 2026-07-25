<?php

namespace App\Services\Ai;

use App\Models\Challenge;
use App\Models\ChatMessage;
use App\Models\ChatSession;
use App\Models\KnowledgeChunk;
use App\Models\User;
use App\Services\ProgressService;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

/**
 * Implements the exact 10-step flow in
 * docs/mvp/issues/08-ai-rag-chat.md "Flow (implement exactly)".
 */
class ChatService
{
    private const SYSTEM_PROMPT = <<<'TEXT'
        You are Liora Change's AI coach. Answer using the provided reference material when relevant.
        You are supportive, brief (under 100 words), and never claim to be a doctor or therapist.
        If the user seems to be in crisis, gently suggest they reach out to a trusted person or local
        support service — do not attempt therapy.
        TEXT;

    /**
     * Short-term memory: how many prior messages in the session to include.
     */
    private const HISTORY_LIMIT = 6;

    /**
     * Fallback reply when no chunk exists at all and OpenAI is unavailable.
     */
    private const GENERIC_FALLBACK_REPLY = "I don't have a specific article for that yet, but here's a general rule: "
        ."start small, stay consistent, and don't let one missed day stop you. You're doing better than you think.";

    public function __construct(
        private readonly SimpleRagRetriever $retriever,
        private readonly OpenAiClient $openAiClient,
        private readonly ProgressService $progressService,
    ) {
    }

    /**
     * @return array{session_id: int, message: ChatMessage, sources: array<int, array{title: string, snippet: string}>, used_challenge_id: int|null}
     */
    public function respond(User $user, string $message, ?ChatSession $session, ?Challenge $challenge): array
    {
        $session = $session ?? ChatSession::create([
            'user_id' => $user->id,
            'challenge_id' => $challenge?->id,
        ]);

        $userMessage = ChatMessage::create([
            'chat_session_id' => $session->id,
            'role' => 'user',
            'content' => $message,
        ]);

        $chunks = $this->retriever->retrieve($message);

        $history = $session->messages()
            ->where('id', '!=', $userMessage->id)
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->limit(self::HISTORY_LIMIT)
            ->get()
            ->reverse()
            ->values();

        $aiMessages = $this->buildPrompt($chunks, $history, $challenge, $message);
        $aiReply = $this->openAiClient->chat($aiMessages);

        $replyContent = $aiReply ?? $this->fallbackReply($chunks);

        $assistantMessage = ChatMessage::create([
            'chat_session_id' => $session->id,
            'role' => 'assistant',
            'content' => $replyContent,
        ]);

        return [
            'session_id' => $session->id,
            'message' => $assistantMessage,
            'sources' => $this->toSources($chunks),
            'used_challenge_id' => $challenge?->id,
        ];
    }

    /**
     * System instruction + retrieved chunks (as reference material) +
     * challenge summary + recent message history + the new user message.
     *
     * @param Collection<int, KnowledgeChunk> $chunks
     * @param Collection<int, ChatMessage> $history
     * @return array<int, array{role: string, content: string}>
     */
    private function buildPrompt(Collection $chunks, Collection $history, ?Challenge $challenge, string $message): array
    {
        $systemContent = self::SYSTEM_PROMPT;

        if ($chunks->isNotEmpty()) {
            $reference = $chunks
                ->values()
                ->map(fn (KnowledgeChunk $chunk, int $index) => ($index + 1).'. '.$chunk->chunk_text)
                ->implode("\n");

            $systemContent .= "\n\nReference material:\n".$reference;
        }

        if ($challenge !== null) {
            $systemContent .= "\n\n".$this->challengeSummary($challenge);
        }

        $messages = [['role' => 'system', 'content' => $systemContent]];

        foreach ($history as $historyMessage) {
            $messages[] = ['role' => $historyMessage->role, 'content' => $historyMessage->content];
        }

        $messages[] = ['role' => 'user', 'content' => $message];

        return $messages;
    }

    private function challengeSummary(Challenge $challenge): string
    {
        $progressPercent = $this->progressService->calculateProgressPercentage(
            $challenge->checkIns()->where('status', 'completed')->count(),
            max(1, (int) $challenge->duration_days)
        );

        return sprintf(
            "User's current challenge: %s (current streak: %d days, progress: %s%%).",
            $challenge->title,
            $challenge->current_streak,
            $progressPercent
        );
    }

    /**
     * Return the single best-matching chunk's text, or a short canned
     * answer if no chunk is available.
     *
     * @param Collection<int, KnowledgeChunk> $chunks
     */
    private function fallbackReply(Collection $chunks): string
    {
        return $chunks->first()?->chunk_text ?? self::GENERIC_FALLBACK_REPLY;
    }

    /**
     * @param Collection<int, KnowledgeChunk> $chunks
     * @return array<int, array{title: string, snippet: string}>
     */
    private function toSources(Collection $chunks): array
    {
        return $chunks
            ->map(fn (KnowledgeChunk $chunk) => [
                'title' => $chunk->article->title,
                'snippet' => Str::limit($chunk->chunk_text, 160),
            ])
            ->values()
            ->all();
    }
}
