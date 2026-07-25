# Issue #1 — Auth API (register / login / logout / me)

| Field | Value |
|-------|-------|
| **Dev** | A |
| **Branch** | `backend/a1-auth-api` |
| **Base** | `main` |
| **Priority** | P0 — blocks everything else (Mobile needs a token first) |
| **Depends on** | None |
| **Estimated time** | 3–4 hours |

---

## Business context

Every screen in the mobile app requires a logged-in user with a Sanctum token. Without this, no other team (Mobile, or Dev B/C's endpoints) can be tested end-to-end. This is the **first thing that must work**.

## Scope

**In:** register, login, logout, get profile (`/me`), update profile (`PATCH /me`)  
**Out:** forgot password, email verification, social login (not needed for hackathon)

## Database

Extend the existing `users` migration (or add a new migration) with these columns:

| Column | Type | Default |
|--------|------|---------|
| timezone | varchar(64) nullable | `UTC` |
| xp_total | integer | 0 |
| level | integer | 1 |
| current_streak | integer | 0 |
| longest_streak | integer | 0 |

Ensure Sanctum is installed and `personal_access_tokens` migration exists (`php artisan install:api` or `sanctum:install` if not already run — check `config/sanctum.php` exists first).

## Routes to add (`routes/api.php`)

```php
Route::prefix('v1')->group(function () {
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/me', [MeController::class, 'show']);
        Route::patch('/me', [MeController::class, 'update']);
    });
});
```

## Endpoint specs

### `POST /api/v1/auth/register` (public)

**Request**

```json
{
  "name": "Alex Demo",
  "email": "alex@example.com",
  "password": "password",
  "password_confirmation": "password",
  "timezone": "Africa/Addis_Ababa"
}
```

**Validation:** `name` required|string|max:255 · `email` required|email|unique:users,email · `password` required|min:8|confirmed · `timezone` nullable|string|max:64

**Response `201`**

```json
{
  "data": {
    "user": {
      "id": 1, "name": "Alex Demo", "email": "alex@example.com",
      "timezone": "Africa/Addis_Ababa", "xp_total": 0, "level": 1,
      "current_streak": 0, "longest_streak": 0
    },
    "token": "1|xxxxxxxxxxxxxxxxxxxx"
  }
}
```

### `POST /api/v1/auth/login` (public)

**Request:** `{ "email": "...", "password": "...", "device_name": "flutter_android" }`  
**Response `200`:** same shape as register `data` (new token each login)  
**Invalid credentials → `422`:**
```json
{ "message": "These credentials do not match our records.", "code": "INVALID_CREDENTIALS", "errors": { "email": ["These credentials do not match our records."] } }
```

### `POST /api/v1/auth/logout` (auth)

Revoke current access token. **Response `200`:** `{ "message": "Logged out" }`

### `GET /api/v1/me` (auth)

**Response `200`:** `{ "data": { ...user fields as above } }`

### `PATCH /api/v1/me` (auth)

**Request:** `{ "name": "Alex", "timezone": "Africa/Addis_Ababa" }` (both optional)  
**Response `200`:** updated user object

## Required files

```text
app/Http/Controllers/Api/V1/AuthController.php
app/Http/Controllers/Api/V1/MeController.php
app/Http/Requests/Api/V1/RegisterRequest.php
app/Http/Requests/Api/V1/LoginRequest.php
app/Http/Requests/Api/V1/UpdateMeRequest.php
app/Http/Resources/Api/V1/UserResource.php
app/Http/Resources/Api/V1/AuthSessionResource.php   (optional wrapper)
database/migrations/xxxx_add_profile_fields_to_users_table.php
```

`UserResource` must output **exactly**: `id, name, email, timezone, xp_total, level, current_streak, longest_streak` (snake_case, no extras like `created_at` unless SHARED contract is updated first).

## Testing requirements (MUST — no exceptions)

Add `tests/Feature/Api/V1/AuthApiTest.php` covering:

- [ ] Register with valid data → `201` + token present + correct user shape
- [ ] Register with duplicate email → `422` with `errors.email`
- [ ] Register with mismatched password confirmation → `422`
- [ ] Login with correct credentials → `200` + token
- [ ] Login with wrong password → `422`
- [ ] `GET /me` without token → `401`
- [ ] `GET /me` with valid token → `200` + correct fields
- [ ] `PATCH /me` updates name/timezone and persists to DB
- [ ] `POST /auth/logout` revokes token; using the same token again on `/me` → `401`

Manual verification (paste into PR description):

```bash
curl -s -X POST http://localhost:8000/api/v1/auth/register -H 'Accept: application/json' -H 'Content-Type: application/json' \
  -d '{"name":"Alex","email":"alex@example.com","password":"password","password_confirmation":"password","timezone":"UTC"}'
```

## Definition of Done

- [ ] All 5 endpoints implemented and match SHARED-DATA-CONTRACT exactly
- [ ] Migration adds profile columns with correct defaults
- [ ] `php artisan test --filter=AuthApiTest` green
- [ ] Error envelope matches standard shape for all failure cases
- [ ] No route/controller name collisions with other devs (`Api/V1` namespace)
- [ ] PR opened against `main`, linked to Issue #1

---

## 🤖 AI Development Prompt

Paste this into your AI coding agent (Cursor) on branch `backend/a1-auth-api`:

```text
You are implementing Issue #1 "Auth API" for the Liora Change Laravel 12 backend.

Context to read first (in this repo):
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (exact JSON field names/enums — treat as law)
- docs/mvp/teams/BACKEND-TEAM-GUIDE.md sections 1-3, 6, 8
- docs/mvp/05-api-contract.md section 1 (Auth)
- app/Models/User.php (existing model)
- routes/api.php (currently minimal)

Build the following, using Laravel 12 + Sanctum conventions already in this codebase:

1. Migration: add nullable `timezone` (varchar 64, default 'UTC'), `xp_total` (int default 0),
   `level` (int default 1), `current_streak` (int default 0), `longest_streak` (int default 0)
   to the `users` table. Use `php artisan make:migration add_profile_fields_to_users_table`.

2. Ensure Laravel Sanctum is installed and configured for API token auth (check composer.json
   already has laravel/sanctum — verify config/sanctum.php and the `HasApiTokens` trait is used
   on App\Models\User; add if missing).

3. Form Requests in app/Http/Requests/Api/V1/: RegisterRequest, LoginRequest, UpdateMeRequest
   with validation rules exactly as specified in docs/mvp/issues/01-auth-api.md.

4. app/Http/Resources/Api/V1/UserResource.php — output ONLY:
   id, name, email, timezone, xp_total, level, current_streak, longest_streak (snake_case).

5. app/Http/Controllers/Api/V1/AuthController.php with register(), login(), logout() actions.
   - register(): create user (hash password), issue Sanctum token via
     $user->createToken($request->device_name ?? 'api'), return
     { "data": { "user": UserResource, "token": "<plain text token>" } } with 201.
   - login(): use Auth::attempt or manual Hash::check; on failure return 422 with
     { "message": "...", "code": "INVALID_CREDENTIALS", "errors": {"email": [...]:} }.
     On success, issue a NEW token and return same shape as register with 200.
   - logout(): $request->user()->currentAccessToken()->delete(); return
     { "message": "Logged out" } with 200.

6. app/Http/Controllers/Api/V1/MeController.php with show() and update() actions returning
   { "data": UserResource } wrapped responses.

7. Wire routes in routes/api.php exactly as shown in the issue file (prefix v1, public routes
   for register/login, auth:sanctum group for logout/me).

8. Configure the API exception handler (bootstrap/app.php withExceptions, or
   app/Exceptions/Handler.php if present) so that:
   - ValidationException on API routes renders as
     { "message": "The given data was invalid.", "code": "VALIDATION_ERROR", "errors": {...} }
     with status 422.
   - AuthenticationException on API routes renders as
     { "message": "Unauthenticated.", "code": "UNAUTHENTICATED" } with status 401.
   Only apply this custom rendering for requests under /api/*, do not break web routes.

9. Write tests/Feature/Api/V1/AuthApiTest.php covering every case listed in the "Testing
   requirements" section of docs/mvp/issues/01-auth-api.md. Use Laravel's RefreshDatabase trait
   and the existing PHPUnit setup in this repo (see tests/Feature/AuthTest.php for existing
   conventions to stay consistent, but do not modify that file).

10. Run `php artisan test --filter=AuthApiTest` and fix any failures until fully green.
    Also run the full suite `php artisan test` to confirm you did not break existing tests
    (tests/Feature/AuthTest.php, ProfileTest.php, PreferencesTest.php, UserManagementTest.php).

11. Manually verify with curl (register → login → GET /me with token → PATCH /me → logout →
    GET /me again must now return 401) and paste the curl session output in your final summary.

Do not change field names from SHARED-DATA-CONTRACT.md. Do not add extra top-level response keys.
When finished, summarize exactly which files you created/changed and confirm all tests pass.
```
