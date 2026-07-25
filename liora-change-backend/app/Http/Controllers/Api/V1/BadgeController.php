<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\BadgeUnlockedResource;
use App\Models\UserBadge;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BadgeController extends Controller
{
    /**
     * GET /api/v1/badges/unlocked — the authenticated user's unlocked
     * badges, most recently unlocked first.
     */
    public function unlocked(Request $request): JsonResponse
    {
        $userBadges = UserBadge::with('badge')
            ->where('user_id', $request->user()->id)
            ->orderByDesc('unlocked_at')
            ->get();

        return response()->json([
            'data' => BadgeUnlockedResource::collection($userBadges),
        ]);
    }
}
