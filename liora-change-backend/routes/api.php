<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\PreferencesController;
use App\Http\Controllers\Api\AdminUserController;

Route::prefix('v1')->group(function () {
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/auth/me', [AuthController::class, 'me']);
        
        Route::get('/profile', [ProfileController::class, 'show']);
        Route::put('/profile', [ProfileController::class, 'update']);

        Route::get('/preferences', [PreferencesController::class, 'show']);
        Route::put('/preferences', [PreferencesController::class, 'update']);
        
        // Challenges
        Route::apiResource('challenges', \App\Http\Controllers\Api\ChallengeController::class);
    });
    
    // Admin routes protected by sanctum and role middleware
    Route::middleware(['auth:sanctum', 'role:SuperAdmin|Admin'])->prefix('admin')->group(function () {
        Route::apiResource('users', AdminUserController::class);
    });
});
