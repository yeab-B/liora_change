# Issue #3 — Challenge Categories & Templates (API + Filament)

| Field | Value |
|-------|-------|
| **Dev** | A |
| **Branch** | `backend/a3-categories-templates` |
| **Base** | `main` |
| **Priority** | P1 — improves demo (create-from-template) but not strictly blocking |
| **Depends on** | None (can run parallel to #1/#2; independent tables) |
| **Estimated time** | 2–3 hours |

---

## Business context

Admins curate **categories** (Health, Focus, Wellbeing) and **templates** (starter challenges) in Filament. Mobile reads them via API so users can create a challenge from a template instead of a blank form — this is also the "platform, not just an app" part of the demo pitch.

## Scope

**In:** read-only API for categories + templates, Filament CRUD for both, demo seed data  
**Out:** template versioning, per-user custom templates

## Database

### `challenge_categories`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| name | varchar(255) | |
| slug | varchar(255) unique | |
| timestamps | | |

### `challenge_templates`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| category_id | FK → challenge_categories, nullable | |
| title | varchar(255) | |
| description | text nullable | |
| difficulty | varchar(32) | default `beginner` |
| duration_days | integer | default 7 |
| timestamps | | |

If Issue #2's `challenges` table has already added `category_id` without a real FK constraint, add the FK constraint to `challenge_categories` here in a follow-up migration (`ALTER TABLE`) — coordinate with Dev A's own Issue #2 since you are the same developer for both.

## Models

```text
app/Models/ChallengeCategory.php
app/Models/ChallengeTemplate.php
```

Both simple Eloquent models with `$fillable`. `ChallengeTemplate belongsTo ChallengeCategory`.

## Routes

```php
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::get('/challenge-categories', [ChallengeCategoryController::class, 'index']);
    Route::get('/challenge-templates', [ChallengeTemplateController::class, 'index']);
});
```

## Endpoint specs

### `GET /api/v1/challenge-categories`

**Response `200`**

```json
{ "data": [ { "id": 1, "name": "Health", "slug": "health" }, { "id": 2, "name": "Focus", "slug": "focus" } ] }
```

### `GET /api/v1/challenge-templates`

Optional query `?category_id=1`.

**Response `200`**

```json
{
  "data": [
    { "id": 1, "title": "7-Day Morning Walk", "description": "Walk 10 minutes each morning", "difficulty": "beginner", "duration_days": 7, "category_id": 1 }
  ]
}
```

## Filament (this issue owns these resources)

Use the existing scaffolds already in the repo and make them fully functional:

- `app/Filament/Resources/ChallengeCategoryResource.php` → form: `name`, `slug` (auto-slug from name); table: name, slug, created_at
- `app/Filament/Resources/ChallengeTemplateResource.php` → form: `title`, `description` (textarea), `difficulty` (select from enum), `duration_days` (number), `category_id` (select relationship); table: title, category, difficulty, duration_days

## Seed data (add to `database/seeders/DemoSeeder.php` — create if it doesn't exist yet; coordinate with Dev B who may also add to it, keep seeders idempotent using `firstOrCreate`)

**Categories:** Health (`health`), Focus (`focus`), Wellbeing (`wellbeing`)

**Templates:**

| title | difficulty | duration_days | category |
|-------|------------|----------------|----------|
| 7-Day Morning Walk | beginner | 7 | Health |
| No Sugar Week | medium | 7 | Health |
| Night Phone Curfew | easy | 7 | Focus |

## Testing requirements (MUST)

`tests/Feature/Api/V1/CategoryTemplateApiTest.php`:

- [ ] `GET /challenge-categories` returns seeded categories with correct shape
- [ ] `GET /challenge-templates` returns seeded templates with correct shape
- [ ] `GET /challenge-templates?category_id=X` filters correctly
- [ ] Both routes require auth (`401` without token)
- [ ] Filament: creating a category via `ChallengeCategoryResource` persists correctly (a simple Livewire/Filament test or a direct model-level assertion is acceptable if full Filament browser testing is out of scope for the hackathon)

## Definition of Done

- [ ] Both migrations run cleanly
- [ ] Both API endpoints return exact SHARED-DATA-CONTRACT shapes
- [ ] Filament resources fully functional (create/edit/list) for both
- [ ] Seeder creates categories + templates idempotently
- [ ] Tests green: `php artisan test --filter=CategoryTemplateApiTest`
- [ ] PR opened against `main`, linked to Issue #3

---

## 🤖 AI Development Prompt

Paste this into your AI coding agent on branch `backend/a3-categories-templates`:

```text
You are implementing Issue #3 "Challenge Categories & Templates" for the Liora Change Laravel 12
backend.

Context to read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (sections 3.12 ChallengeCategory, 3.13 ChallengeTemplate)
- docs/mvp/teams/BACKEND-TEAM-GUIDE.md sections 3.5, 3.6, 9, 10 (Filament + seed data)
- docs/mvp/issues/03-categories-templates-api.md (this issue's full spec)
- app/Filament/Resources/ChallengeCategoryResource.php and ChallengeTemplateResource.php
  (already scaffolded by Filament generator but need real form fields and working model classes)
- app/Shared/Enums/ChallengeDifficulty.php (reuse this enum for the difficulty select)

Build the following:

1. Migration `create_challenge_categories_table`: id, name (varchar 255), slug (varchar 255,
   unique), timestamps.

2. Migration `create_challenge_templates_table`: id, category_id (nullable FK to
   challenge_categories, nullOnDelete), title (varchar 255), description (text nullable),
   difficulty (varchar 32, default 'beginner'), duration_days (integer, default 7), timestamps.

3. app/Models/ChallengeCategory.php and app/Models/ChallengeTemplate.php with correct
   $fillable arrays and the belongsTo/hasMany relationship between them.

4. Complete the Filament resource forms in ChallengeCategoryResource.php (TextInput for name,
   TextInput for slug with a simple ->afterStateUpdated slug generation from name if easy, or a
   Str::slug() default) and ChallengeTemplateResource.php (TextInput title, Textarea description,
   Select difficulty with options from ChallengeDifficulty enum cases, TextInput duration_days as
   numeric, Select category_id as a relationship select to ChallengeCategory). Also fill in the
   table() columns for both (see the issue file "Filament" section for exact column lists).

5. app/Http/Controllers/Api/V1/ChallengeCategoryController.php (index only) and
   ChallengeTemplateController.php (index only, supporting an optional ?category_id= filter),
   each returning the exact JSON shapes from the issue file's "Endpoint specs" section, wrapped
   as { "data": [...] }.

6. Wire GET /api/v1/challenge-categories and GET /api/v1/challenge-templates inside the
   auth:sanctum v1 route group in routes/api.php (merge with existing routes, do not remove
   other devs' routes).

7. Create or extend database/seeders/DemoSeeder.php using firstOrCreate() (idempotent) to seed
   exactly the categories and templates listed in the issue file's "Seed data" section. Call this
   seeder from database/seeders/DatabaseSeeder.php if not already wired.

8. Write tests/Feature/Api/V1/CategoryTemplateApiTest.php covering every case in the issue's
   "Testing requirements" section.

9. Run `php artisan migrate:fresh --seed` locally to confirm no migration errors, then
   `php artisan test --filter=CategoryTemplateApiTest` until green, then the full
   `php artisan test` suite to confirm nothing else broke.

10. Manually verify with curl (after logging in as a seeded user):
    GET /api/v1/challenge-categories
    GET /api/v1/challenge-templates
    GET /api/v1/challenge-templates?category_id=1
    Paste the curl output in your summary.

Do not rename any JSON field from SHARED-DATA-CONTRACT.md. When finished, list every file created
or modified and confirm all tests pass.
```
