# Issue #7 — AI Motivation (OpenAI + challenge context)

| Field | Value |
|-------|-------|
| **Dev** | C |
| **Branch** | `backend/c1-ai-motivation` |
| **Base** | `main` |
| **Priority** | P0 — explicitly requested AI feature for the demo |
| **Depends on** | #2 Challenges API (reads challenge fields for the prompt) |
| **Estimated time** | 3–4 hours |

---

## Business context

Judges must see AI generate **personalized** text from the user's real challenge data — not a generic quote. This endpoint also must **never crash the Home screen**: if OpenAI fails or no key is configured, fall back to a template that still mentions the challenge by name.

## Scope

**In:** `POST /ai/motivation` with OpenAI call + template fallback  
**Out:** voice, multi-language, streaming responses

## No new tables required for this issue alone

(It reads `users` + `challenges` + `check_ins`. Optional logging table `ai_generations` is nice-to-have — add only if time remains.)

## Env

Add to `.env.example` and document in README:

```env
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o-mini
```

If `OPENAI_API_KEY` is empty/missing, the service must **always** use the template path — never throw.

## Routes

```php
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::post('/ai/motivation', [MotivationController::class, 'generate']);
});
```

## Endpoint spec

### `POST /api/v1/ai/motivation` (auth)

**Request**

```json
{ "challenge_id": 1, "context": "morning" }
```

