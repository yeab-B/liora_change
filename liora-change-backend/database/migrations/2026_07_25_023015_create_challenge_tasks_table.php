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
        Schema::create('challenge_tasks', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('challenge_id');
            $table->string('title');
            $table->text('description')->nullable();
            $table->integer('day_number')->nullable(); // For daily structured tasks
            $table->integer('order')->default(0);
            $table->integer('estimated_minutes')->nullable();
            $table->boolean('is_required')->default(true);
            $table->string('completion_rule')->nullable();
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
        Schema::dropIfExists('challenge_tasks');
    }
};
