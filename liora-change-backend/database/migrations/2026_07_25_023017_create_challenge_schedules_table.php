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
        Schema::create('challenge_schedules', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('challenge_id');
            $table->string('type')->default('daily'); // daily, weekly, monthly, custom
            $table->json('weekdays')->nullable();
            $table->time('reminder_time')->nullable();
            $table->string('timezone')->nullable();
            $table->integer('duration_days')->nullable();
            $table->boolean('is_unlimited')->default(false);
            $table->timestamps();
            $table->softDeletes();
            
            $table->foreign('challenge_id')->references('id')->on('challenges')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('challenge_schedules');
    }
};
