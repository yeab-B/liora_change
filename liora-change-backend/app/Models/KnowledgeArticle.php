<?php

namespace App\Models;

use App\Services\Ai\KnowledgeChunker;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class KnowledgeArticle extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'title',
        'body',
        'category',
        'is_active',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function chunks(): HasMany
    {
        return $this->hasMany(KnowledgeChunk::class)->orderBy('chunk_index');
    }

    /**
     * Re-chunk on every create/update so `knowledge_chunks` always matches
     * the current `body` (docs/mvp/issues/08-ai-rag-chat.md "Chunking logic").
     */
    protected static function booted(): void
    {
        static::saved(function (KnowledgeArticle $article) {
            app(KnowledgeChunker::class)->chunk($article);
        });
    }
}
