<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ChallengeTemplateResource;
use App\Models\ChallengeTemplate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChallengeTemplateController extends Controller
{
    /**
     * GET /api/v1/challenge-templates — read-only list for mobile, with an
     * optional `?category_id=` filter.
     */
    public function index(Request $request): JsonResponse
    {
        $templates = ChallengeTemplate::query()
            ->when(
                $request->query('category_id'),
                fn ($query, $categoryId) => $query->where('category_id', $categoryId)
            )
            ->orderBy('id')
            ->get();

        return response()->json([
            'data' => ChallengeTemplateResource::collection($templates),
        ]);
    }
}
