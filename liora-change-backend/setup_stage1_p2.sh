#!/bin/bash
set -e

# Update User Model
cat << 'EOF' > app/Models/User.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Shared\Enums\AccountStatus;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, HasRoles;

    protected $fillable = [
        'name',
        'email',
        'password',
        'status',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'status' => AccountStatus::class,
    ];

    public function profile(): HasOne
    {
        return $this->hasOne(UserProfile::class);
    }

    public function preferences(): HasOne
    {
        return $this->hasOne(UserPreference::class);
    }

    public function loginHistories(): HasMany
    {
        return $this->hasMany(LoginHistory::class);
    }

    public function auditLogs(): HasMany
    {
        return $this->hasMany(AuditLog::class);
    }
}
EOF

# Update UserProfile Model
cat << 'EOF' > app/Models/UserProfile.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserProfile extends Model
{
    protected $fillable = [
        'user_id',
        'first_name',
        'last_name',
        'phone',
        'country_id',
        'language_id',
        'timezone',
        'date_format',
        'biography',
        'birth_date',
        'gender',
        'occupation',
        'personal_goals',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
EOF

# Update UserPreference Model
cat << 'EOF' > app/Models/UserPreference.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserPreference extends Model
{
    protected $fillable = [
        'user_id',
        'notifications_enabled',
        'dark_mode',
        'weekly_reports',
        'reminder_time',
        'measurement_units',
        'theme',
        'privacy_settings',
    ];

    protected $casts = [
        'notifications_enabled' => 'boolean',
        'dark_mode' => 'boolean',
        'weekly_reports' => 'boolean',
        'privacy_settings' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
EOF

# Create Seeder
cat << 'EOF' > database/seeders/DatabaseSeeder.php
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Shared\Enums\RoleName;
use App\Shared\Enums\PermissionName;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Permissions
        foreach (PermissionName::cases() as $permission) {
            Permission::firstOrCreate(['name' => $permission->value]);
        }

        // Roles
        foreach (RoleName::cases() as $role) {
            Role::firstOrCreate(['name' => $role->value]);
        }

        // Assign all permissions to SuperAdmin
        $superAdminRole = Role::findByName(RoleName::SuperAdmin->value);
        $superAdminRole->syncPermissions(Permission::all());

        // Create Default Admin User
        $admin = User::firstOrCreate([
            'email' => 'admin@liorachange.com'
        ], [
            'name' => 'Super Admin',
            'password' => bcrypt('password'),
            'status' => 'active',
        ]);
        $admin->assignRole(RoleName::SuperAdmin->value);
        $admin->profile()->create(['first_name' => 'Super', 'last_name' => 'Admin']);
        $admin->preferences()->create();
    }
}
EOF

php artisan db:seed

# Scaffold Auth Controller
mkdir -p app/Http/Controllers/Api
cat << 'EOF' > app/Http/Controllers/Api/AuthController.php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use App\Shared\Enums\RoleName;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'status' => 'active',
        ]);

        $user->assignRole(RoleName::FreeUser->value);
        $user->profile()->create();
        $user->preferences()->create();

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Registration successful.',
            'user' => $user->load('profile', 'preferences', 'roles'),
            'token' => $token,
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials.'],
            ]);
        }

        if ($user->status->value !== 'active') {
            return response()->json(['message' => 'Account is ' . $user->status->value . '.'], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful.',
            'user' => $user->load('profile', 'preferences', 'roles'),
            'token' => $token,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out successfully.']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'user' => $request->user()->load('profile', 'preferences', 'roles')
        ]);
    }
}
EOF

cat << 'EOF' > routes/api.php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;

Route::prefix('v1')->group(function () {
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/auth/me', [AuthController::class, 'me']);
    });
});
EOF
