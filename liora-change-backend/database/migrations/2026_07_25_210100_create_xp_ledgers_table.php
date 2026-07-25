<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * No `updated_at` column: xp_ledgers is an append-only ledger, rows are
     * never edited after creation (see App\Models\XpLedger::UPDATED_AT).
     */
    public function up(): void
    {
        Schema::create('xp_ledgers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained();
            $table->foreignId('challenge_id')->nullable()->constrained('challenges')->nullOnDelete();
            $table->integer('amount');
            $table->string('reason', 64);
            $table->timestamp('created_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('xp_ledgers');
    }
};
