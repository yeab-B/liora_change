<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\InvalidStatusTransitionException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreChallengeRequest;
use App\Http\Resources\Api\V1\ChallengeResource;
use App\Models\Challenge;
use App\Services\ChallengeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChallengeController extends Controller
{
    public function __construct(private readonly ChallengeService $challengeService)
    {
    }

    /**
     * GET /api/v1/challenges — the authenticated user's own challenges,
     * newest first. Optional `?status=` filter.
     */
    public function index(Request $request): JsonResponse
    {
        $challenges = $request->user()
            ->challenges()
            ->when($request->query('status'), fn ($query, $status) => $query->where('status', $status))
            ->latest()
            ->get();

        return response()->json([
            'data' => ChallengeResource::collection($challenges),
        ]);
    }

    /**
     * POST /api/v1/challenges — create a new draft challenge owned by the
     * authenticated user.
     */
    public function store(StoreChallengeRequest $request): JsonResponse
    {
        $challenge = $this->challengeService->createDraft(
            $request->validated(),
            $request->user()->id
        );

        return response()->json([
            'data' => new ChallengeResource($challenge),
        ], 201);
    }

    /**
     * GET /api/v1/challenges/{challenge} — owner only (403 otherwise).
     */
    public function show(Challenge $challenge): JsonResponse
    {
        $this->authorize('view', $challenge);

        return response()->json([
            'data' => new ChallengeResource($challenge),
        ]);
    }

    /**
     * POST /api/v1/challenges/{challenge}/activate — owner only, draft/ready
     * -> active. Returns 422 INVALID_STATUS_TRANSITION when not allowed.
     */
    public function activate(Challenge $challenge): JsonResponse
    {
        $this->authorize('update', $challenge);

        try {
            $challenge = $this->challengeService->activate($challenge);
        } catch (InvalidStatusTransitionException $e) {
            return response()->json([
                'message' => $e->getMessage(),
                'code' => 'INVALID_STATUS_TRANSITION',
            ], 422);
        }

        return response()->json([
            'data' => new ChallengeResource($challenge),
        ]);
    }
}
