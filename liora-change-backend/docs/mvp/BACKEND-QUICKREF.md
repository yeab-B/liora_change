# Backend Quick Reference (Laravel)

Print / pin this. Full details: [05-api-contract.md](./05-api-contract.md) · [06-data-model.md](./06-data-model.md)

## Implement first (MUST)

```text
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
GET  /api/v1/me
PATCH /api/v1/me

GET  /api/v1/challenges
POST /api/v1/challenges
GET  /api/v1/challenges/{id}
POST /api/v1/challenges/{id}/activate

POST /api/v1/challenges/{id}/check-ins
GET  /api/v1/challenges/{id}/check-ins

GET  /api/v1/dashboard
GET  /api/v1/recovery/current
```

## Business rules to code

1. `draft → active` allowed on activate  
2. Unique `(challenge_id, check_in_date)`  
3. completed → +10 XP, streak++  
4. skipped → streak=0, recovery active  
5. Dashboard aggregates for Home in one call  
6. JSON `snake_case` + error envelope  

## Seed

```text
demo@liora.change / password
mobile@liora.change / password
templates: Morning Walk, No Sugar Week, Phone Curfew
badges: first_checkin, streak_3, comeback
```

## Align with existing code

| Existing | Use for |
|----------|---------|
| `ChallengeService` | draft + status transitions (extend: draft→active) |
| `ProgressService` / `StreakService` / `XPService` | check-in side effects |
| `StoreChallengeRequest` | prefer field `difficulty` (alias `difficulty_score` OK) |
| Postman Stage 1–5 | replace paths with contract; keep as smoke tests |

## Do not build for hackathon

Voice · RAG/Qdrant · risk ML · social partners · FAL images · full i18n

## Freeze

T-60 min: no response-shape changes without mobile agreement.
