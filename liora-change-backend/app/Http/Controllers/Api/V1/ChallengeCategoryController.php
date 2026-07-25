<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ChallengeCategoryResource;
use App\Models\ChallengeCategory;
use Illuminate\Http\JsonResponse;

class ChallengeCategoryController extends Controller
{
    /**
     * GET /api/v1/challenge-categories — read-only list for mobile so users
     * can create a challenge from a curated category instead of a blank form.
     */
    public function index(): JsonResponse
    {
        $categories = ChallengeCategory::orderBy('id')->get();

        return response()->json([
            'data' => ChallengeCategoryResource::collection($categories),
        ]);
    }
}
