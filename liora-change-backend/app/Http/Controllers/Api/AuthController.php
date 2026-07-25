<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use App\Shared\Enums\RoleName;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Resources\UserResource;

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();

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
            'success' => true,
            'message' => 'Registration successful.',
            'data' => [
                'user' => new UserResource($user->load('profile', 'preferences', 'roles')),
                'token' => $token,
            ],
            'errors' => null
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => [
                    'email' => ['Invalid credentials.']
                ]
            ], 422);
        }

        if ($user->status->value !== 'active') {
            return response()->json([
                'success' => false,
                'message' => 'Account is ' . $user->status->value . '.',
                'errors' => null
            ], 403);
        }

        $token = $user->createToken($validated['device_name'] ?? 'auth_token')->plainTextToken;

        // Log login history
        $user->loginHistories()->create([
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'login_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'data' => [
                'user' => new UserResource($user->load('profile', 'preferences', 'roles')),
                'token' => $token,
            ],
            'errors' => null
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        // Update login history logout_at
        $currentAccessToken = $request->user()->currentAccessToken();
        
        $request->user()->currentAccessToken()->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully.',
            'data' => [],
            'errors' => null
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'User profile retrieved.',
            'data' => [
                'user' => new UserResource($request->user()->load('profile', 'preferences', 'roles'))
            ],
            'errors' => null
        ]);
    }
}
