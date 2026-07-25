<?php

namespace App\Services\Ai;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Thin wrapper around the OpenAI chat completions API. Never throws: any
 * missing key, HTTP failure, timeout, or malformed response resolves to
 * null so callers can always fall back to a static template
 * (docs/mvp/issues/07-ai-motivation.md — "must never crash the Home screen").
 */
class OpenAiClient
{
    private const ENDPOINT = 'https://api.openai.com/v1/chat/completions';

    private const TIMEOUT_SECONDS = 8;

    /**
     * @param array<int, array{role: string, content: string}> $messages
     */
    public function chat(array $messages, ?string $model = null): ?string
    {
        $apiKey = config('services.openai.key');

        if (empty($apiKey)) {
            return null;
        }

        try {
            $response = Http::withToken($apiKey)
                ->timeout(self::TIMEOUT_SECONDS)
                ->post(self::ENDPOINT, [
                    'model' => $model ?: config('services.openai.model', 'gpt-4o-mini'),
                    'messages' => $messages,
                ]);

            if (! $response->successful()) {
                return null;
            }

            $content = $response->json('choices.0.message.content');

            return is_string($content) && trim($content) !== '' ? trim($content) : null;
        } catch (Throwable $e) {
            Log::warning('OpenAI chat completion failed; falling back to template.', [
                'error' => $e->getMessage(),
            ]);

            return null;
        }
    }
}
