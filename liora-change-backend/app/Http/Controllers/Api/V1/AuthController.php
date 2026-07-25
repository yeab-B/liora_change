<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\LoginRequest;
use App\Http\Requests\Api\V1\RegisterRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    /**
     * Register a new member and issue a Sanctum API token.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name' => $request->validated('name'),
            'email' => $request->validated('email'),
            'password' => $request->validated('password'),
            'timezone' => $request->validated('timezone') ?? 'UTC',
        ]);

        $token = $user->createToken($this->deviceName($request))->plainTextToken;

        return $this->authResponse($user, $token, 201);
    }

    /**
     * Authenticate an existing member and issue a new Sanctum API token.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->validated('email'))->first();

        if (! $user || ! Hash::check($request->validated('password'), $user->password)) {
            return response()->json([
                'message' => 'These credentials do not match our records.',
                'code' => 'INVALID_CREDENTIALS',
                'errors' => [
                    'email' => ['These credentials do not match our records.'],
                ],
            ], 422);
        }

        $token = $user->createToken($this->deviceName($request))->plainTextToken;

        return $this->authResponse($user, $token, 200);
    }

    /**
     * Revoke the token used to authenticate the current request.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out',
        ]);
    }

    /**
     * Resolve the Sanctum token name from the request, defaulting to "api"
     * when the client did not send a device name (e.g. register calls).
     */
    private function deviceName(Request $request): string
    {
        $deviceName = $request->input('device_name');

        return is_string($deviceName) && $deviceName !== '' ? $deviceName : 'api';
    }

    /**
     * Build the shared { user, token } envelope used by register/login.
     */
    private function authResponse(User $user, string $token, int $status): JsonResponse
    {
        return response()->json([
            'data' => [
                'user' => new UserResource($user),
                'token' => $token,
            ],
        ], $status);
    }
}
