# Backend Quick Reference (Laravel)

Print / pin this.  
**Full backend handbook:** [teams/BACKEND-TEAM-GUIDE.md](./teams/BACKEND-TEAM-GUIDE.md)  
**Schemas (same as mobile):** [teams/SHARED-DATA-CONTRACT.md](./teams/SHARED-DATA-CONTRACT.md)  
API examples: [05-api-contract.md](./05-api-contract.md) · DB: [06-data-model.md](./06-data-model.md)

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
POST /api/v1/ai/motivation
POST /api/v1/ai/chat
```

AI: OpenAI motivation from challenge + simple MySQL RAG chat. See [09-simple-ai-rag-chat.md](./09-simple-ai-rag-chat.md)

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

## Filament admin (MUST — do not forget)

| Item | Value |
|------|-------|
| URL | `/liora_change` |
| Seed admin | `admin@liora.change` / `password` |
| MUST resources | Users, Categories, Templates |
| Already in repo | `UserResource`, `RoleResource`, `ChallengeResource`, `ChallengeCategoryResource`, `ChallengeTemplateResource`, `FeaturedChallengeResource` |
| Full doc | [08-filament-admin.md](./08-filament-admin.md) |

Filament writes same DB as API. Show it in the demo after the mobile flow.

## Do not build for hackathon

Voice · Qdrant/Pinecone · risk ML · social partners · FAL images · full i18n  
(Do **not** cut Filament, AI motivation, or simple RAG chat.)

## Freeze

T-60 min: no response-shape changes without mobile agreement.
