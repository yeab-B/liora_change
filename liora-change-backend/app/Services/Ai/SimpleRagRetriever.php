<?php

namespace App\Services\Ai;

use App\Models\KnowledgeChunk;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Keyword-based retrieval over `knowledge_chunks` — no vector DB required for
 * the MVP (docs/mvp/issues/08-ai-rag-chat.md "Retrieval").
 */
class SimpleRagRetriever
{
    /**
     * Common short/stop words to ignore when extracting search keywords.
     *
     * @var array<int, string>
     */
    private const STOP_WORDS = [
        'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been',
        'do', 'does', 'did', 'what', 'when', 'where', 'why', 'how',
        'should', 'would', 'could', 'can', 'will',
        'i', 'my', 'me', 'you', 'your', 'it', 'its',
        'to', 'if', 'in', 'on', 'of', 'for', 'and', 'or', 'with', 'about',
    ];

    /**
     * Retrieve up to $limit relevant chunks for $query. Only chunks whose
     * article is active are considered. Never returns an empty collection
     * if at least one active chunk exists in the table.
     *
     * @return Collection<int, KnowledgeChunk>
     */
    public function retrieve(string $query, int $limit = 5): Collection
    {
        $chunks = $this->fullTextSearch($query, $limit);

        if ($chunks->isEmpty()) {
            $chunks = $this->keywordSearch($query, $limit);
        }

        if ($chunks->isEmpty()) {
            $chunks = $this->mostRecentChunks($limit);
        }

        return $chunks;
    }

    private function activeChunksQuery(): Builder
    {
        return KnowledgeChunk::query()
            ->with('article')
            ->whereHas('article', fn (Builder $articles) => $articles->where('is_active', true));
    }

    /**
     * MySQL FULLTEXT natural-language search. Only attempted on MySQL —
     * SQLite (used in tests) has no MATCH...AGAINST support, so this
     * intentionally no-ops there and lets the LIKE fallback take over.
     *
     * @return Collection<int, KnowledgeChunk>
     */
    private function fullTextSearch(string $query, int $limit): Collection
    {
        if (trim($query) === '' || DB::connection()->getDriverName() !== 'mysql') {
            return new Collection();
        }

        try {
            return $this->activeChunksQuery()
                ->whereRaw('MATCH(chunk_text) AGAINST (? IN NATURAL LANGUAGE MODE)', [$query])
                ->selectRaw('knowledge_chunks.*, MATCH(chunk_text) AGAINST (? IN NATURAL LANGUAGE MODE) as relevance', [$query])
                ->orderByDesc('relevance')
                ->limit($limit)
                ->get();
        } catch (\Throwable) {
            return new Collection();
        }
    }

    /**
     * Fallback: LIKE '%keyword%' over a few extracted keywords from the
     * query.
     *
     * @return Collection<int, KnowledgeChunk>
     */
    private function keywordSearch(string $query, int $limit): Collection
    {
        $keywords = $this->extractKeywords($query);

        if (empty($keywords)) {
            return new Collection();
        }

        return $this->activeChunksQuery()
            ->where(function (Builder $builder) use ($keywords) {
                foreach ($keywords as $keyword) {
                    $builder->orWhere('chunk_text', 'like', "%{$keyword}%");
                }
            })
            ->latest('id')
            ->limit($limit)
            ->get();
    }

    /**
     * Last-resort fallback so the chat never ends up with zero context when
     * chunks exist.
     *
     * @return Collection<int, KnowledgeChunk>
     */
    private function mostRecentChunks(int $limit): Collection
    {
        return $this->activeChunksQuery()
            ->latest('id')
            ->limit($limit)
            ->get();
    }

    /**
     * @return array<int, string>
     */
    private function extractKeywords(string $query): array
    {
        $words = preg_split('/[^\p{L}\p{N}]+/u', strtolower(trim($query))) ?: [];

        return array_values(array_unique(array_filter(
            $words,
            fn (string $word) => mb_strlen($word) >= 3 && ! in_array($word, self::STOP_WORDS, true)
        )));
    }
}
