<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\XpLedgerResource;
use App\Models\XpLedger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class XpController extends Controller
{
    /**
     * GET /api/v1/xp/history — the authenticated user's XP ledger, newest
     * first.
     */
    public function history(Request $request): JsonResponse
    {
        $ledger = XpLedger::where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'data' => XpLedgerResource::collection($ledger),
        ]);
    }
}
