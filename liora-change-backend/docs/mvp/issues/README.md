# Backend Issues — 3 Devs × 3 Issues (9 total)

**Team:** Backend only (3 developers)  
**Base branch:** `main`  
**Rule:** Every issue must ship **working API endpoints + passing tests**. "Done" = curl/Postman proves it, and `php artisan test` proves it.

Each issue file below is **copy-paste ready** for a GitHub Issue (title + body), and ends with a **🤖 AI Development Prompt** you can paste directly into Cursor/agent chat to build it.

---

## Team split

| Dev | Issues | Branches |
|-----|--------|----------|
| **Dev A** | #1 Auth API · #2 Challenges API · #3 Categories & Templates | `backend/a1-auth-api`, `backend/a2-challenges-api`, `backend/a3-categories-templates` |
| **Dev B** | #4 Check-ins API · #5 Dashboard & Recovery · #6 Gamification & Admin | `backend/b1-checkins-api`, `backend/b2-dashboard-recovery`, `backend/b3-gamification-admin` |
| **Dev C** | #7 AI Motivation · #8 AI RAG Chat · #9 Testing & QA | `backend/c1-ai-motivation`, `backend/c2-ai-rag-chat`, `backend/c3-testing-qa` |

## Issue index

| # | Title | Dev | File |
|---|-------|-----|------|
| 1 | Auth API (register/login/logout/me) | A | [01-auth-api.md](./01-auth-api.md) |
| 2 | Challenges API (create/list/show/activate) | A | [02-challenges-api.md](./02-challenges-api.md) |
| 3 | Challenge Categories & Templates (API + Filament) | A | [03-categories-templates-api.md](./03-categories-templates-api.md) |
| 4 | Check-ins API (XP + Streak logic) | B | [04-checkins-api.md](./04-checkins-api.md) |
| 5 | Dashboard & Recovery API | B | [05-dashboard-recovery-api.md](./05-dashboard-recovery-api.md) |
| 6 | Gamification extras & Filament Admin polish | B | [06-gamification-admin.md](./06-gamification-admin.md) |
| 7 | AI Motivation (OpenAI + challenge context) | C | [07-ai-motivation.md](./07-ai-motivation.md) |
| 8 | Simple RAG Chatbot | C | [08-ai-rag-chat.md](./08-ai-rag-chat.md) |
| 9 | Testing, QA & Error Standards (all APIs) | C | [09-testing-qa.md](./09-testing-qa.md) |

---

## Golden rules for every issue

1. **Read first:** [teams/SHARED-DATA-CONTRACT.md](../teams/SHARED-DATA-CONTRACT.md) — field names/enums are law.
2. **One branch per issue**, always branched from latest `main`:
   ```bash
   git checkout main && git pull
   git checkout -b backend/<branch-name>
   ```
3. **Migrations:** use `php artisan make:migration ...` (auto-timestamped) — avoids merge conflicts between devs.
4. **Every endpoint must return the exact JSON shape** in SHARED-DATA-CONTRACT / [05-api-contract.md](../05-api-contract.md).
5. **Every issue ships tests** in `tests/Feature/` (PHPUnit, already used in this repo) — no issue is "done" without green tests.
6. **Error format** is always:
   ```json
   { "message": "string", "code": "STRING_CODE", "errors": { "field": ["msg"] } }
   ```
7. Open a PR into `main`, link the issue number, request review from one other dev.

---

## Suggested merge order (reduce conflicts)

```text
1. #1 Auth API           (Dev A) → merge first, everyone needs users/tokens
2. #2 Challenges API      (Dev A) → merge second, check-ins depend on it
3. #4 Check-ins API       (Dev B) → after #2
4. #5 Dashboard/Recovery  (Dev B) → after #4
5. #3 Categories/Templates(Dev A) → parallel, low conflict risk
6. #6 Gamification/Admin  (Dev B) → after #3 + #4
7. #7 AI Motivation       (Dev C) → parallel, needs #2 (challenge fields)
8. #8 AI RAG Chat         (Dev C) → parallel, independent tables
9. #9 Testing & QA        (Dev C) → continuous, finalized last (covers 1–8)
```

Rebase on `main` daily. If two people touch `routes/api.php`, resolve by keeping both route groups — never delete another dev's routes.

---

## Definition of Done (every issue)

- [ ] Branch created from latest `main`, named as specified
- [ ] Migration(s) run cleanly (`php artisan migrate:fresh --seed`)
- [ ] Endpoint(s) return exact JSON shape from SHARED-DATA-CONTRACT
- [ ] Validation errors return `422` with standard error envelope
- [ ] Feature tests added in `tests/Feature/` and pass: `php artisan test`
- [ ] Manually verified with curl/Postman (paste sample output in PR description)
- [ ] No breaking change to another dev's already-merged endpoint
- [ ] PR opened against `main`, issue linked
