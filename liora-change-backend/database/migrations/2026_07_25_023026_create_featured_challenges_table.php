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
        Schema::create('featured_challenges', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('challenge_id');
            $table->integer('display_priority')->default(0);
            $table->timestamp('publish_date')->nullable();
            $table->timestamp('expiration_date')->nullable();
            $table->boolean('is_visible')->default(true);
            $table->string('campaign_support')->nullable();
            $table->timestamps();
            
            $table->foreign('challenge_id')->references('id')->on('challenges')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('featured_challenges');
    }
};
