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

## E. Demo rehearsal (3 minutes)

- [ ] Cold start → login as demo user **or** register live
- [ ] Create “Morning Walk”
- [ ] Activate + complete check-in
- [ ] Show streak/XP on Home
- [ ] Skip / show recovery message
- [ ] Complete again → comeback
- [ ] Say punchline: *Trackers punish failure. Liora helps you recover.*

---

## F. Known issues log

| Issue | Owner | Workaround for demo | Fixed? |
|-------|-------|---------------------|--------|
| | | | |

---

## G. Freeze rule

**T-60 minutes before judging:** API shape freeze.  
Only bugfixes allowed. No new fields unless demo is blocked.
