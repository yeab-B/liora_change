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
        Schema::create('daily_check_ins', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->uuid('challenge_id');
            $table->date('date');
            $table->boolean('is_completed')->default(false);
            $table->timestamp('completion_time')->nullable();
            $table->integer('mood_score')->nullable();
            $table->integer('energy_level')->nullable();
            $table->text('reflection_notes')->nullable();
            $table->text('skipped_reason')->nullable();
            $table->timestamps();
            
            $table->foreign('challenge_id')->references('id')->on('challenges')->onDelete('cascade');
            $table->unique(['user_id', 'challenge_id', 'date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('daily_check_ins');
    }
};
