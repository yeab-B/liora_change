# Issue #9 — Testing, QA & Error Standards (all APIs)

| Field | Value |
|-------|-------|
| **Dev** | C |
| **Branch** | `backend/c3-testing-qa` |
| **Base** | `main` |
| **Priority** | P0 — this is the safety net that proves "all API must work properly" before the demo |
| **Depends on** | Everything (#1–#8) — this issue is finalized **last**, but the exception-handling and Postman parts can start early |
| **Estimated time** | 4–5 hours (spread across the hackathon, not all at once) |

---

## Business context

Nine endpoints, three developers, one afternoon. The only way to know the whole system actually works together — not just each dev's own branch — is a **single test suite that exercises every MUST endpoint end-to-end**, plus a **consistent error format everywhere**, plus a **one-command smoke script** the team runs right before judging.

## Scope

**In:** global API exception handling, end-to-end integration test covering the full demo story, a Postman/curl smoke script, a lightweight GitHub Actions CI workflow  
**Out:** load testing, security penetration testing, code coverage tooling

## Part 1 — Global error standard (do this early, others depend on it)

Configure Laravel's exception rendering (in `bootstrap/app.php` via `->withExceptions()`, or `app/Exceptions/Handler.php` if this Laravel version still uses it) so that **every** API response under `/api/*` follows the exact same shape, regardless of which controller threw it:

| Exception | Status | Body |
|-----------|--------|------|
| `ValidationException` | 422 | `{ "message": "The given data was invalid.", "code": "VALIDATION_ERROR", "errors": {...} }` |
| `AuthenticationException` | 401 | `{ "message": "Unauthenticated.", "code": "UNAUTHENTICATED" }` |
| `AuthorizationException` / policy `403` | 403 | `{ "message": "This action is unauthorized.", "code": "FORBIDDEN" }` |
| `ModelNotFoundException` / `404` | 404 | `{ "message": "Resource not found.", "code": "NOT_FOUND" }` |
| Any other uncaught `Throwable` | 500 | `{ "message": "Something went wrong.", "code": "SERVER_ERROR" }` (never leak stack traces in the JSON body when `APP_DEBUG=false`; it's fine if Laravel's default debug page still shows locally with `APP_DEBUG=true`) |

Business-rule exceptions (like `INVALID_STATUS_TRANSITION`, `CHALLENGE_NOT_ACTIVE`, `DUPLICATE_CHECK_IN`, `ALREADY_CLAIMED` from other issues) should be thrown as small custom exception classes (e.g. `app/Exceptions/Api/BusinessRuleException.php` with a `code` property) so this handler can render them consistently too — coordinate with Dev A/B if they already threw plain `422` responses ad-hoc; refactor those call sites to use the shared exception class where practical, but don't block the whole issue on refactoring every other dev's controller if time is short — at minimum, document any endpoint that doesn't yet conform.

## Part 2 — Full-loop integration test (the most important deliverable)

Create `tests/Feature/DemoLoopTest.php` that runs the **entire hackathon demo story in one test**, hitting real HTTP endpoints in sequence (using Laravel's `$this->postJson()` / `getJson()` test helpers, not raw curl):

```text
1.  POST /api/v1/auth/register           → 201, get token
2.  GET  /api/v1/me                      → 200, xp_total=0
3.  POST /api/v1/challenges              → 201, status=draft
4.  POST /api/v1/challenges/{id}/activate→ 200, status=active
5.  POST /api/v1/challenges/{id}/check-ins  {status: completed}  → 201, streak=1, xp_earned=10
6.  GET  /api/v1/dashboard               → 200, active_challenges[0].checked_in_today=true
7.  POST /api/v1/challenges/{id}/check-ins  {status: skipped, check_in_date: tomorrow}→ 201, streak reset
8.  GET  /api/v1/recovery/current        → 200, active=true
9.  POST /api/v1/challenges/{id}/check-ins  {status: completed, check_in_date: day after}→ 201
10. GET  /api/v1/recovery/current        → 200, active=false
11. POST /api/v1/ai/motivation  {challenge_id}  → 200, message mentions challenge title, source in [openai, template]
12. POST /api/v1/ai/chat  {message: "What if I miss a day?"}→ 200, session_id present, message.role=assistant
13. POST /api/v1/auth/logout              → 200
14. GET  /api/v1/me (same token)          → 401
```

This test is the **ground truth** that the whole product works end-to-end, independent of any single dev's unit tests. It should be written incrementally as each issue merges — start with steps 1–4 as soon as #1/#2 land, and keep extending it.

## Part 3 — Endpoint coverage checklist (verify, don't just trust each dev's PR)

Go through every MUST endpoint from [teams/SHARED-DATA-CONTRACT.md](../teams/SHARED-DATA-CONTRACT.md) § 4 and confirm a Feature test exists somewhere in the suite that hits it successfully AND at least one failure case. Track it in a table in your PR description:

| Endpoint | Happy-path test exists? | Failure-case test exists? | File |
|----------|--------------------------|----------------------------|------|
| POST /auth/register | ✅/❌ | ✅/❌ | AuthApiTest.php |
| POST /auth/login | | | |
| POST /auth/logout | | | |
| GET /me | | | |
| PATCH /me | | | |
| GET /challenges | | | |
| POST /challenges | | | |
| GET /challenges/{id} | | | |
| POST /challenges/{id}/activate | | | |
| POST /challenges/{id}/check-ins | | | |
| GET /challenges/{id}/check-ins | | | |
| GET /dashboard | | | |
| GET /recovery/current | | | |
| POST /ai/motivation | | | |
| POST /ai/chat | | | |

Any row marked ❌ is a bug to file against the owning dev **before** the demo, not after.

## Part 4 — Smoke script for judging day

Create `scripts/smoke-test.sh` (a simple curl-based bash script, chmod +x) that runs the same 14-step story as the integration test but against a **real running server** (`http://localhost:8000` by default, overridable via `$BASE_URL` env var), printing ✅/❌ per step with the actual response body on failure. This is what the team runs 15 minutes before presenting to catch environment-specific issues (seeding, `.env` misconfig, migrations not run) that the PHPUnit suite (SQLite in-memory) can't catch.

```bash
#!/usr/bin/env bash
set -e
BASE_URL="${BASE_URL:-http://localhost:8000/api/v1}"
# ... register, login, create challenge, activate, check-in, dashboard, recovery, ai/motivation, ai/chat ...
# print PASS/FAIL per step, exit non-zero if any step fails
```

## Part 5 — Minimal CI (GitHub Actions)

Add `.github/workflows/backend-tests.yml` that on every push/PR:

1. Checks out code, sets up PHP 8.4 + Composer
2. Copies `.env.example` → `.env`, sets `DB_CONNECTION=sqlite`, `DB_DATABASE=:memory:`
3. `composer install --no-interaction`
4. `php artisan key:generate`
5. `php artisan test`

This gives every dev's PR a green/red check without needing a real MySQL/OpenAI in CI (all AI tests must use `Http::fake()` per Issues #7/#8 — this CI job will fail loudly if anyone accidentally makes a real network call).

## Testing requirements for THIS issue (meta, but still required)

- [ ] `tests/Feature/DemoLoopTest.php` passes end-to-end against the full merged `main` branch
- [ ] Exception handler produces the documented shape for at least one case of each exception type (write a small `tests/Feature/ErrorFormatTest.php` hitting a deliberately invalid request, an unauthenticated request, and a not-found ID)
- [ ] `scripts/smoke-test.sh` runs successfully against a locally served instance (`php artisan serve` + seeded DB)
- [ ] GitHub Actions workflow shows green on a real PR
- [ ] Endpoint coverage table in Part 3 has no unexplained ❌ rows

## Definition of Done

- [ ] Global error envelope is consistent across every endpoint from every dev
- [ ] `DemoLoopTest.php` is part of `main` and passes
- [ ] `scripts/smoke-test.sh` exists, is executable, and works against a fresh `migrate:fresh --seed`
- [ ] CI workflow green
- [ ] Any endpoint-level bugs found during this issue are filed and fixed (or clearly flagged as known issues in [07-integration-checklist.md](../07-integration-checklist.md) known-issues log) before judging
- [ ] PR opened against `main`, linked to Issue #9

---

## 🤖 AI Development Prompt

Paste this into your AI coding agent on branch `backend/c3-testing-qa` (run this progressively —
start early for Part 1, and re-run/extend for Parts 2–5 as other issues merge into `main`):

```text
You are implementing Issue #9 "Testing, QA & Error Standards" for the Liora Change Laravel 12
backend. This issue is the final safety net across the whole team's work (Issues #1-#8), so read
broadly before writing code.

Context to read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (entire file — sections 1 "Global rules" and 4 "Endpoint
  ↔ schema map" are most relevant here)
- docs/mvp/05-api-contract.md (full file — the canonical list of every endpoint and expected
  status codes)
- docs/mvp/issues/README.md (team split, merge order, Definition of Done)
- docs/mvp/issues/09-testing-qa.md (this issue's full spec, including the exact 14-step demo loop
  and the exact exception-to-status-code mapping table)
- docs/mvp/07-integration-checklist.md (existing checklist to cross-reference, do not duplicate,
  link to it instead)
- All existing tests in tests/Feature/ (read them to understand current testing conventions in
  this codebase before adding new files)

Build the following, in this order:

PART 1 - Global error handling (do this first, it's foundational):
1. In bootstrap/app.php (Laravel 12 uses the ->withExceptions() closure in this file rather than
   a separate Handler.php, unless app/Exceptions/Handler.php still exists in this codebase - check
   first and use whichever mechanism is actually present), register custom rendering ONLY for
   requests where $request->is('api/*') so web/Filament routes are unaffected:
   - Illuminate\Validation\ValidationException -> 422,
     {"message": "The given data was invalid.", "code": "VALIDATION_ERROR", "errors": <validator errors>}
   - Illuminate\Auth\AuthenticationException -> 401,
     {"message": "Unauthenticated.", "code": "UNAUTHENTICATED"}
   - Illuminate\Auth\Access\AuthorizationException -> 403,
     {"message": "This action is unauthorized.", "code": "FORBIDDEN"}
   - Illuminate\Database\Eloquent\ModelNotFoundException (and generic 404 route-not-found) -> 404,
     {"message": "Resource not found.", "code": "NOT_FOUND"}
   - Any other Throwable, when app()->environment() is not 'local'/'testing' or APP_DEBUG is
     false -> 500, {"message": "Something went wrong.", "code": "SERVER_ERROR"} (do not leak
     exception messages/stack traces in this branch; let Laravel's normal debug page still work
     when APP_DEBUG=true and not hitting api/* — verify you scope this narrowly).
2. Create app/Exceptions/Api/BusinessRuleException.php - a simple exception with a public
   readonly string $code and int $status (default 422), and a toResponse()-friendly shape, for
   other devs' business-rule errors (INVALID_STATUS_TRANSITION, CHALLENGE_NOT_ACTIVE, etc.) to use
   consistently. Register its rendering in the same exception handler. Do NOT go refactor every
   other controller across Issues #1-#8 to use this - just make it available and use it in any
   NEW code you write in this issue; note in your PR description which existing ad-hoc 422s you
   found that don't yet use it, as a follow-up note rather than blocking this issue.
3. Write tests/Feature/ErrorFormatTest.php with at least 4 tests: an invalid registration payload
   asserting the VALIDATION_ERROR shape, an unauthenticated request to a protected route
   asserting UNAUTHENTICATED, a request for a nonexistent challenge ID asserting NOT_FOUND, and
   (if any business-rule exception exists yet from other merged issues, e.g. activating a
   completed challenge) asserting that shape too.

PART 2 - Full demo loop integration test:
4. Write tests/Feature/DemoLoopTest.php implementing the exact 14-step sequence from this issue's
   "Part 2" section, using $this->postJson()/getJson()/patchJson() Laravel test helpers with
   Bearer token headers (['Authorization' => 'Bearer '.$token]) carried between steps. Assert the
   specific field values called out at each step (streak numbers, xp_earned, checked_in_today,
   recovery.active transitions, ai response shapes). For steps 11-12 (AI endpoints), use
   Illuminate\Support\Facades\Http::fake([...]) so this test never makes a real OpenAI call and
   remains deterministic in CI. If any endpoint from Issues #1-#8 is not yet merged into the
   branch you're working from, mark that step with $this->markTestSkipped('Waiting on Issue #N')
   rather than deleting it, then come back and un-skip it once you rebase after that issue merges
   - the goal is for this file to be complete and fully passing against the final integrated main.

PART 3 - Endpoint coverage audit:
5. Read every test file under tests/Feature/Api/V1/ (created by Issues #1, #2, #3, #4, #5, #6,
   #7, #8) plus your own new files, and produce the coverage table from this issue's "Part 3"
   section in your PR description, marking any endpoint that lacks both a happy-path and a
   failure-case test. For any gap you find, either add the missing test yourself (preferred if
   quick) or file it as a clearly named follow-up and reference it in
   docs/mvp/07-integration-checklist.md's "Known issues log" table.

PART 4 - Smoke script:
6. Create scripts/smoke-test.sh (bash, chmod +x it) implementing the same 14-step story against a
   REAL running server via curl, with BASE_URL defaulting to http://localhost:8000/api/v1 and
   overridable via an environment variable. Print a clear PASS/FAIL line per step (e.g. using
   `echo "[PASS] step 5: check-in completed"` or `[FAIL] ...` with the raw response body), and
   exit with a non-zero code if any step fails, so it can be used as a final go/no-go check
   right before judging.

PART 5 - CI:
7. Create .github/workflows/backend-tests.yml that on push and pull_request: checks out the repo,
   sets up PHP 8.4 with the extensions this Laravel app needs (check composer.json "require" for
   any ext- entries), runs `composer install --no-interaction --prefer-dist`, copies .env.example
   to .env, sets DB_CONNECTION=sqlite and DB_DATABASE=:memory: (matching phpunit.xml's existing
   testing env), runs `php artisan key:generate`, and runs `php artisan test`. Keep it minimal -
   no deployment steps, this is CI only for the hackathon.

FINALLY:
8. Run the full `php artisan test` suite locally and fix anything failing that is within this
   issue's scope (error format tests, demo loop test). For failures caused by OTHER devs' code
   being incomplete or not yet merged, do not attempt to fix their business logic - instead note
   the gap clearly in your PR description and in docs/mvp/07-integration-checklist.md.
9. Manually run scripts/smoke-test.sh against a `php artisan serve` instance with a freshly
   migrated + seeded database and paste its full PASS/FAIL output in your summary.

Do not weaken any other dev's already-passing test to make your suite green - if you find a
genuine conflict, flag it rather than silently deleting assertions. When finished, list every
file you created or modified, list any endpoint coverage gaps found, and confirm the demo loop
test and error format test both pass.
```
