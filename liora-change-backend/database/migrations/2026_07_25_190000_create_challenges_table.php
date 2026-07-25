<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * `category_id` intentionally has no hard FK constraint yet: the
     * `challenge_categories` table is created in Issue #3 and the two
     * migrations may land in either order. Add the FK constraint in a
     * follow-up migration once #3 is merged.
     */
    public function up(): void
    {
        Schema::create('challenges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('category_id')->nullable();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('status', 32)->default('draft');
            $table->string('difficulty', 32)->default('beginner');
            $table->string('visibility', 32)->default('private');
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->integer('duration_days')->default(7);
            $table->integer('current_streak')->default(0);
            $table->integer('longest_streak')->default(0);
            $table->timestamps();

            $table->index(['user_id', 'status']);
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
