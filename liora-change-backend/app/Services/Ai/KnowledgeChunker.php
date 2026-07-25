<?php

namespace App\Services\Ai;

use App\Models\KnowledgeArticle;
use Illuminate\Support\Facades\DB;

/**
 * Splits a KnowledgeArticle's body into ordered chunk rows
 * (docs/mvp/issues/08-ai-rag-chat.md "Chunking logic").
 */
class KnowledgeChunker
{
    /**
     * Paragraphs at or under this length are kept as a single chunk.
     */
    private const LONG_PARAGRAPH_THRESHOLD = 500;

    /**
     * Target size (chars) for pieces of a long paragraph once split.
     */
    private const SPLIT_CHUNK_SIZE = 400;

    /**
     * Re-chunk an article: delete its existing chunks and re-insert in
     * order (chunk_index = 0, 1, 2, ...).
     */
    public function chunk(KnowledgeArticle $article): void
    {
        $pieces = $this->buildChunks((string) $article->body);

        DB::transaction(function () use ($article, $pieces) {
            $article->chunks()->delete();

            foreach ($pieces as $index => $text) {
                $article->chunks()->create([
                    'chunk_text' => $text,
                    'chunk_index' => $index,
                ]);
            }
        });
    }

    /**
     * @return array<int, string>
     */
    private function buildChunks(string $body): array
    {
        $paragraphs = $this->splitIntoParagraphs($body);

        $chunks = [];

        foreach ($paragraphs as $paragraph) {
            if (mb_strlen($paragraph) <= self::LONG_PARAGRAPH_THRESHOLD) {
                $chunks[] = $paragraph;

                continue;
            }

            array_push($chunks, ...$this->splitLongParagraph($paragraph));
        }

        return $chunks;
    }

    /**
     * @return array<int, string>
     */
    private function splitIntoParagraphs(string $body): array
    {
        $paragraphs = preg_split('/\r?\n\s*\r?\n/', trim($body)) ?: [];

        return array_values(array_filter(
            array_map('trim', $paragraphs),
            fn (string $paragraph) => $paragraph !== ''
        ));
    }

    /**
     * Split a long paragraph into ~400-char pieces, preferring sentence
     * boundaries over hard cuts.
     *
     * @return array<int, string>
     */
    private function splitLongParagraph(string $paragraph): array
    {
        $sentences = preg_split('/(?<=[.!?])\s+/', $paragraph) ?: [$paragraph];

        $pieces = [];
        $current = '';

        foreach ($sentences as $sentence) {
            $candidate = $current === '' ? $sentence : $current.' '.$sentence;

            if ($current !== '' && mb_strlen($candidate) > self::SPLIT_CHUNK_SIZE) {
                $pieces[] = $current;
                $current = $sentence;
            } else {
                $current = $candidate;
            }

            // A single sentence longer than the target size on its own: hard-cut it.
            while (mb_strlen($current) > self::SPLIT_CHUNK_SIZE) {
                $pieces[] = trim(mb_substr($current, 0, self::SPLIT_CHUNK_SIZE));
                $current = trim(mb_substr($current, self::SPLIT_CHUNK_SIZE));
            }
        }

        if ($current !== '') {
            $pieces[] = $current;
        }

        return $pieces;
    }
}
