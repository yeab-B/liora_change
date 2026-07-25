<?php

use App\Exceptions\Api\BusinessRuleException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->alias([
            'role' => \Spatie\Permission\Middleware\RoleMiddleware::class,
            'permission' => \Spatie\Permission\Middleware\PermissionMiddleware::class,
            'role_or_permission' => \Spatie\Permission\Middleware\RoleOrPermissionMiddleware::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );

        /*
         * Standard API error envelope: { message, code, [errors] }
         * (docs/mvp/05-api-contract.md §0.3, docs/mvp/issues/09-testing-qa.md
         * Part 1 — every /api/* response follows this shape regardless of
         * which controller/exception produced it).
         *
         * Order matters here. Laravel's exception handler runs
         * prepareException() before any of these callbacks, which silently
         * converts a couple of types:
         *   - Illuminate\Database\Eloquent\ModelNotFoundException
         *     -> Symfony NotFoundHttpException
         *   - Illuminate\Auth\Access\AuthorizationException (no ->withStatus())
         *     -> Symfony AccessDeniedHttpException
         * so we register renderers for the *converted* Symfony types to
         * actually catch those cases, not the original Illuminate ones.
         *
         * The generic Throwable catch-all at the bottom MUST stay last:
         * Laravel invokes matching renderers in registration order, and a
         * Throwable-typed callback also matches every exception above it,
         * so registering it first would short-circuit all the specific ones.
         */
        $exceptions->render(function (ValidationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'message' => 'The given data was invalid.',
                    'code' => 'VALIDATION_ERROR',
                    'errors' => $e->errors(),
                ], 422);
            }
        });

        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'message' => 'Unauthenticated.',
                    'code' => 'UNAUTHENTICATED',
                ], 401);
            }
        });

        $exceptions->render(function (AccessDeniedHttpException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'message' => 'This action is unauthorized.',
                    'code' => 'FORBIDDEN',
                ], 403);
            }
        });

        $exceptions->render(function (NotFoundHttpException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'message' => 'Resource not found.',
                    'code' => 'NOT_FOUND',
                ], 404);
            }
        });

        $exceptions->render(function (BusinessRuleException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'message' => $e->getMessage(),
                    'code' => $e->code,
                ], $e->status);
            }
        });

        // Catch-all: never leak an exception message or stack trace in the
        // JSON body for api/* routes, no matter what went wrong or whether
        // APP_DEBUG is on (web/Filament routes are untouched by this and
        // still get Laravel's normal debug page when APP_DEBUG=true).
        $exceptions->render(function (\Throwable $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'message' => 'Something went wrong.',
                    'code' => 'SERVER_ERROR',
                ], 500);
            }
        });
    })->create();
