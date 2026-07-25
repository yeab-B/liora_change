<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Adds the member profile/gamification fields required by the MVP
     * auth + dashboard contract (docs/mvp/teams/SHARED-DATA-CONTRACT.md).
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('timezone', 64)->nullable()->default('UTC');
            $table->integer('xp_total')->default(0);
            $table->integer('level')->default(1);
            $table->integer('current_streak')->default(0);
            $table->integer('longest_streak')->default(0);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'timezone',
                'xp_total',
                'level',
                'current_streak',
                'longest_streak',
            ]);
        });
    }
};