**Validation:** `challenge_id` nullable|integer|exists:challenges,id (must belong to the authenticated user if provided — if omitted, use the user's most recently active challenge; if the user has none, return a generic encouragement without a challenge reference) · `context` nullable|in:morning,recovery,general (default `general`)

**Response `200`**

```json
{
  "data": {
    "message": "Alex, your Morning Walk only needs 10 minutes today. Keep the bar tiny — step outside and begin.",
    "tone": "encouraging",
    "source": "openai",
    "challenge_id": 1,
    "challenge_title": "Morning Walk"
  }
}
```

`source` is `"openai"` when the LLM call succeeds, `"template"` on any failure/fallback/missing key. **Always return `200`** with a usable message — never `500` for a provider failure.

## Prompt construction (build from real data — this is the point of the issue)

Load and inject into the prompt:

| Signal | Source |
|--------|--------|
| User name | `$user->name` |
| Challenge title/description | `$challenge->title`, `$challenge->description` |
| Difficulty | `$challenge->difficulty` |
| Current streak | `$challenge->current_streak` |
| Progress % | `ProgressService` (reuse from Issue #2/#4 work) |
| Last check-in status | latest `check_ins` row for that challenge, if any |
| Context | request param: `morning` \| `recovery` \| `general` |

**System instruction (use verbatim or close to it):**

```text
You are Liora Change, a supportive habit coach. You are not a doctor or therapist.
Write under 60 words. Mention the challenge by name. Be warm, specific, and actionable.
If context is "recovery", be gentle about the setback and suggest one tiny next step.
Never use guilt, shame, or clinical language.
```

**User message template (example):**

```text
User: {name}
Challenge: {title} — {description}
Difficulty: {difficulty}
Current streak: {current_streak} days
Progress: {progress_percent}%
Last check-in: {last_status or "none yet"}
Context: {context}

Write one short motivational message for this user right now.
```

## Template fallback (must exist and be tested — this path WILL be exercised in CI since there's no real API key there)

```text
"{name}, your {title} only needs a small step today. {tiny_action_hint}. You've got this."
```

Where `tiny_action_hint` can be a static per-difficulty string (e.g. beginner → "Even 5 minutes counts").

## Required files

```text
app/Services/Ai/OpenAiClient.php        — thin wrapper around the OpenAI HTTP API (chat completions)
app/Services/Ai/MotivationService.php   — builds prompt, calls OpenAiClient, falls back to template
app/Http/Controllers/Api/V1/MotivationController.php
app/Http/Requests/Api/V1/MotivationRequest.php
app/Http/Resources/Api/V1/MotivationResource.php   (or return a plain array — either is fine as long as the shape matches)
config/services.php — add an 'openai' key/model config block reading from env
```

Use Laravel's `Http::` facade for the OpenAI call (no need for a heavy SDK package for the hackathon) — `Http::withToken(config('services.openai.key'))->post('https://api.openai.com/v1/chat/completions', [...])`. Set a short timeout (e.g. 8 seconds) and catch any exception/non-2xx response to trigger the template fallback.

## Testing requirements (MUST)

`tests/Feature/Api/V1/MotivationApiTest.php`:

- [ ] With no `OPENAI_API_KEY` set (default test env) → `200`, `source: "template"`, message contains the challenge title
- [ ] Mock `Http::fake()` to simulate a successful OpenAI response → `source: "openai"`, message equals the mocked content
- [ ] Mock `Http::fake()` to simulate an OpenAI error/timeout → falls back to `source: "template"` gracefully, still `200`
- [ ] `challenge_id` omitted, user has an active challenge → auto-selects it
- [ ] `challenge_id` omitted, user has no challenges → generic message, `challenge_id: null`, no crash
- [ ] `challenge_id` belonging to another user → `403`/`404` (do not leak other users' challenge data into a prompt)
- [ ] Invalid `context` value → `422`
- [ ] Unauthenticated request → `401`

Use `Http::fake([...])` in tests — **do not call the real OpenAI API in the test suite.**

## Definition of Done

- [ ] Endpoint always returns `200` with a usable message, even without an API key
- [ ] Response shape matches SHARED-DATA-CONTRACT `Motivation` exactly
- [ ] Prompt genuinely includes challenge title/streak/progress (verify by reading the code, not just assuming)
- [ ] Tests green with `Http::fake()`, no real network calls in CI
- [ ] `.env.example` updated with `OPENAI_API_KEY` / `OPENAI_MODEL`
- [ ] PR opened against `main`, linked to Issue #7

---

## 🤖 AI Development Prompt

Paste this into your AI coding agent on branch `backend/c1-ai-motivation`:

```text
You are implementing Issue #7 "AI Motivation" for the Liora Change Laravel 12 backend.

Context to read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (section 3.14 Motivation schema — exact field names)
- docs/mvp/09-simple-ai-rag-chat.md (section 2 "AI Motivation")
- docs/mvp/teams/BACKEND-TEAM-GUIDE.md section 7.6, 7.8
- docs/mvp/issues/07-ai-motivation.md (this issue's full spec, including the exact system prompt
  and prompt template to use)
- app/Services/ProgressService.php (reuse for progress_percent, do not reimplement)
- app/Models/Challenge.php, app/Models/CheckIn.php (from Issues #2/#4 — if not yet merged into
  main, create minimal compatible stand-ins so this branch works independently, reconcile later
  via rebase)

Build the following:

1. Add an 'openai' config block to config/services.php reading OPENAI_API_KEY and
   OPENAI_MODEL (default 'gpt-4o-mini') from env. Add both keys with empty/default values to
   .env.example with a comment that they are optional (template fallback works without them).

2. app/Services/Ai/OpenAiClient.php — a thin wrapper with a method like
   chat(array $messages, ?string $model = null): ?string that POSTs to
   https://api.openai.com/v1/chat/completions using Laravel's Http:: facade, with a short
   timeout (~8s), Bearer auth from config('services.openai.key'). If the key is empty/null,
   return null immediately without making a network call. If the HTTP call throws or returns a
   non-2xx status, catch it and return null (never let an exception escape this class).

3. app/Services/Ai/MotivationService.php with a method like
   generate(User $user, ?Challenge $challenge, string $context): array that:
   - Loads challenge fields (title, description, difficulty, current_streak), computes
     progress_percent via ProgressService, and finds the latest check-in status for that
     challenge if one exists.
   - Builds the system + user messages EXACTLY per the templates in
     docs/mvp/issues/07-ai-motivation.md ("Prompt construction" section).
   - Calls OpenAiClient::chat(). If it returns a non-null string, return
     ['message' => <that string>, 'tone' => 'encouraging', 'source' => 'openai',
     'challenge_id' => $challenge?->id, 'challenge_title' => $challenge?->title].
   - If it returns null (no key, error, or timeout), build and return the template fallback
     message per the issue's "Template fallback" section, with 'source' => 'template'.
   - If $challenge is null (user has no challenges), skip challenge-specific fields and return
     a generic encouraging message with challenge_id/challenge_title as null, still working for
     both openai and template paths.

4. app/Http/Requests/Api/V1/MotivationRequest.php validating challenge_id (nullable, integer,
   must exist and belong to the authenticated user — validate ownership in the controller or a
   custom rule, returning 403/404 if it belongs to someone else) and context (nullable, in:
   morning,recovery,general, default general).

5. app/Http/Controllers/Api/V1/MotivationController.php with a generate() action that resolves
   the target challenge (explicit challenge_id, or the user's most recently activated challenge
   if omitted, or null if the user has none), calls MotivationService::generate(), and returns
   { "data": {...} } matching the exact shape in the issue file's "Response 200" example, always
   with HTTP 200 (never 500 for AI provider failures — only 422/403/404 for validation/auth
   issues).

6. Wire POST /api/v1/ai/motivation inside the auth:sanctum v1 group in routes/api.php.

7. Write tests/Feature/Api/V1/MotivationApiTest.php covering every case in the issue's "Testing
   requirements" section. Use Http::fake([...]) from Illuminate\Support\Facades\Http to mock both
   a successful OpenAI response and a failure/timeout — do NOT make real network calls in tests.
   For the "no API key" test, ensure config('services.openai.key') resolves to empty/null in the
   test environment (it should by default since .env.testing won't set it).

8. Run `php artisan test --filter=MotivationApiTest` until fully green, then the full
   `php artisan test` suite to confirm nothing else broke.

9. Manually verify with curl (with and without a real OPENAI_API_KEY set in your local .env) that
   POST /api/v1/ai/motivation returns a 200 with a sensible message either way. Paste the curl
   output (and note which source value you got) in your summary.

Do not rename any JSON field from SHARED-DATA-CONTRACT.md. Never let this endpoint return 500 due
to an AI provider issue. When finished, list every file created or modified and confirm all tests
pass.
```
