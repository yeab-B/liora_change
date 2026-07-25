<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\MotivationRequest;
use App\Http\Resources\Api\V1\MotivationResource;
use App\Models\Challenge;
use App\Models\User;
use App\Services\Ai\MotivationService;
use App\Shared\Enums\ChallengeStatus;
use Illuminate\Http\JsonResponse;

class MotivationController extends Controller
{
    public function __construct(
        private readonly MotivationService $motivationService,
    ) {
    }

    /**
     * POST /api/v1/ai/motivation — always returns 200 with a usable message,
     * even when OpenAI is unreachable or unconfigured
     * (docs/mvp/issues/07-ai-motivation.md).
     */
    public function generate(MotivationRequest $request): JsonResponse
    {
        $user = $request->user();
        $context = $request->validated('context') ?? 'general';
        $challengeId = $request->validated('challenge_id');

        if ($challengeId !== null) {
            $challenge = Challenge::find($challengeId);

            if ($challenge === null) {
                return response()->json([
                    'message' => 'Challenge not found',
                    'code' => 'NOT_FOUND',
                ], 404);
            }

            $this->authorize('view', $challenge);
        } else {
            $challenge = $this->mostRecentlyActiveChallenge($user);
        }

        $result = $this->motivationService->generate($user, $challenge, $context);

        return response()->json([
            'data' => new MotivationResource($result),
        ]);
    }

    private function mostRecentlyActiveChallenge(User $user): ?Challenge
    {
        return $user->challenges()
            ->where('status', ChallengeStatus::Active->value)
            ->orderByDesc('start_date')
            ->orderByDesc('updated_at')
            ->first();
    }
}
