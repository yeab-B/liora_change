<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ChallengeCategoryController;
use App\Http\Controllers\Api\V1\ChallengeController;
use App\Http\Controllers\Api\V1\ChallengeTemplateController;
use App\Http\Controllers\Api\V1\CheckInController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\MeController;
use App\Http\Controllers\Api\V1\ProgressController;
use App\Http\Controllers\Api\V1\RecoveryController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::prefix('v1')->group(function () {
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/me', [MeController::class, 'show']);
        Route::patch('/me', [MeController::class, 'update']);

        Route::get('/challenges', [ChallengeController::class, 'index']);
        Route::post('/challenges', [ChallengeController::class, 'store']);
        Route::get('/challenges/{challenge}', [ChallengeController::class, 'show']);
        Route::post('/challenges/{challenge}/activate', [ChallengeController::class, 'activate']);
        Route::post('/challenges/{challenge}/check-ins', [CheckInController::class, 'store']);
        Route::get('/challenges/{challenge}/check-ins', [CheckInController::class, 'index']);

        Route::get('/challenge-categories', [ChallengeCategoryController::class, 'index']);
        Route::get('/challenge-templates', [ChallengeTemplateController::class, 'index']);

        Route::get('/dashboard', [DashboardController::class, 'show']);
        Route::get('/recovery/current', [RecoveryController::class, 'current']);
        Route::get('/progress', [ProgressController::class, 'show']);
    });
});
