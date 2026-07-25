<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ChatRequest;
use App\Http\Resources\Api\V1\ChatMessageResource;
use App\Http\Resources\Api\V1\ChatReplyResource;
use App\Http\Resources\Api\V1\ChatSessionResource;
use App\Models\Challenge;
use App\Models\ChatSession;
use App\Services\Ai\ChatService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function __construct(
        private readonly ChatService $chatService,
    ) {
    }

    /**
     * POST /api/v1/ai/chat — always returns 200 with a usable reply, even
     * when OpenAI is unreachable or unconfigured
     * (docs/mvp/issues/08-ai-rag-chat.md).
     */
    public function send(ChatRequest $request): JsonResponse
    {
        $user = $request->user();
        $sessionId = $request->validated('session_id');
        $challengeId = $request->validated('challenge_id');

        $session = null;
        if ($sessionId !== null) {
            $session = ChatSession::find($sessionId);

            if ($session === null) {
                return response()->json([
                    'message' => 'Chat session not found',
                    'code' => 'NOT_FOUND',
                ], 404);
            }

            $this->authorize('view', $session);
        }

        $challenge = null;
        if ($challengeId !== null) {
            $challenge = Challenge::find($challengeId);

            if ($challenge === null) {
                return response()->json([
                    'message' => 'Challenge not found',
                    'code' => 'NOT_FOUND',
                ], 404);
            }

            $this->authorize('view', $challenge);
        }

        $result = $this->chatService->respond($user, $request->validated('message'), $session, $challenge);

        return response()->json([
            'data' => new ChatReplyResource($result),
        ]);
    }

    /**
     * GET /api/v1/ai/chat/sessions — nice-to-have session history list.
     */
    public function sessions(Request $request): JsonResponse
    {
        $sessions = ChatSession::where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json([
            'data' => ChatSessionResource::collection($sessions),
        ]);
    }

    /**
     * GET /api/v1/ai/chat/sessions/{session}/messages — nice-to-have,
     * owner-checked.
     */
    public function messages(Request $request, ChatSession $session): JsonResponse
    {
        $this->authorize('view', $session);

        $messages = $session->messages()
            ->orderBy('created_at')
            ->orderBy('id')
            ->get();

        return response()->json([
            'data' => ChatMessageResource::collection($messages),
        ]);
    }
}
