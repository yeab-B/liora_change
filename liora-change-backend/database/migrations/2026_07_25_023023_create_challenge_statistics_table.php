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
        Schema::create('challenge_statistics', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('challenge_id');
            $table->integer('participant_count')->default(0);
            $table->float('completion_rate')->default(0);
            $table->integer('average_completion_time')->nullable();
            $table->integer('average_streak')->default(0);
            $table->integer('likes')->default(0);
            $table->integer('favorites')->default(0);
            $table->integer('views')->default(0);
            $table->timestamps();
            
            $table->foreign('challenge_id')->references('id')->on('challenges')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('challenge_statistics');
    }
};
