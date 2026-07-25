<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('challenges', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('title');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->text('motivation')->nullable();
            $table->uuid('category_id')->nullable();
            $table->string('difficulty_score')->default('beginner');
            $table->string('status')->default('draft');
            $table->string('visibility')->default('private');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('cover_image')->nullable();
            $table->string('color')->nullable();
            $table->string('icon')->nullable();
            
            // AI Compatibility
            $table->boolean('ai_generated')->default(false);
            $table->text('ai_prompt')->nullable();
            $table->text('ai_summary')->nullable();
            $table->text('ai_recommendation')->nullable();
            $table->integer('ai_difficulty_score')->nullable();
            $table->boolean('ai_suggested_tasks')->default(false);
            $table->boolean('ai_generated_schedule')->default(false);
            $table->float('ai_confidence')->nullable();

            $table->timestamps();
            $table->softDeletes();

            $table->foreign('category_id')->references('id')->on('challenge_categories')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('challenges');
    }
};
