# 03 — Team Split (Backend ↔ Mobile)

## Communication rule

1. **API Contract** (`05-api-contract.md`) is the single source of truth.  
2. If mobile needs a field → update contract first, then backend implements, then mobile consumes.  
3. No silent response-shape changes.  
4. Use shared Postman collection + this doc.  
5. Blockers go in a shared chat with: endpoint, expected vs actual JSON, status code.

---

## Ownership

| Area | Backend | Mobile |
|------|---------|--------|
| Auth (register/login/token) | Owns API | Owns screens + secure token storage |
| Challenges | Owns rules + status transitions | Owns create/list/detail UX |
| Check-ins | Owns streak/XP side effects | Owns complete/skip UX |
| Dashboard | Owns aggregation | Owns widgets |
| Recovery | Owns when recovery is “active” | Owns banner + CTA |
| Motivation AI stub | Owns endpoint (template or LLM) | Owns card UI |
| Validation errors | Returns standard 422 | Shows field errors |
| Offline | — | Optional Hive cache (nice) |
| Push notifications | LATER | LATER |

---

## Parallel work plan (hackathon timeline)

### Hour 0–2
| Backend | Mobile |
|---------|--------|
| Auth endpoints live | Auth screens + Dio client + token |
| Challenge create/list | Challenge create form + list UI |
| Seed demo user | Navigation shell (GoRouter) |

### Hour 2–5
| Backend | Mobile |
|---------|--------|
| Activate + check-ins | Check-in actions |
| Streak/XP logic | Show streak/XP on home |
| Dashboard endpoint | Dashboard screen |

### Hour 5–7
| Backend | Mobile |
|---------|--------|
| Recovery endpoint | Recovery banner |
| Motivation stub | Motivation card |
| Fix contract mismatches | Wire loading/error states |

### Hour 7–end
| Both |
|------|
| Run [Integration Checklist](./07-integration-checklist.md) |
| Rehearse 3-minute demo story |
| Freeze API changes unless critical bug |

---

## Mobile client conventions

- Base client: Dio  
- Auth interceptor attaches Bearer token  
- On `401` → clear token → login screen  
- Parse `message` + `errors` from API error envelope  
- Dates: ISO-8601 (`2026-07-25`) for `check_in_date`  
- Timezone: send user timezone in profile if available; else device timezone

---

## Backend conventions

- Prefix: `/api/v1`  
- Auth: Laravel Sanctum personal access tokens  
- Resources: consistent JSON keys (`snake_case`)  
- Pagination: Laravel default (`data`, `links`, `meta`) where lists are long  
- MVP lists may return plain `data: []` without pagination if small  
- Business errors: `422` with machine `code` when useful  

---

## Fake/demo accounts

| Email | Password | Purpose |
|-------|----------|---------|
| `demo@liora.change` | `password` | Judge demo |
| `mobile@liora.change` | `password` | Mobile QA |

Backend should seed these.
