# Mobile Quick Reference (Flutter)

Print / pin this.  
**Full mobile handbook:** [teams/MOBILE-TEAM-GUIDE.md](./teams/MOBILE-TEAM-GUIDE.md)  
**Schemas (same as backend):** [teams/SHARED-DATA-CONTRACT.md](./teams/SHARED-DATA-CONTRACT.md)  
**Your 10 GitHub issues + design system:** [mobile-issues/README.md](./mobile-issues/README.md)  
API examples: [05-api-contract.md](./05-api-contract.md)

## Config

```text
BASE_URL = http://<laptop-ip>:8000/api/v1
Header: Authorization: Bearer <token>
Accept: application/json
```

Use LAN IP for physical device (not `localhost`).

## Must-call order for demo

1. `POST /auth/login` or `register` → save `data.token`  
2. `POST /challenges` → save `data.id`  
3. `POST /challenges/{id}/activate`  
4. `POST /challenges/{id}/check-ins` `{ "status":"completed" }`  
5. `GET /dashboard` → bind Home  
6. `POST /challenges/{id}/check-ins` `{ "status":"skipped" }`  
7. `GET /recovery/current` → show recovery banner  

## Screens → endpoints

| Screen | Calls |
|--------|-------|
| Login | `POST /auth/login` |
| Register | `POST /auth/register` |
| Home | `GET /dashboard` + `POST /ai/motivation` |
| Coach | `POST /ai/chat` (keep `session_id`) |
| Challenge list | `GET /challenges` |
| Create | `POST /challenges` |
| Detail | `GET /challenges/{id}`, activate, check-ins |
| Profile | `GET /me` |

## Models to create (Dart-ish fields)

```text
User: id, name, email, timezone, xp_total, level, current_streak, longest_streak
Challenge: id, title, description, status, difficulty, duration_days,
           progress_percent, current_streak, checked_in_today, start_date, end_date
CheckInResult: check_in{}, summary{ current_streak, xp_earned, xp_total, recovery_available }
Dashboard: user{}, today{}, active_challenges[], recovery{}
Recovery: active, title, message, suggested_action{}
```

## Error handling

```text
401 → logout
422 → show message + field errors.errors
other → snackbar message
```

## Demo account

```text
demo@liora.change / password
```

## Copy rules

- Skip → “Missed day — let’s restart small.”  
- Never “You failed.”
