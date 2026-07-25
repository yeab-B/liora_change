<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Http\Requests\ProfileUpdateRequest;
use App\Http\Resources\ProfileResource;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Profile retrieved.',
            'data' => [
                'profile' => new ProfileResource($request->user()->profile)
            ],
            'errors' => null
        ]);
    }

    public function update(ProfileUpdateRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $request->user()->profile()->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully.',
            'data' => [
                'profile' => new ProfileResource($request->user()->profile->fresh())
            ],
            'errors' => null
        ]);
    }
}
