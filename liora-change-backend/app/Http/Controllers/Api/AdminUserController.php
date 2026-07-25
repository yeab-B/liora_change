<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use App\Shared\Enums\AccountStatus;
use App\Http\Resources\UserResource;

class AdminUserController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Users retrieved.',
            'data' => [
                'users' => UserResource::collection(User::with('roles', 'profile')->paginate(15))
            ],
            'errors' => null
        ]);
    }

    public function show(User $user): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'User retrieved.',
            'data' => [
                'user' => new UserResource($user->load('roles', 'profile', 'preferences'))
            ],
            'errors' => null
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
            'success' => true,
            'message' => 'User created successfully.',
            'data' => [
                'user' => new UserResource($user->load('roles', 'profile', 'preferences'))
            ],
            'errors' => null
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
            'success' => true,
            'message' => 'User updated successfully.',
            'data' => [
                'user' => new UserResource($user->fresh('roles', 'profile', 'preferences'))
            ],
            'errors' => null
        ]);
    }

    public function destroy(User $user): JsonResponse
    {
        $user->delete();
        return response()->json([
            'success' => true,
            'message' => 'User deleted successfully.',
            'data' => [],
            'errors' => null
        ]);
    }
}
