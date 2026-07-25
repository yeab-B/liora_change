<?php

namespace Tests\Feature;

use App\Models\KnowledgeArticle;
use App\Services\Ai\KnowledgeChunker;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class KnowledgeChunkerTest extends TestCase
{
    use RefreshDatabase;

    public function test_multi_paragraph_body_produces_multiple_ordered_chunks(): void
    {
        $article = KnowledgeArticle::create([
            'title' => 'Test Article',
            'category' => 'faq',
            'body' => "First paragraph about habits.\n\nSecond paragraph about recovery.\n\nThird paragraph about streaks.",
            'is_active' => true,
        ]);

        // The `saved` event already chunked it; re-run explicitly too so
        // this test also exercises KnowledgeChunker::chunk() directly.
        app(KnowledgeChunker::class)->chunk($article);

        $chunks = $article->chunks()->orderBy('chunk_index')->get();

        $this->assertCount(3, $chunks);
        $this->assertSame(0, $chunks[0]->chunk_index);
        $this->assertSame(1, $chunks[1]->chunk_index);
        $this->assertSame(2, $chunks[2]->chunk_index);
        $this->assertStringContainsString('habits', $chunks[0]->chunk_text);
        $this->assertStringContainsString('recovery', $chunks[1]->chunk_text);
        $this->assertStringContainsString('streaks', $chunks[2]->chunk_text);
    }

    public function test_long_paragraph_is_split_into_smaller_pieces(): void
    {
        $longSentence = 'This is a fairly long sentence that keeps going and going to simulate real coaching content. ';
        $longParagraph = trim(str_repeat($longSentence, 8)); // ~760 chars, one "paragraph"

        $article = KnowledgeArticle::create([
            'title' => 'Long Article',
            'category' => 'faq',
            'body' => $longParagraph,
            'is_active' => true,
        ]);

        $chunks = $article->chunks()->orderBy('chunk_index')->get();

        $this->assertGreaterThan(1, $chunks->count());

        foreach ($chunks as $chunk) {
            $this->assertLessThanOrEqual(400, mb_strlen($chunk->chunk_text));
        }
    }

    public function test_rechunking_on_update_replaces_old_chunks(): void
    {
        $article = KnowledgeArticle::create([
            'title' => 'Editable Article',
            'category' => 'faq',
            'body' => "Original paragraph one.\n\nOriginal paragraph two.",
            'is_active' => true,
        ]);

        $this->assertCount(2, $article->chunks()->get());

        $article->update(['body' => 'A single short replacement paragraph.']);

        $chunks = $article->chunks()->get();
        $this->assertCount(1, $chunks);
        $this->assertSame('A single short replacement paragraph.', $chunks->first()->chunk_text);
    }
}
