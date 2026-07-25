<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * The FULLTEXT index is MySQL-only (InnoDB/MySQL 5.6+) — SQLite's schema
     * grammar has no `fullText()` support and would throw during
     * `php artisan test`'s RefreshDatabase (sqlite :memory:), so it's only
     * added when the active connection is actually MySQL. See
     * App\Services\Ai\SimpleRagRetriever, which likewise only attempts a
     * FULLTEXT query on MySQL and uses a LIKE-based fallback otherwise.
     */
    public function up(): void
    {
        Schema::create('knowledge_chunks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('knowledge_article_id')->constrained()->cascadeOnDelete();
            $table->text('chunk_text');
            $table->integer('chunk_index');
            $table->timestamps();
        });

        if (Schema::getConnection()->getDriverName() === 'mysql') {
            Schema::table('knowledge_chunks', function (Blueprint $table) {
                $table->fullText('chunk_text');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('knowledge_chunks');
    }
};
