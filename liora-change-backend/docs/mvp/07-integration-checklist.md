# 07 — Integration Checklist (Before Demo)

Use this as the joint Backend + Mobile go/no-go list.

---

## A. Environment

- [ ] API running (`php artisan serve` or shared staging URL)
- [ ] MySQL migrated + seeded (`demo@liora.change` / `password`)
- [ ] CORS allows Flutter dev origin (if web) / clearbase URL for device
- [ ] Mobile `.env` / config points to same `BASE_URL`
- [ ] Sanctum tokens work from device/emulator (not only Postman)

---

## B. Auth

- [ ] Register creates user + returns token
- [ ] Login returns token
- [ ] `GET /me` works with Bearer token
- [ ] Logout revokes token
- [ ] Mobile stores token and attaches header
- [ ] 401 sends user to Login

---

## C. Core loop (MUST PASS)

- [ ] Create challenge → `status=draft`
- [ ] Activate → `status=active`, dates set
- [ ] Complete check-in → streak ≥ 1, xp > 0
- [ ] Second complete on same day → 422 or idempotent same record (document which)
- [ ] Skip check-in → streak 0, `recovery_available=true`
- [ ] `GET /recovery/current` → `active=true` after skip
- [ ] Complete after recovery → streak restarts, recovery clears
- [ ] `GET /dashboard` matches home UI fields

---

## D. Contract compliance

- [ ] All keys `snake_case`
- [ ] Error shape has `message` (+ `errors` on 422)
- [ ] Challenge field is `difficulty` (not only `difficulty_score`)
- [ ] Check-in path is `/challenges/{id}/check-ins` (not old habits path)
- [ ] No breaking field renames after freeze time

---

## E. AI Motivation + RAG Chat (MUST)

- [ ] `POST /ai/motivation` with `challenge_id` returns message mentioning challenge
- [ ] Motivation works with OpenAI; template fallback if key missing
- [ ] `POST /ai/chat` answers “What if I miss a day?” using seeded knowledge
- [ ] Chat response includes `session_id`, assistant `message`, optional `sources`
- [ ] Mobile Home motivate button + Coach chat screen wired
- [ ] Knowledge articles exist in Filament / seeder

## F. Filament admin (MUST)

- [ ] `/liora_change` loads and admin can log in (`admin@liora.change`)
- [ ] Users list shows demo/mobile members
- [ ] Categories can be viewed/created
- [ ] Templates can be viewed/created
- [ ] Knowledge articles can be viewed/created (RAG)
- [ ] Template/category/knowledge data is what API/mobile can consume (same DB)

## G. Demo rehearsal (3–4 minutes)

- [ ] Cold start → login as demo user **or** register live
- [ ] Create “Morning Walk”
- [ ] Activate + complete check-in
- [ ] Show streak/XP on Home
- [ ] Skip / show recovery message
- [ ] Complete again → comeback
- [ ] Tap Motivate me → AI text mentions challenge
- [ ] Coach chat → ask about missing a day
- [ ] Open Filament → Templates / Categories / Knowledge / Users
- [ ] Say punchline: *Trackers punish failure. Liora helps you recover — with AI coaching on your challenge.*

---

## H. Known issues log

| Issue | Owner | Workaround for demo | Fixed? |
|-------|-------|---------------------|--------|
| | | | |

---

## I. Freeze rule

**T-60 minutes before judging:** API shape freeze.  
Only bugfixes allowed. No new fields unless demo is blocked.
