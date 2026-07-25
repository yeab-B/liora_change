# Issue #5 — Dashboard & Recovery API

| Field | Value |
|-------|-------|
| **Dev** | B |
| **Branch** | `backend/b2-dashboard-recovery` |
| **Base** | `main` |
| **Priority** | P0 — Mobile Home screen renders entirely from `GET /dashboard`; Recovery is the product's key differentiator |
| **Depends on** | #2 Challenges API, #4 Check-ins API |
| **Estimated time** | 3–4 hours |

---

## Business context

Mobile's Home screen must render from **one API call**. Recovery is the "trackers punish failure, we help you recover" moment of the demo — it must feel warm, not shaming.

## Scope

**In:** `GET /dashboard` (single aggregate payload), `GET /recovery/current`, optional `GET /progress`  
**Out:** calendar heatmap, statistics breakdowns (nice-to-have only, not required)

## No new tables required

This issue is pure aggregation logic over `users`, `challenges`, and `check_ins` (from Issues #2 and #4). If those aren't merged into `main` yet, branch from `main` anyway and stub the relations locally so you can develop in parallel — rebase once they land.

## Routes

```php
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'show']);
    Route::get('/recovery/current', [RecoveryController::class, 'current']);
    Route::get('/progress', [ProgressController::class, 'show']); // nice-to-have
});
```

## Endpoint specs

### `GET /api/v1/dashboard` (auth)

**Response `200`** — must match this shape exactly:

```json
{
  "data": {
    "user": {
      "name": "Alex Demo", "xp_total": 40, "level": 1,
      "current_streak": 0, "longest_streak": 3
    },
    "today": {
      "date": "2026-07-26",
      "active_challenges_count": 1,
      "completed_checkins_count": 0,
      "pending_checkins_count": 1
    },
    "active_challenges": [
      {
        "id": 1, "title": "Morning Walk", "status": "active",
        "progress_percent": 28.57, "current_streak": 0, "checked_in_today": false
      }
    ],
    "recovery": {
      "active": true,
      "challenge_id": 1,
      "title": "Missed day — restart small",
      "message": "One missed walk does not erase your progress. Try a 5-minute walk today."
    },
    "motivation_preview": null
  }
}
```

If recovery is not active, `"recovery": { "active": false }`.

`motivation_preview` stays `null` for now — Issue #7 (AI Motivation) may populate it later; do not block on that.

### `GET /api/v1/recovery/current` (auth)

**Business rule (implement exactly):**

```text
active = true if:
  the user has an active challenge AND
  the latest check-in for that challenge has status in (skipped, missed) AND
  that check-in's date is within the last 3 days AND
  no completed check-in exists after it
else active = false
```

If multiple active challenges qualify, pick the **most recent** skipped/missed check-in across all of them.

**Response when active (`200`)**

```json
{
  "data": {
    "active": true,
    "challenge_id": 1,
    "challenge_title": "Morning Walk",
    "reason": "skipped",
    "title": "Let's restart gently",
    "message": "You skipped yesterday. Today, do the smallest version: 5 minutes.",
    "suggested_action": { "type": "check_in", "challenge_id": 1, "label": "Check in now" }
  }
}
```

**Response when inactive (`200`)**

```json
{ "data": { "active": false } }
```

Messages can be **static templates** keyed by `reason` (no AI call required — Issue #7 may later enrich this, but it must work standalone).

### `GET /api/v1/progress` (auth) — nice-to-have

```json
{
  "data": {
    "xp_total": 40, "level": 1, "current_streak": 0, "longest_streak": 3,
    "success_rate": 75.0, "completed_checkins": 3, "skipped_checkins": 1,
    "active_challenges": 1, "completed_challenges": 0
  }
}
```

Use `app/Services/ProgressService.php::calculateSuccessRate()` (already implemented — reuse it, don't reimplement).

## Testing requirements (MUST)

`tests/Feature/Api/V1/DashboardApiTest.php` + `RecoveryApiTest.php`:

- [ ] Dashboard with no challenges → empty `active_challenges: []`, `recovery.active: false`, no errors
- [ ] Dashboard with one active challenge and no check-in today → `pending_checkins_count: 1`
- [ ] Dashboard after completing today's check-in → `checked_in_today: true` on that challenge, `pending_checkins_count: 0`
- [ ] Recovery inactive when everything is on track (no skips)
- [ ] Recovery active immediately after a `skipped` check-in (within 3 days, no completed check-in after it)
- [ ] Recovery becomes inactive again after the user completes a new check-in
- [ ] Recovery ignores skips older than 3 days (`active: false`)
- [ ] All 3 routes require auth (`401` without token)

## Definition of Done

- [ ] `GET /dashboard` alone can fully power Mobile Home (verify against Mobile team guide's binding table)
- [ ] Recovery logic matches the rule exactly, including the 3-day window
- [ ] Reused `ProgressService` for percentages/success rate (no duplicate math)
- [ ] Tests green: `php artisan test --filter=DashboardApiTest` and `RecoveryApiTest`
- [ ] PR opened against `main`, linked to Issue #5

---

## 🤖 AI Development Prompt

Paste this into your AI coding agent on branch `backend/b2-dashboard-recovery`:

```text
You are implementing Issue #5 "Dashboard & Recovery API" for the Liora Change Laravel 12 backend.

Context to read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (sections 3.7 Dashboard, 3.8 TodaySummary, 3.9 Recovery,
  3.10 SuggestedAction, 3.11 Progress)
- docs/mvp/teams/BACKEND-TEAM-GUIDE.md sections 7.4, 7.5
- docs/mvp/issues/05-dashboard-recovery-api.md (this issue's full spec, including the exact
  recovery activation rule)
- app/Services/ProgressService.php (reuse calculateProgressPercentage and calculateSuccessRate,
  do not reimplement this math elsewhere)
- app/Models/Challenge.php and app/Models/CheckIn.php (from Issues #2 and #4 — if not yet on main,
  create minimal local stand-ins so this branch can be developed independently, then reconcile via
  rebase once those issues merge)

Build the following:

1. app/Http/Controllers/Api/V1/DashboardController.php with a show() action that aggregates, in a
   SINGLE response, exactly the JSON shape shown in the issue's "GET /api/v1/dashboard" section:
   - user: name, xp_total, level, current_streak, longest_streak (from the authenticated user)
   - today: date (in user's timezone), active_challenges_count, completed_checkins_count,
     pending_checkins_count (= active_challenges_count - completed_checkins_count, never negative)
   - active_challenges: slim array of the user's active challenges with id, title, status,
     progress_percent, current_streak, checked_in_today
   - recovery: delegate to the same logic used by RecoveryController (extract a shared
     app/Services/RecoveryService.php so DashboardController and RecoveryController don't
     duplicate the rule)
   - motivation_preview: always null for now (Issue #7 may populate this later independently)

2. app/Services/RecoveryService.php implementing EXACTLY the business rule in the issue's
   "GET /api/v1/recovery/current" section:
   - Find the user's active challenges.
   - For each, find the latest check-in by check_in_date.
   - If that latest check-in has status in [skipped, missed], its date is within the last 3
     calendar days (relative to today in the user's timezone), and there is no completed
     check-in with a later date for that challenge, recovery is active for that challenge.
   - If multiple challenges qualify, choose the one with the most recent qualifying check-in.
   - Return a plain array/DTO with: active, challenge_id, challenge_title, reason, title, message,
     suggested_action — using static template strings keyed by reason (e.g. "skipped" ->
     "Let's restart gently" / "You skipped {date}. Today, do the smallest version: 5 minutes." —
     personalize the challenge title into the message). If nothing qualifies, return
     { active: false } only.

3. app/Http/Controllers/Api/V1/RecoveryController.php with a current() action that calls
   RecoveryService and returns { "data": {...} } wrapped in the exact shape from the issue file.

4. app/Http/Controllers/Api/V1/ProgressController.php (nice-to-have) with a show() action
   returning the Progress shape from the issue file, using ProgressService for the calculations.

5. Wire GET /api/v1/dashboard, GET /api/v1/recovery/current, and GET /api/v1/progress inside the
   auth:sanctum v1 group in routes/api.php (merge with existing routes, do not remove others').

6. Write tests/Feature/Api/V1/DashboardApiTest.php and tests/Feature/Api/V1/RecoveryApiTest.php
   covering every case in the issue's "Testing requirements" section. You will need to create
   Challenge and CheckIn fixtures directly (factories or model creation) with specific
   check_in_date values (e.g. Carbon::yesterday(), Carbon::now()->subDays(5)) to test the 3-day
   recovery window precisely.

7. Run `php artisan test --filter=DashboardApiTest` and `php artisan test --filter=RecoveryApiTest`
   until fully green, then the full `php artisan test` suite.

8. Manually verify with curl: GET /dashboard on a fresh user (should show empty state without
   errors), then after creating+activating a challenge and skipping a check-in, GET
   /recovery/current should show active:true. Paste the curl session in your summary.

Do not rename any JSON field from SHARED-DATA-CONTRACT.md. When finished, list every file created
or modified and confirm all tests pass.
```
