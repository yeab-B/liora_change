<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Issue #2 (challenges table) left `category_id` without a hard FK
     * constraint since `challenge_categories` did not exist yet. Now that
     * Issue #3 creates it, wire up the real constraint.
     */
    public function up(): void
    {
        Schema::table('challenges', function (Blueprint $table) {
            $table->foreign('category_id')
                ->references('id')
                ->on('challenge_categories')
                ->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('challenges', function (Blueprint $table) {
            $table->dropForeign(['category_id']);
        });
    }
};
