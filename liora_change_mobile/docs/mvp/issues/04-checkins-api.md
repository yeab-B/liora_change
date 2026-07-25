# Issue #4 — Check-ins API (XP + Streak logic)

| Field | Value |
|-------|-------|
| **Dev** | B |
| **Branch** | `backend/b1-checkins-api` |
| **Base** | `main` |
| **Priority** | P0 — this is the heart of the demo loop (complete/skip → streak/XP/recovery) |
| **Depends on** | #2 Challenges API (needs `challenges` table + `Challenge` model) |
| **Estimated time** | 5–6 hours |

---

## Business context

This is **the differentiator**: completing a check-in builds streak + XP; skipping resets the streak but flags **recovery** instead of just punishing the user. Get this exactly right — Dashboard (#5) and Mobile depend entirely on the numbers this issue produces.

## Scope

**In:** create check-in (complete/skip), list check-ins for a challenge, XP award, streak calculation, one-check-in-per-day enforcement  
**Out:** auto-generating `missed` check-ins via scheduler (not needed for hackathon demo)

## Database

### `check_ins` (new migration)

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| id | bigint PK | | |
| user_id | FK → users | | |
| challenge_id | FK → challenges, cascade on delete | | |
| check_in_date | date | | |
| status | varchar(16) | | `completed` \| `skipped` \| `missed` |
| note | text nullable | | |
| mood | tinyint nullable | | 1–5 |
| energy | tinyint nullable | | 1–5 |
| xp_earned | integer | 0 | |
| created_at / updated_at | timestamps | | |

**UNIQUE constraint:** `(challenge_id, check_in_date)` — critical, this is what makes "one check-in per day" enforceable at the DB level, not just app logic.

### `xp_ledgers` (new migration)

| Column | Type |
|--------|------|
| id | bigint PK |
| user_id | FK → users |
| challenge_id | FK → challenges, nullable |
| amount | integer |
| reason | varchar(64) — `check_in_completed`, `streak_bonus` |
| created_at | timestamp |

## Model

```text
app/Models/CheckIn.php   — belongsTo Challenge, belongsTo User
app/Models/XpLedger.php  — belongsTo User, belongsTo Challenge (nullable)
```

## Routes

```php
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::post('/challenges/{challenge}/check-ins', [CheckInController::class, 'store']);
    Route::get('/challenges/{challenge}/check-ins', [CheckInController::class, 'index']);
});
```

Owner-only via the existing `ChallengePolicy` (reuse it from Issue #2 — don't fork a separate policy).

## Endpoint specs

### `POST /api/v1/challenges/{id}/check-ins` (auth, owner only)

**Request**

```json
{ "status": "completed", "note": "Felt great", "mood": 4, "energy": 3, "check_in_date": "2026-07-25" }
```

**Validation:** `status` required|in:completed,skipped · `note` nullable|string|max:1000 · `mood` nullable|integer|min:1|max:5 · `energy` nullable|integer|min:1|max:5 · `check_in_date` nullable|date (default: **today in the user's timezone**, use `$user->timezone ?? 'UTC'`)

**Business rules (implement exactly):**

1. Challenge must be `status = active` — otherwise `422` `{ "message": "Challenge is not active", "code": "CHALLENGE_NOT_ACTIVE" }`
2. Enforce one check-in per `(challenge_id, check_in_date)` — if it already exists, either update it (upsert) or return `422` `{ "message": "Already checked in for this date", "code": "DUPLICATE_CHECK_IN" }`. **Pick upsert** for a smoother demo (simpler for Mobile to retry).
3. **On `completed`:**
   - `xp_earned = 10`
   - increment challenge's `current_streak` by 1 (use `app/Services/StreakService.php::incrementStreak`), update `longest_streak` if exceeded
   - `user.xp_total += 10`; recompute `user.level = floor(xp_total / 100) + 1`
   - insert `xp_ledgers` row with `reason: check_in_completed`
   - `recovery_available = false`
4. **On `skipped`:**
   - `xp_earned = 0`
   - reset challenge's `current_streak` to `0` (use `StreakService::breakStreak`), `longest_streak` unchanged
   - `recovery_available = true`
5. Response must include a `summary` block with the numbers **after** this action is applied (see shape below) so Mobile can update the UI without a second request.

**Response `201`**

```json
{
  "data": {
    "check_in": {
      "id": 10, "challenge_id": 1, "check_in_date": "2026-07-25", "status": "completed",
      "note": "Felt great", "mood": 4, "energy": 3, "xp_earned": 10, "streak_after": 1,
      "created_at": "2026-07-25T08:01:00Z"
    },
    "summary": {
      "current_streak": 1, "longest_streak": 1, "xp_total": 10, "xp_earned": 10,
      "challenge_progress_percent": 14.29, "recovery_available": false
    }
  }
}
```

### `GET /api/v1/challenges/{id}/check-ins` (auth, owner only)

**Response `200`:** `{ "data": [ CheckIn, CheckIn, ... ] }` ordered by `check_in_date desc`

## Testing requirements (MUST)

`tests/Feature/Api/V1/CheckInApiTest.php`:

- [ ] Complete check-in on an active challenge → `201`, streak becomes 1, `xp_earned = 10`, user's `xp_total` increased by 10
- [ ] Two completed check-ins on consecutive days → streak = 2
- [ ] Skip check-in → streak resets to 0, `recovery_available = true` in summary
- [ ] Check-in on a `draft` (non-active) challenge → `422` `CHALLENGE_NOT_ACTIVE`
- [ ] Second check-in same challenge + same date → either updates cleanly or returns the documented `422` (pick one behavior and assert it consistently)
- [ ] `GET check-ins` for a challenge returns only that challenge's check-ins, newest first
- [ ] Check-in on another user's challenge → `403`/`404`
- [ ] Invalid `status` value (e.g. `"missed"` sent by client) → `422`

## Definition of Done

- [ ] Both migrations run cleanly with the unique constraint in place
- [ ] Check-in response matches SHARED-DATA-CONTRACT `CheckInResult` shape exactly
- [ ] XP/streak math is correct and covered by tests
- [ ] `StreakService` and `XPService` reused (extended if needed, not duplicated)
- [ ] Tests green: `php artisan test --filter=CheckInApiTest`
- [ ] PR opened against `main`, linked to Issue #4

---

## 🤖 AI Development Prompt

Paste this into your AI coding agent on branch `backend/b1-checkins-api`:

```text
You are implementing Issue #4 "Check-ins API" for the Liora Change Laravel 12 backend.

Context to read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (sections 3.4 CheckIn, 3.5 CheckInResult, 3.6 CheckInSummary,
  and section 5 "Business numbers" — these numbers are law)
- docs/mvp/teams/BACKEND-TEAM-GUIDE.md sections 3.3, 3.4, 4 (CheckInResource), 7.2, 7.3
- docs/mvp/issues/04-checkins-api.md (this issue's full spec)
- app/Services/StreakService.php, app/Services/XPService.php, app/Services/ProgressService.php
  (existing services — reuse and extend them, do not duplicate their logic elsewhere)
- app/Models/Challenge.php (created in Issue #2 — if not yet merged into main, create a minimal
  compatible version so this branch is self-contained, but prefer rebasing on main once #2 lands)
- app/Policies/ChallengePolicy.php (reuse for authorization, do not create a separate policy)

Build the following:

1. Migration `create_check_ins_table` with exactly the columns in the issue's "Database" section,
   including the UNIQUE constraint on (challenge_id, check_in_date). This constraint is critical —
   do not skip it.

2. Migration `create_xp_ledgers_table` with exactly the columns listed.

3. app/Models/CheckIn.php (belongsTo Challenge, belongsTo User, cast check_in_date as date) and
   app/Models/XpLedger.php (belongsTo User, belongsTo Challenge nullable).

4. app/Http/Requests/Api/V1/StoreCheckInRequest.php with validation rules from the issue spec.
   Default check_in_date to "today" in the authenticated user's timezone (fallback 'UTC') when
   not provided.

5. app/Http/Controllers/Api/V1/CheckInController.php with store() and index() actions implementing
   EXACTLY the business rules in the issue's "Business rules (implement exactly)" section:
   - Reject if challenge.status != active (422 CHALLENGE_NOT_ACTIVE)
   - Upsert on (challenge_id, check_in_date) — implement as: find existing check-in for that date,
     if found update it, else create new. This keeps the demo resilient to double-taps.
   - On status=completed: xp_earned=10, increment streak via StreakService, update
     challenge.longest_streak if exceeded, increment user.xp_total by 10, recompute
     user.level = floor(xp_total/100)+1, insert xp_ledgers row (reason=check_in_completed).
   - On status=skipped: xp_earned=0, reset challenge.current_streak to 0 via StreakService,
     leave longest_streak untouched.
   - Wrap the whole mutation in a DB transaction for consistency.
   - Build the response using ProgressService for challenge_progress_percent
     (completed_checkins / duration_days * 100, rounded to 2 decimals).
   - Return the exact CheckInResult JSON shape from docs/mvp/issues/04-checkins-api.md
     ("Response 201" example), with status 201.

6. Authorize using the existing ChallengePolicy so a user can only check into their own challenges
   (403/404 otherwise).

7. Wire routes in routes/api.php inside the auth:sanctum v1 group:
   POST /challenges/{challenge}/check-ins and GET /challenges/{challenge}/check-ins
   (merge with existing routes from other devs, do not remove them).

8. Write tests/Feature/Api/V1/CheckInApiTest.php covering every case in the issue's "Testing
   requirements" section, using RefreshDatabase. You will need to create an active Challenge
   fixture in each test (factory or direct model creation) since this table depends on Issue #2.

9. Run `php artisan test --filter=CheckInApiTest` until fully green, then the full
   `php artisan test` suite to make sure nothing else broke.

10. Manually verify with curl: create+activate a challenge, then POST a completed check-in, then
    a skipped check-in on a different date, confirming streak and xp_total behave as specified.
    Paste the curl session in your summary.

Do not rename any JSON field from SHARED-DATA-CONTRACT.md. The XP/streak numbers in section 5 of
that file are exact and must match your implementation. When finished, list every file created or
modified and confirm all tests pass.
```
