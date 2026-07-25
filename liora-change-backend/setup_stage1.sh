#!/bin/bash
set -e

# Create Enums
mkdir -p app/Shared/Enums
cat << 'EOF' > app/Shared/Enums/AccountStatus.php
<?php
namespace App\Shared\Enums;

enum AccountStatus: string {
    case Active = 'active';
    case Inactive = 'inactive';
    case Suspended = 'suspended';
    case Blocked = 'blocked';
    case Deleted = 'deleted';
    case PendingVerification = 'pending_verification';

    public function isAccessible(): bool {
        return $this === self::Active;
    }
}
EOF

cat << 'EOF' > app/Shared/Enums/RoleName.php
<?php
namespace App\Shared\Enums;

enum RoleName: string {
    case SuperAdmin = 'SuperAdmin';
    case Admin = 'Admin';
    case ContentManager = 'ContentManager';
    case SupportStaff = 'SupportStaff';
    case PremiumUser = 'PremiumUser';
    case RegisteredUser = 'RegisteredUser';
    case FreeUser = 'FreeUser';
    case Guest = 'Guest';
}
EOF

cat << 'EOF' > app/Shared/Enums/PermissionName.php
<?php
namespace App\Shared\Enums;

enum PermissionName: string {
    case ManageUsers = 'manage users';
    case ManageRoles = 'manage roles';
    case ManageSettings = 'manage settings';
}
EOF

# Create Migrations and Models
php artisan make:model UserProfile -m
php artisan make:model UserPreference -m
php artisan make:model LoginHistory -m
php artisan make:model AuditLog -m

# Now we need to overwrite the users migration
cat << 'EOF' > database/migrations/0001_01_01_000000_create_users_table.php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->string('status')->default('active');
            $table->rememberToken();
            $table->timestamps();
            $table->softDeletes();
        });
        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });
        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }
    public function down(): void {
        Schema::dropIfExists('users');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('sessions');
    }
};
EOF

# Overwrite Profile Migration
PROFILE_MIGRATION=$(ls database/migrations/*_create_user_profiles_table.php)
cat << 'EOF' > $PROFILE_MIGRATION
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('user_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('first_name')->nullable();
            $table->string('last_name')->nullable();
            $table->string('phone')->nullable();
            $table->string('country_id')->nullable();
            $table->string('language_id')->nullable();
            $table->string('timezone')->nullable();
            $table->string('date_format')->nullable();
            $table->text('biography')->nullable();
            $table->date('birth_date')->nullable();
            $table->string('gender')->nullable();
            $table->string('occupation')->nullable();
            $table->text('personal_goals')->nullable();
            $table->timestamps();
        });
    }
    public function down(): void {
        Schema::dropIfExists('user_profiles');
    }
};
EOF

# Overwrite Preference Migration
PREF_MIGRATION=$(ls database/migrations/*_create_user_preferences_table.php)
cat << 'EOF' > $PREF_MIGRATION
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
EOF

php artisan migrate:fresh
