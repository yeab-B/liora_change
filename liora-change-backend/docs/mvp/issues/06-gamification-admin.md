# Issue #6 — Gamification Extras & Filament Admin Polish

| Field | Value |
|-------|-------|
| **Dev** | B |
| **Branch** | `backend/b3-gamification-admin` |
| **Base** | `main` |
| **Priority** | P1 — nice-to-have that strengthens the demo, not blocking the core loop |
| **Depends on** | #4 Check-ins API (xp_ledgers table), #3 Categories & Templates (Filament pattern reuse) |
| **Estimated time** | 3–4 hours |

---

## Business context

These endpoints add depth to the gamification story (XP history, badges) and make sure the **Users** view in Filament is genuinely useful for judges/admins to inspect what mobile users are doing during the demo.

## Scope

**In:** `GET /xp/history`, `GET /badges/unlocked`, `POST /rewards/daily/claim`, badge auto-unlock on check-in, Filament `UserResource` polish  
**Out:** full reward shop, complex badge rule engine

## Database

### `badges`

| Column | Type |
|--------|------|
| id | bigint PK |
| code | varchar(64) unique |
| name | varchar(255) |
| description | text nullable |

### `user_badges`

| Column | Type |
|--------|------|
| id | bigint PK |
| user_id | FK → users |
| badge_id | FK → badges |
| unlocked_at | timestamp |

Unique constraint on `(user_id, badge_id)` — a badge can only be unlocked once per user.

## Models

```text
app/Models/Badge.php        — hasMany UserBadge
app/Models/UserBadge.php    — belongsTo User, belongsTo Badge
```

## Routes

```php
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::get('/xp/history', [XpController::class, 'history']);
    Route::get('/badges/unlocked', [BadgeController::class, 'unlocked']);
    Route::post('/rewards/daily/claim', [RewardController::class, 'claimDaily']);
});
```

## Endpoint specs

### `GET /api/v1/xp/history`

**Response `200`**

```json
{
  "data": [
    { "id": 1, "amount": 10, "reason": "check_in_completed", "challenge_id": 1, "created_at": "2026-07-25T08:01:00Z" }
  ]
}
```

Reads from the `xp_ledgers` table created in Issue #4 — newest first.

### `GET /api/v1/badges/unlocked`

**Response `200`**

```json
{
  "data": [
    { "id": 1, "code": "first_checkin", "name": "First Step", "description": "Completed your first check-in", "unlocked_at": "2026-07-25T08:01:00Z" }
  ]
}
```

### `POST /api/v1/rewards/daily/claim`

Simple: award a fixed +5 XP once per user per calendar day (track via a `daily_reward_claims` table with `(user_id, claim_date)` unique, or reuse `xp_ledgers` with `reason=daily_reward` and check "already claimed today" by querying it — pick whichever is less code).

**Response `200`**

```json
{ "data": { "claimed": true, "xp_earned": 5, "xp_total": 45 } }
```

If already claimed today: `422` `{ "message": "Daily reward already claimed", "code": "ALREADY_CLAIMED" }`

## Badge auto-unlock (hook into Issue #4's check-in flow)

