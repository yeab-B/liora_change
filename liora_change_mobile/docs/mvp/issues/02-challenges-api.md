# Issue #2 — Challenges API (create / list / show / activate)

| Field | Value |
|-------|-------|
| **Dev** | A |
| **Branch** | `backend/a2-challenges-api` |
| **Base** | `main` |
| **Priority** | P0 — Check-ins (#4), Dashboard (#5), and AI Motivation (#7) all depend on this |
| **Depends on** | #1 Auth API (needs authenticated user) |
| **Estimated time** | 4–5 hours |

---

## Business context

The **Challenge** is the core object of the product: a user's structured commitment (e.g. "Morning Walk — 7 days"). This issue delivers create → activate, the first half of the demo loop. Dev B's check-ins (#4) will attach to the `challenges` created here.

## Scope

**In:** create draft, list (mine), show one, activate (draft/ready → active)  
**Out:** pause/resume/complete (nice-to-have, add only if time remains after DoD)

## Database — `challenges` table (new migration)

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| id | bigint PK | | |
| user_id | FK → users, cascade on delete | | indexed |
| category_id | FK → challenge_categories, nullable | null | table created in Issue #3 — make this column nullable with no hard FK constraint yet if #3 isn't merged; add FK constraint via a later migration if needed, or coordinate with Dev A's own issue #3 |
| title | varchar(255) | | |
| description | text nullable | | |
| status | varchar(32) | `draft` | enum values below |
| difficulty | varchar(32) | `beginner` | |
| visibility | varchar(32) | `private` | |
| start_date | date nullable | | set on activate |
| end_date | date nullable | | set on activate |
| duration_days | integer | 7 | |
| current_streak | integer | 0 | |
| longest_streak | integer | 0 | |
| created_at / updated_at | timestamps | | |

Index: `(user_id, status)`

**Enums (exact strings — see SHARED-DATA-CONTRACT):**
- `challenge_status`: `draft, ready, active, paused, completed, cancelled, archived`
- `challenge_difficulty`: `beginner, easy, medium, hard, expert`
- `challenge_visibility`: `private, public`

## Model

Create `app/Models/Challenge.php` (referenced already by `app/Filament/Resources/ChallengeResource.php` but the model file does not exist yet — create it now):

```php
class Challenge extends Model
{
    protected $fillable = ['user_id','category_id','title','description','status','difficulty','visibility','start_date','end_date','duration_days','current_streak','longest_streak'];
    protected $casts = ['start_date' => 'date', 'end_date' => 'date'];

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function checkIns(): HasMany { return $this->hasMany(CheckIn::class); } // used by Dev B in #4
}
```

## Routes

```php
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::get('/challenges', [ChallengeController::class, 'index']);
    Route::post('/challenges', [ChallengeController::class, 'store']);
    Route::get('/challenges/{challenge}', [ChallengeController::class, 'show']);
    Route::post('/challenges/{challenge}/activate', [ChallengeController::class, 'activate']);
});
```

Use route-model binding + a Policy (`ChallengePolicy` already exists at `app/Policies/ChallengePolicy.php` — reuse/extend it) so a user can only see/activate **their own** challenges (`403` otherwise).

## Endpoint specs

### `GET /api/v1/challenges` (auth)

Optional query `?status=active`. **Response `200`:** `{ "data": [ Challenge, ... ] }` — only the current user's challenges, newest first.

### `POST /api/v1/challenges` (auth)

**Request**

```json
{ "title": "Morning Walk", "description": "10 min walk", "difficulty": "beginner", "visibility": "private", "duration_days": 7, "category_id": null }
```

**Validation:** `title` required|string|max:255 · `description` nullable|string · `difficulty` nullable|in:beginner,easy,medium,hard,expert (default beginner) · `visibility` nullable|in:private,public (default private) · `duration_days` nullable|integer|min:1|max:90 (default 7) · `category_id` nullable|integer  
Accept legacy `difficulty_score` as an alias for `difficulty` (map it, don't require both).

**Response `201`:** `{ "data": { ...Challenge, "status": "draft" } }`

### `GET /api/v1/challenges/{id}` (auth, owner only)

**Response `200`:** full Challenge object (see JSON shape below)

### `POST /api/v1/challenges/{id}/activate` (auth, owner only)

**Rule:** allowed only from `draft` or `ready` → `active`. Sets `start_date = today (user timezone)`, `end_date = start_date + duration_days - 1`.  
**Response `200`:** updated Challenge, `status: "active"`  
**Invalid transition → `422`:**
```json
{ "message": "Challenge cannot be activated from completed", "code": "INVALID_STATUS_TRANSITION" }
```

Update `app/Services/ChallengeService.php::canTransition()` — the current logic only allows `Ready → Active`. **Add `Draft → Active`** to the `Draft` case for MVP:

```php
ChallengeStatus::Draft => in_array($new, [ChallengeStatus::Ready, ChallengeStatus::Active, ChallengeStatus::Archived]),
```

## Challenge JSON shape (`ChallengeResource`)

```json
{
  "id": 1, "title": "Morning Walk", "description": "10 min walk",
  "status": "active", "difficulty": "beginner", "visibility": "private",
  "category_id": null, "start_date": "2026-07-25", "end_date": "2026-07-31",
  "duration_days": 7, "progress_percent": 0, "current_streak": 0, "longest_streak": 0,
  "completed_checkins": 0, "missed_checkins": 0, "checked_in_today": false,
  "created_at": "2026-07-25T10:00:00Z", "updated_at": "2026-07-25T10:00:00Z"
}
```

`progress_percent`, `completed_checkins`, `missed_checkins`, `checked_in_today` will be `0`/`false` until Issue #4 (check-ins) is merged — compute them defensively (e.g. `$this->checkIns()->count()` returning 0 if table/relation has no rows yet is fine; guard with a `try` or simply rely on Eloquent returning empty collections, no error).

## Testing requirements (MUST)

`tests/Feature/Api/V1/ChallengeApiTest.php`:

- [ ] Create challenge → `201`, status `draft`, defaults applied correctly
- [ ] Create with missing title → `422`
- [ ] List returns only the authenticated user's challenges (create as user A and user B, assert isolation)
- [ ] Show challenge belonging to another user → `403` or `404`
- [ ] Activate a draft challenge → `200`, status `active`, `start_date`/`end_date` set
- [ ] Activate an already-completed challenge → `422` with `INVALID_STATUS_TRANSITION`
- [ ] Unauthenticated request to any route → `401`

## Definition of Done

- [ ] Migration + Model + Policy wired correctly
- [ ] All 4 endpoints match SHARED-DATA-CONTRACT exactly
- [ ] `ChallengeService::canTransition` updated for draft→active
- [ ] Tests green: `php artisan test --filter=ChallengeApiTest`
- [ ] Verified with curl: create → activate → show
- [ ] PR opened against `main`, linked to Issue #2

---

## 🤖 AI Development Prompt

Paste this into your AI coding agent on branch `backend/a2-challenges-api`:

```text
You are implementing Issue #2 "Challenges API" for the Liora Change Laravel 12 backend.

Context to read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (section 3.3 Challenge schema — exact field names/enums)
- docs/mvp/teams/BACKEND-TEAM-GUIDE.md sections 3.2, 4 (ChallengeResource), 5, 6, 7.1
- docs/mvp/issues/02-challenges-api.md (this issue's full spec)
- app/Services/ChallengeService.php (existing draft/status-transition logic — extend, don't rewrite)
- app/Shared/Enums/ChallengeStatus.php, ChallengeDifficulty.php, ChallengeVisibility.php (existing enums, reuse them)
- app/Policies/ChallengePolicy.php (existing policy, extend for owner-only access)
- app/Filament/Resources/ChallengeResource.php (already references App\Models\Challenge — this model
  does not exist yet, you must create it so Filament keeps working)

Build the following:

1. Migration `create_challenges_table` with exactly the columns listed in the "Database" section
   of docs/mvp/issues/02-challenges-api.md. Add index on (user_id, status). Make category_id
   nullable with no strict FK constraint for now (Issue #3 creates challenge_categories separately;
   coordinate by using unsignedBigInteger()->nullable() without ->constrained() to avoid migration
   order conflicts, OR add the FK only if challenge_categories migration already exists in main).

2. app/Models/Challenge.php — fillable fields, casts for start_date/end_date as date, belongsTo
   User, hasMany CheckIn (CheckIn model will be created in Issue #4 by another dev — just declare
   the relation, it's fine if the model class doesn't exist yet on this branch).

3. Update app/Services/ChallengeService.php::canTransition() to allow Draft -> Active directly
   (in addition to existing Draft -> Ready/Archived), per the MVP rule in the issue file. Do not
   remove any existing transition logic.

4. app/Http/Requests/Api/V1/StoreChallengeRequest.php (new, under Api/V1 namespace to avoid
   clashing with the existing app/Http/Requests/StoreChallengeRequest.php) with validation rules
   from the issue spec, including accepting legacy `difficulty_score` as an alias for `difficulty`.

5. app/Http/Resources/Api/V1/ChallengeResource.php outputting EXACTLY the JSON shape in the issue
   file's "Challenge JSON shape" section. Compute progress_percent using
   app/Services/ProgressService.php (reuse it: completed check-ins / duration_days * 100, rounded
   to 2 decimals). Compute completed_checkins, missed_checkins, checked_in_today defensively so
   they return 0/false if no check_ins table/rows exist yet.

6. app/Http/Controllers/Api/V1/ChallengeController.php with index(), store(), show(), activate()
   actions matching the endpoint specs in the issue file exactly, including the 422
   INVALID_STATUS_TRANSITION error shape on invalid activation.

7. Use route-model binding for {challenge} and authorize via ChallengePolicy so users can only
   view/activate their own challenges (403 for others' challenges, extend the existing policy
   rather than replacing it).

8. Wire routes in routes/api.php inside the auth:sanctum v1 group (merge with existing routes from
   Issue #1 if present on main — do not delete other routes).

9. Write tests/Feature/Api/V1/ChallengeApiTest.php covering every case in the issue's "Testing
   requirements" section, using RefreshDatabase and Sanctum::actingAs (or issuing a real token)
   for authenticated requests.

10. Run `php artisan test --filter=ChallengeApiTest` until green, then run the full `php artisan
    test` suite to confirm nothing else broke.

11. Manually verify with curl: register/login (assume Issue #1 is merged; if not yet available on
    this branch, create a test user via tinker/seeder to get a token) -> POST /challenges ->
    POST /challenges/{id}/activate -> GET /challenges/{id}. Paste the curl output in your summary.

Do not rename any JSON field from SHARED-DATA-CONTRACT.md. When finished, list every file created
or modified and confirm all tests pass.
```
