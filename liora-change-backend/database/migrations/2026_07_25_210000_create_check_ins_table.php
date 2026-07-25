<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * `streak_after` is a deliberate, minimal addition beyond the issue's
     * literal column list: docs/mvp/teams/SHARED-DATA-CONTRACT.md §3.4
     * requires every CheckIn (including historical rows returned by
     * `GET /challenges/{id}/check-ins`) to carry `streak_after`. That value
     * is only meaningful as a point-in-time snapshot, so it must be stored
     * at write-time rather than recomputed on read.
     */
    public function up(): void
    {
        Schema::create('check_ins', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained();
            $table->foreignId('challenge_id')->constrained()->cascadeOnDelete();
            $table->date('check_in_date');
            $table->string('status', 16);
            $table->text('note')->nullable();
            $table->unsignedTinyInteger('mood')->nullable();
            $table->unsignedTinyInteger('energy')->nullable();
            $table->integer('xp_earned')->default(0);
            $table->integer('streak_after')->default(0);
            $table->timestamps();

            $table->unique(['challenge_id', 'check_in_date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('check_ins');
    }
};
