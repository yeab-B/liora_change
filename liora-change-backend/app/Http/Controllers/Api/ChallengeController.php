<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreChallengeRequest;
use App\Http\Requests\UpdateChallengeRequest;
use App\Models\Challenge;
use App\Services\ChallengeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChallengeController extends Controller
{
    protected ChallengeService $challengeService;

    public function __construct(ChallengeService $challengeService)
    {
        $this->challengeService = $challengeService;
    }

    public function index(): JsonResponse
    {
        $challenges = Challenge::where('user_id', auth()->id())->paginate(15);
        
        return response()->json([
            'success' => true,
            'message' => 'Challenges retrieved successfully.',
            'data' => ['challenges' => $challenges]
        ]);
    }

    public function store(StoreChallengeRequest $request): JsonResponse
    {
        $challenge = $this->challengeService->createDraft($request->validated(), auth()->id());
        
        return response()->json([
            'success' => true,
            'message' => 'Challenge created successfully.',
            'data' => ['challenge' => $challenge]
        ], 201);
    }

    public function show(Challenge $challenge): JsonResponse
    {
        if ($challenge->user_id !== auth()->id()) {
            abort(403, 'Unauthorized access to challenge.');
        }

        return response()->json([
            'success' => true,
            'message' => 'Challenge retrieved successfully.',
            'data' => ['challenge' => $challenge]
        ]);
    }
}
