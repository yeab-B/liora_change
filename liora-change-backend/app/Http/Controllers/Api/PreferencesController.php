<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Http\Requests\PreferenceUpdateRequest;
use App\Http\Resources\PreferenceResource;

class PreferencesController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Preferences retrieved.',
            'data' => [
                'preferences' => new PreferenceResource($request->user()->preferences)
            ],
            'errors' => null
        ]);
    }

    public function update(PreferenceUpdateRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $request->user()->preferences()->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Preferences updated successfully.',
            'data' => [
                'preferences' => new PreferenceResource($request->user()->preferences->fresh())
            ],
            'errors' => null
        ]);
    }
}
