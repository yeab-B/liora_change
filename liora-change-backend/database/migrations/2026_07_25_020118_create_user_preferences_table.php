<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('user_preferences', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->boolean('notifications_enabled')->default(true);
            $table->boolean('dark_mode')->default(false);
            $table->boolean('weekly_reports')->default(true);
            $table->string('reminder_time')->nullable();
            $table->string('measurement_units')->default('metric');
            $table->string('theme')->default('default');
            $table->json('privacy_settings')->nullable();
            $table->timestamps();
        });
    }
    public function down(): void {
        Schema::dropIfExists('user_preferences');
    }
};