Add a small `app/Services/BadgeService.php` (already scaffolded in the repo at `app/Services/BadgeService.php` — check it and extend, don't duplicate) that is called **after** a completed check-in is saved:

| Badge code | Unlock condition |
|------------|-------------------|
| `first_checkin` | User's first-ever `completed` check-in |
| `streak_3` | Any challenge reaches `current_streak == 3` |
| `comeback` | First `completed` check-in that immediately follows a `skipped`/`missed` one (i.e. recovery worked) |

Wire this as a call from `CheckInController::store()` (Issue #4) — if Issue #4 is already merged, add the call there; if not yet merged, add a `TODO` comment and coordinate with Dev B's own Issue #4 (same developer) to wire it during that branch's review, or add it here behind a check for table existence.

## Filament — Users polish

Improve `app/Filament/Resources/UserResource.php` table/columns to show, at minimum: `name`, `email`, `xp_total`, `level`, `current_streak`, `longest_streak`, `created_at`. Add a simple filter for "has active challenge" if time allows (nice-to-have, skip if tight on time).

Seed badges in `database/seeders/DemoSeeder.php` (reuse the same seeder Dev A is using in Issue #3 — coordinate to avoid overwriting each other's seed sections; use clearly separated methods like `seedBadges()`).

## Testing requirements (MUST)

`tests/Feature/Api/V1/GamificationApiTest.php`:

- [ ] `GET /xp/history` returns ledger entries newest-first for the authenticated user only
- [ ] `GET /badges/unlocked` returns only the authenticated user's unlocked badges
- [ ] Completing a user's first check-in unlocks `first_checkin` (assert via `user_badges` table)
- [ ] Reaching streak of 3 unlocks `streak_3`
- [ ] A completed check-in right after a skipped one unlocks `comeback`
- [ ] `POST /rewards/daily/claim` succeeds once, then returns `422 ALREADY_CLAIMED` on a second call same day
- [ ] All routes require auth

## Definition of Done

- [ ] Migrations for `badges`, `user_badges` run cleanly
- [ ] All 3 endpoints match SHARED-DATA-CONTRACT shapes
- [ ] Badge auto-unlock wired into the check-in flow (or clearly TODO'd with a follow-up note if #4 isn't merged yet)
- [ ] Filament UserResource shows gamification fields
- [ ] Tests green: `php artisan test --filter=GamificationApiTest`
- [ ] PR opened against `main`, linked to Issue #6

---

## 🤖 AI Development Prompt

Paste this into your AI coding agent on branch `backend/b3-gamification-admin`:

```text
You are implementing Issue #6 "Gamification Extras & Filament Admin Polish" for the Liora Change
Laravel 12 backend.

Context to read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (sections 3.15/3.16 XpLedgerItem, BadgeUnlocked in the
  "Gamification" area — match field names exactly)
- docs/mvp/teams/BACKEND-TEAM-GUIDE.md section 10 (seed content, badges)
- docs/mvp/issues/06-gamification-admin.md (this issue's full spec)
- app/Services/BadgeService.php, app/Services/RewardService.php, app/Services/XPService.php,
  app/Services/LevelService.php (existing scaffolds in this repo — inspect them first and extend/
  reuse rather than writing duplicate logic)
- app/Filament/Resources/UserResource.php (existing, polish the table columns)
- app/Models/XpLedger.php (from Issue #4 — if not yet on main, create a minimal compatible
  version so this branch works standalone, then reconcile by rebase)

Build the following:

1. Migration `create_badges_table`: id, code (varchar 64, unique), name (varchar 255),
   description (text nullable).

2. Migration `create_user_badges_table`: id, user_id (FK users), badge_id (FK badges),
   unlocked_at (timestamp), with a UNIQUE constraint on (user_id, badge_id).

3. app/Models/Badge.php and app/Models/UserBadge.php with correct relationships.

4. Extend app/Services/BadgeService.php with a method like
   evaluateAndUnlock(User $user, Challenge $challenge, CheckIn $checkIn) implementing the 3 badge
   rules exactly as described in the issue's "Badge auto-unlock" section (first_checkin, streak_3,
   comeback). Use firstOrCreate-style logic on user_badges to avoid duplicate unlocks (respect the
   unique constraint).

5. app/Http/Controllers/Api/V1/XpController.php with history() returning the exact JSON shape
   from the issue file's "GET /api/v1/xp/history" section, reading from the xp_ledgers table,
   scoped to the authenticated user, newest first.

6. app/Http/Controllers/Api/V1/BadgeController.php with unlocked() returning the exact shape from
   "GET /api/v1/badges/unlocked", scoped to the authenticated user.

7. A small daily-reward mechanism: either a new migration for `daily_reward_claims`
   (user_id, claim_date, unique on both) or reuse xp_ledgers with reason='daily_reward' — choose
   whichever is simpler given what already exists, and implement
   app/Http/Controllers/Api/V1/RewardController.php::claimDaily() matching the issue's exact
   request/response/error behavior (422 ALREADY_CLAIMED on double-claim same day).

8. Wire all three routes (GET /xp/history, GET /badges/unlocked, POST /rewards/daily/claim)
   inside the auth:sanctum v1 group in routes/api.php.

9. If app/Http/Controllers/Api/V1/CheckInController.php already exists on main (from Issue #4),
   add a call to BadgeService::evaluateAndUnlock() right after a completed check-in is persisted.
   If it does not exist yet on this branch, add a clear `// TODO(Issue #4 integration):` comment
   at the top of BadgeService noting where it must be wired once check-ins land, and write your
   tests by calling BadgeService directly with manually constructed User/Challenge/CheckIn models
   so your test suite doesn't hard-depend on Issue #4's controller.

10. Polish app/Filament/Resources/UserResource.php table() to show columns: name, email, xp_total,
    level, current_streak, longest_streak, created_at.

11. Add a seedBadges() method to database/seeders/DemoSeeder.php (create the seeder if it does not
    exist; if it already exists from Issue #3, add your method alongside without removing theirs)
    seeding badges: first_checkin ("First Step"), streak_3 ("On a Roll"), comeback
    ("The Comeback") with sensible descriptions. Call it from DatabaseSeeder.php.

12. Write tests/Feature/Api/V1/GamificationApiTest.php covering every case in the issue's "Testing
    requirements" section.

13. Run `php artisan test --filter=GamificationApiTest` until green, then the full
    `php artisan test` suite.

14. Manually verify with curl: GET /xp/history and GET /badges/unlocked for a user who has
    completed check-ins (seed or create fixtures as needed), and POST /rewards/daily/claim twice
    in a row to confirm the second call returns 422. Paste the curl session in your summary.

Do not rename any JSON field from SHARED-DATA-CONTRACT.md. When finished, list every file created
or modified and confirm all tests pass.
```
