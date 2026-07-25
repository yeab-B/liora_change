<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\RecoveryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RecoveryController extends Controller
{
    public function __construct(
        private readonly RecoveryService $recoveryService,
    ) {
    }

    /**
     * GET /api/v1/recovery/current — standalone recovery check, delegating
     * to the same RecoveryService used by DashboardController so the "one
     * missed day doesn't erase your progress" rule is never duplicated.
     */
    public function current(Request $request): JsonResponse
    {
        return response()->json([
            'data' => $this->recoveryService->currentFor($request->user()),
        ]);
    }
}
