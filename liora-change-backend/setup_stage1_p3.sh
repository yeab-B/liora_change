#!/bin/bash
set -e

mkdir -p app/Http/Controllers/Api

# Profile Controller
cat << 'EOF' > app/Http/Controllers/Api/ProfileController.php
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json([
            'profile' => $request->user()->profile
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'first_name' => 'nullable|string|max:255',
            'last_name' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:20',
            'country_id' => 'nullable|string',
            'language_id' => 'nullable|string',
            'timezone' => 'nullable|string',
            'date_format' => 'nullable|string',
            'biography' => 'nullable|string',
            'birth_date' => 'nullable|date',
            'gender' => 'nullable|string',
            'occupation' => 'nullable|string',
            'personal_goals' => 'nullable|string',
        ]);

        $request->user()->profile()->update($validated);

        return response()->json([
            'message' => 'Profile updated successfully.',
            'profile' => $request->user()->profile->fresh()
        ]);
    }
}
EOF

# Preferences Controller
cat << 'EOF' > app/Http/Controllers/Api/PreferencesController.php
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class PreferencesController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json([
            'preferences' => $request->user()->preferences
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'notifications_enabled' => 'nullable|boolean',
            'dark_mode' => 'nullable|boolean',
            'weekly_reports' => 'nullable|boolean',
            'reminder_time' => 'nullable|string',
            'measurement_units' => 'nullable|string|in:metric,imperial',
            'theme' => 'nullable|string',
            'privacy_settings' => 'nullable|array',
        ]);

        $request->user()->preferences()->update($validated);

        return response()->json([
            'message' => 'Preferences updated successfully.',
            'preferences' => $request->user()->preferences->fresh()
        ]);
    }
}
EOF

# Admin Controller
cat << 'EOF' > app/Http/Controllers/Api/AdminUserController.php
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use App\Shared\Enums\AccountStatus;

class AdminUserController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json([
            'users' => User::with('roles', 'profile')->paginate(15)
        ]);
    }

    public function show(User $user): JsonResponse
    {
        return response()->json([
            'user' => $user->load('roles', 'profile', 'preferences')
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'role' => 'required|string|exists:roles,name',
            'status' => 'required|string|in:active,inactive,suspended,blocked,deleted,pending_verification',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'status' => $validated['status'],
        ]);

        $user->assignRole($validated['role']);
        $user->profile()->create();
        $user->preferences()->create();

        return response()->json([
            'message' => 'User created successfully.',
            'user' => $user->load('roles', 'profile', 'preferences')
        ], 201);
    }

    public function update(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|string|email|max:255|unique:users,email,'.$user->id,
            'role' => 'sometimes|string|exists:roles,name',
            'status' => 'sometimes|string|in:active,inactive,suspended,blocked,deleted,pending_verification',
        ]);

        $user->update($request->only(['name', 'email', 'status']));

        if ($request->has('role')) {
            $user->syncRoles([$validated['role']]);
        }

        return response()->json([
            'message' => 'User updated successfully.',
            'user' => $user->fresh('roles', 'profile', 'preferences')
        ]);
    }

    public function destroy(User $user): JsonResponse
    {
        $user->delete();
        return response()->json([
            'message' => 'User deleted successfully.'
        ]);
    }
}
EOF

# Update API Routes
cat << 'EOF' > routes/api.php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\PreferencesController;
use App\Http\Controllers\Api\AdminUserController;

Route::prefix('v1')->group(function () {
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/auth/me', [AuthController::class, 'me']);
        
        Route::get('/profile', [ProfileController::class, 'show']);
        Route::put('/profile', [ProfileController::class, 'update']);

        Route::get('/preferences', [PreferencesController::class, 'show']);
        Route::put('/preferences', [PreferencesController::class, 'update']);
    });
    
    // Admin routes protected by sanctum and role middleware
    Route::middleware(['auth:sanctum', 'role:SuperAdmin|Admin'])->prefix('admin')->group(function () {
        Route::apiResource('users', AdminUserController::class);
    });
});
EOF

# Feature Tests
cat << 'EOF' > tests/Feature/ProfileTest.php
<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;

class ProfileTest extends TestCase
{
    use RefreshDatabase;
    protected $seed = true;

    public function test_user_can_view_profile()
    {
        $user = User::factory()->create();
        $user->profile()->create(['first_name' => 'John']);

        $response = $this->actingAs($user)->getJson('/api/v1/profile');

        $response->assertStatus(200)
                 ->assertJsonPath('profile.first_name', 'John');
    }

    public function test_user_can_update_profile()
    {
        $user = User::factory()->create();
        $user->profile()->create();

        $response = $this->actingAs($user)->putJson('/api/v1/profile', [
            'first_name' => 'Jane',
            'last_name' => 'Smith',
        ]);

        $response->assertStatus(200)
                 ->assertJsonPath('profile.first_name', 'Jane')
                 ->assertJsonPath('profile.last_name', 'Smith');
    }
}
EOF

cat << 'EOF' > tests/Feature/PreferencesTest.php
<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;

class PreferencesTest extends TestCase
{
    use RefreshDatabase;
    protected $seed = true;

    public function test_user_can_view_preferences()
    {
        $user = User::factory()->create();
        $user->preferences()->create(['dark_mode' => true]);

        $response = $this->actingAs($user)->getJson('/api/v1/preferences');

        $response->assertStatus(200)
                 ->assertJsonPath('preferences.dark_mode', true);
    }

    public function test_user_can_update_preferences()
    {
        $user = User::factory()->create();
        $user->preferences()->create();

        $response = $this->actingAs($user)->putJson('/api/v1/preferences', [
            'dark_mode' => true,
            'theme' => 'dark_theme',
        ]);

        $response->assertStatus(200)
                 ->assertJsonPath('preferences.dark_mode', true)
                 ->assertJsonPath('preferences.theme', 'dark_theme');
    }
}
EOF

cat << 'EOF' > tests/Feature/AdminUserTest.php
<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Shared\Enums\RoleName;

class AdminUserTest extends TestCase
{
    use RefreshDatabase;
    protected $seed = true;

    public function test_admin_can_list_users()
    {
        $admin = User::where('email', 'admin@liorachange.com')->first();
        
        $response = $this->actingAs($admin)->getJson('/api/v1/admin/users');

        $response->assertStatus(200)
                 ->assertJsonStructure(['users' => ['data', 'current_page']]);
    }

    public function test_regular_user_cannot_list_users()
    {
        $user = User::factory()->create();
        $user->assignRole(RoleName::FreeUser->value);

        $response = $this->actingAs($user)->getJson('/api/v1/admin/users');

        $response->assertStatus(403);
    }

    public function test_admin_can_create_user()
    {
        $admin = User::where('email', 'admin@liorachange.com')->first();
        
        $response = $this->actingAs($admin)->postJson('/api/v1/admin/users', [
            'name' => 'New User',
            'email' => 'new@user.com',
            'password' => 'password',
            'role' => RoleName::PremiumUser->value,
            'status' => 'active',
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('users', ['email' => 'new@user.com']);
        $this->assertTrue(User::where('email', 'new@user.com')->first()->hasRole(RoleName::PremiumUser->value));
    }
}
EOF
