<?php

namespace Database\Factories;

use App\Models\KnowledgeArticle;
use App\Models\KnowledgeChunk;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<KnowledgeChunk>
 */
class KnowledgeChunkFactory extends Factory
{
    protected $model = KnowledgeChunk::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'knowledge_article_id' => KnowledgeArticle::factory(),
            'chunk_text' => fake()->paragraph(),
            'chunk_index' => 0,
        ];
    }
}
