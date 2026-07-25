<?php

namespace Database\Factories;

use App\Models\KnowledgeArticle;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<KnowledgeArticle>
 */
class KnowledgeArticleFactory extends Factory
{
    protected $model = KnowledgeArticle::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'title' => fake()->sentence(3),
            'body' => fake()->paragraphs(2, true),
            'category' => 'faq',
            'is_active' => true,
        ];
    }
}
