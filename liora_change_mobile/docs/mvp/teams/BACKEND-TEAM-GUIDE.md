# BACKEND TEAM GUIDE (Laravel + Filament)
## Full integration handbook

**You build:** Laravel 12 API (`/api/v1`) + Filament v4 admin (`/liora_change`) + MySQL  
**Mobile consumes:** only the REST API (Sanctum)  
**Admin uses:** Filament (session auth) — same database  

| Must read | Why |
|-----------|-----|
| [SHARED-DATA-CONTRACT.md](./SHARED-DATA-CONTRACT.md) | **Same schemas as Mobile** |
| [../05-api-contract.md](../05-api-contract.md) | Full examples + validation |
| [../06-data-model.md](../06-data-model.md) | Tables / ERD |
| [../08-filament-admin.md](../08-filament-admin.md) | Admin panel duties |
| [../BACKEND-QUICKREF.md](../BACKEND-QUICKREF.md) | One-page pin |

---

## 1. Your mission (hackathon)

1. Expose all **MVP-MUST** API endpoints with **exact** shared JSON shapes  
2. Keep Filament usable for Users / Categories / Templates / **Knowledge**  
3. Seed demo users so Mobile + judges can log in  
4. Implement check-in side effects: XP, streak, recovery flag  
5. **AI Motivation** — OpenAI text from challenge context (+ template fallback)  
6. **Simple RAG Chatbot** — MySQL knowledge chunks + OpenAI `/ai/chat`  

AI design: [../09-simple-ai-rag-chat.md](../09-simple-ai-rag-chat.md)

**Integration golden rule:** API Resource output keys === SHARED-DATA-CONTRACT.  
Mobile will parse those keys literally.

---

## 2. Stack & entry points

| Piece | Detail |
|-------|--------|
| Framework | Laravel 12 / PHP 8.4 |
| Auth API | Laravel Sanctum token |
| Auth Admin | Filament session at `/liora_change` |
| DB | MySQL |
| Routes | `routes/api.php` → prefix `api/v1` |
| Admin panel | `LioraChangePanelProvider` path `liora_change` |

### Existing code to reuse

| Path | Use for |
|------|---------|
| `app/Services/ChallengeService.php` | draft + status transitions (allow draft→active) |
| `app/Services/ProgressService.php` | progress % |
| `app/Services/StreakService.php` | streak inc/break |
| `app/Services/XPService.php` | award XP |
| `app/Http/Requests/*` | validation |
| `app/Filament/Resources/*` | admin CRUD (already started) |
| `app/Shared/Enums/*` | status/difficulty/visibility |

---

## 3. Database schemas (implement these columns)

IDs: `BIGINT` auto-increment. JSON returns them as numbers.

### 3.1 `users`

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| id | bigint PK | | |
| name | varchar(255) | | |
| email | varchar(255) unique | | |
| password | varchar(255) | | hashed |
| timezone | varchar(64) null | UTC | |
| xp_total | int | 0 | |
| level | int | 1 | |
| current_streak | int | 0 | |
| longest_streak | int | 0 | |
| email_verified_at | timestamp null | | optional |
| remember_token | varchar | | |
| created_at / updated_at | timestamps | | |

Plus Sanctum `personal_access_tokens` table.

### 3.2 `challenges`

| Column | Type | Default |
|--------|------|---------|
| id | bigint PK | |
| user_id | FK users | index |
| category_id | FK null | |
| title | varchar(255) | |
| description | text null | |
| status | varchar(32) | `draft` |
| difficulty | varchar(32) | `beginner` |
| visibility | varchar(32) | `private` |
| start_date | date null | |
| end_date | date null | |
| duration_days | int | 7 |
| current_streak | int | 0 |
| longest_streak | int | 0 |
| created_at / updated_at | | |

Indexes: `(user_id, status)`

### 3.3 `check_ins`

| Column | Type | Default |
|--------|------|---------|
| id | bigint PK | |
| user_id | FK | |
| challenge_id | FK | |
| check_in_date | date | |
| status | varchar(16) | |
| note | text null | |
| mood | tinyint null | 1–5 |
| energy | tinyint null | 1–5 |
| xp_earned | int | 0 |
| created_at / updated_at | | |

**UNIQUE** `(challenge_id, check_in_date)` — critical for Mobile idempotency.

### 3.4 `xp_ledgers`

| Column | Type |
|--------|------|
| id | bigint PK |
| user_id | FK |
| challenge_id | FK null |
| amount | int |
| reason | varchar(64) |
| created_at | timestamp |

### 3.5 `challenge_categories`

| Column | Type |
|--------|------|
| id | bigint PK |
| name | varchar(255) |
| slug | varchar(255) unique |
| timestamps | |

### 3.6 `challenge_templates`

| Column | Type |
|--------|------|
| id | bigint PK |
| category_id | FK null |
| title | varchar(255) |
| description | text null |
| difficulty | varchar(32) |
| duration_days | int |
| timestamps | |

### 3.7 `badges` / `user_badges` (NICE)

See SHARED contract BadgeUnlocked.

### 3.8 `knowledge_articles` — MUST (simple RAG)

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| title | varchar(255) | |
| body | text | full article |
| category | varchar(64) null | e.g. recovery, habits, faq |
| is_active | boolean | default true |
| timestamps | | |

### 3.9 `knowledge_chunks` — MUST

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| knowledge_article_id | FK | |
| chunk_text | text | ~200–500 chars |
| chunk_index | int | order in article |
| timestamps | | |

Optional later: `embedding` JSON column for cosine search.

### 3.10 `chat_sessions` — MUST

| Column | Type |
|--------|------|
| id | bigint PK |
| user_id | FK |
| challenge_id | FK null |
| title | varchar(255) null |
| timestamps | |

### 3.11 `chat_messages` — MUST

| Column | Type |
|--------|------|
| id | bigint PK |
| chat_session_id | FK |
| role | varchar(16) `user`\|`assistant` |
| content | text |
| created_at | timestamp |

### 3.12 `ai_generations` (optional log)

| Column | Type |
|--------|------|
| id | bigint PK |
| user_id | FK |
| type | `motivation`\|`chat` |
| model | varchar |
| prompt_tokens | int null |
| completion_tokens | int null |
| created_at | |

---

## 4. API Resources (output shapes)

Create Laravel API Resources that emit **exactly** these keys (snake_case):

### UserResource

```json
{
  "id", "name", "email", "timezone",
  "xp_total", "level", "current_streak", "longest_streak"
}
```

### ChallengeResource

```json
{
  "id", "title", "description", "status", "difficulty", "visibility",
  "category_id", "start_date", "end_date", "duration_days",
  "progress_percent", "current_streak", "longest_streak",
  "completed_checkins", "missed_checkins", "checked_in_today",
  "created_at", "updated_at"
}
```

Compute:

- `progress_percent` via ProgressService  
- `completed_checkins` / `missed_checkins` via counts  
- `checked_in_today` via exists query for user TZ today  

### CheckInResource

```json
{
  "id", "challenge_id", "check_in_date", "status", "note",
  "mood", "energy", "xp_earned", "streak_after", "created_at"
}
```

`streak_after` = challenge/user streak **after** this check-in is applied.

### DashboardResource

Match SHARED `Dashboard` schema — Mobile Home depends on this one payload.

---

## 5. Endpoints to implement (board)

### MUST

| Method | Path | Controller action | Response schema |
|--------|------|-------------------|-----------------|
| POST | `/auth/register` | register | AuthSession |
| POST | `/auth/login` | login | AuthSession |
| POST | `/auth/logout` | logout | message |
| GET | `/me` | me | User |
| PATCH | `/me` | updateMe | User |
| GET | `/challenges` | index | Challenge[] |
| POST | `/challenges` | store | Challenge |
| GET | `/challenges/{id}` | show | Challenge |
| POST | `/challenges/{id}/activate` | activate | Challenge |
| POST | `/challenges/{id}/check-ins` | storeCheckIn | CheckInResult |
| GET | `/challenges/{id}/check-ins` | listCheckIns | CheckIn[] |
| GET | `/dashboard` | dashboard | Dashboard |
| GET | `/recovery/current` | recovery | Recovery |
| POST | `/ai/motivation` | motivation | Motivation |
| POST | `/ai/chat` | chat | ChatReply |

### NICE

| Method | Path | Schema |
|--------|------|--------|
| GET | `/progress` | Progress |
| GET | `/ai/chat/sessions` | ChatSession[] |
| GET | `/ai/chat/sessions/{id}/messages` | ChatMessage[] |
| GET | `/challenge-categories` | ChallengeCategory[] |
| GET | `/challenge-templates` | ChallengeTemplate[] |
| GET | `/xp/history` | XpLedgerItem[] |
| GET | `/badges/unlocked` | BadgeUnlocked[] |

Route group sketch:

```text
Route::prefix('v1')->group(...)
  public: auth/register, auth/login
  auth:sanctum: everything else
```

---

## 6. Validation rules (mirror Mobile forms)

### Register
- name: required|string|max:255  
- email: required|email|unique:users,email  
- password: required|string|min:8|confirmed  
- timezone: nullable|string|max:64  

### Login
- email: required|email  
- password: required  
- device_name: nullable|string|max:255  

### Create challenge
- title: required|string|max:255  
- description: nullable|string  
- difficulty: nullable|in:beginner,easy,medium,hard,expert  
- visibility: nullable|in:private,public  
- duration_days: nullable|integer|min:1|max:90  
- category_id: nullable|integer|exists:challenge_categories,id  

Alias (optional): accept `difficulty_score` but **normalize to `difficulty`** in Resource output.

### Check-in
- status: required|in:completed,skipped  
- note: nullable|string|max:1000  
- mood: nullable|integer|min:1|max:5  
- energy: nullable|integer|min:1|max:5  
- check_in_date: nullable|date  

---

## 7. Business logic (implement exactly)

### 7.1 Activate

```text
if status in [draft, ready]:
  status = active
  start_date = today(user.timezone)
  end_date = start_date + duration_days - 1 days
else:
  422 INVALID_STATUS_TRANSITION
```

Update `ChallengeService::canTransition` to allow **Draft → Active** for MVP.

### 7.2 Check-in completed

```text
assert challenge.status == active
assert unique(challenge_id, date)
xp = 10
streak = increment (use StreakService)
user.xp_total += xp
user.level = floor(xp_total/100)+1
write xp_ledgers reason=check_in_completed
recovery_available = false
optional: unlock badge first_checkin / streak_3
```

### 7.3 Check-in skipped

```text
xp = 0
streak current = 0  (longest unchanged)
recovery_available = true
```

### 7.4 Recovery current

```text
active = true if:
  user has active challenge AND
  latest check-in for that challenge is skipped|missed AND
  that date is within last 3 days AND
  no completed check-in after it
else active = false
```

Message can be template string (no AI required).

### 7.5 Dashboard aggregation

Return one JSON matching SHARED `Dashboard` so Mobile does not need 5 round-trips.

### 7.6 AI Motivation (MUST)

```text
Input: challenge_id, context
Load: user, challenge, progress_percent, streak, last check-in
Build prompt with those fields
Call OpenAI chat (gpt-4o-mini recommended)
Return Motivation schema (source=openai)
On failure: template with challenge.title (source=template)
```

Example system instruction:

```text
You are Liora Change, a supportive habit coach. Not a doctor.
Write under 60 words. Mention the challenge by name.
If context is recovery, be gentle and suggest a tiny next step.
```

### 7.7 Simple RAG Chat (MUST)

```text
1. Validate message (max 1000)
2. Create or load chat_session (user-owned)
3. Store user ChatMessage
4. Retrieve top 3–5 knowledge_chunks:
   - MVP: MySQL FULLTEXT / LIKE on chunk_text vs message keywords
5. Load last ~6 messages in session
6. Load challenge summary if challenge_id present
7. Prompt OpenAI with: system + chunks + history + question
8. Store assistant message
9. Return ChatReply with sources[{title, snippet}]
```

Chunking on article save:

```text
Split body by paragraphs / ~400 chars → knowledge_chunks rows
```

Seed at least 8–15 chunks (recovery, streaks, tiny habits, FAQ).

### 7.8 Env

```env
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o-mini
```

Suggested service classes:

```text
app/Services/Ai/OpenAiClient.php
app/Services/Ai/MotivationService.php
app/Services/Ai/SimpleRagRetriever.php
app/Services/Ai/ChatService.php
app/Services/Ai/KnowledgeChunker.php
```

---

## 8. Error format (required)

Always:

```json
{
  "message": "The given data was invalid.",
  "code": "VALIDATION_ERROR",
  "errors": { "email": ["The email has already been taken."] }
}
```

Business example:

```json
{
  "message": "Challenge cannot be activated from completed",
  "code": "INVALID_STATUS_TRANSITION"
}
```

Configure Laravel exception rendering for API to match this (Mobile depends on it).

---

## 9. Filament (MUST)

Panel URL: `/liora_change`

| Resource | MVP |
|----------|-----|
| UserResource | MUST |
| ChallengeCategoryResource | MUST |
| ChallengeTemplateResource | MUST |
| KnowledgeArticleResource | MUST (title, body, category, is_active) |
| ChallengeResource | NICE (view) |
| RoleResource | NICE |
| FeaturedChallengeResource | NICE |

On KnowledgeArticle save → re-chunk into `knowledge_chunks`.

### Seed admin

```text
admin@liora.change / password   → can access Filament
demo@liora.change / password    → member (Mobile)
mobile@liora.change / password  → member QA
```

Ensure admin user has correct role/panel access.

### Filament ↔ API consistency

| Filament field | DB column | API JSON key |
|----------------|-----------|--------------|
| Title | title | title |
| Difficulty | difficulty | difficulty |
| Duration days | duration_days | duration_days |
| Category | category_id | category_id |

When admin edits a template, `GET /challenge-templates` must return the new values (same row).

---

## 10. Seed content (required for demo)

**Categories**

| name | slug |
|------|------|
| Health | health |
| Focus | focus |
| Wellbeing | wellbeing |

**Templates**

| title | difficulty | duration_days | category |
|-------|------------|---------------|----------|
| 7-Day Morning Walk | beginner | 7 | Health |
| No Sugar Week | medium | 7 | Health |
| Night Phone Curfew | easy | 7 | Focus |

**Badges (NICE):** `first_checkin`, `streak_3`, `comeback`

**Knowledge (MUST for RAG)** — seed articles such as:

| title | category |
|-------|----------|
| Tiny habits starter | habits |
| Recovery basics | recovery |
| Humane streaks | streaks |
| How check-ins work | faq |
| Writing a good challenge | faq |

---

## 11. Suggested backend folder layout

```text
app/Http/Controllers/Api/V1/
  AuthController.php
  MeController.php
  ChallengeController.php
  CheckInController.php
  DashboardController.php
  RecoveryController.php
  MotivationController.php
  ChatController.php
app/Http/Resources/V1/
  UserResource.php
  ChallengeResource.php
  CheckInResource.php
  DashboardResource.php
  RecoveryResource.php
  MotivationResource.php
  ChatReplyResource.php
app/Services/   # existing + Ai/*
app/Filament/Resources/  # existing + KnowledgeArticleResource
database/migrations/
database/seeders/DemoSeeder.php
database/seeders/KnowledgeSeeder.php
```

---

## 12. CORS / device access

For physical phones:

- `php artisan serve --host=0.0.0.0 --port=8000`  
- Open firewall for port 8000 if needed  
- Sanctum: ensure API token auth (not cookie) for mobile  
- If using stateful domains, keep mobile on **token** auth only  

---

## 13. Testing for Mobile (your duty)

Before saying “API ready”:

```bash
# smoke
POST /auth/login demo user
POST /challenges
POST /challenges/1/activate
POST /challenges/1/check-ins  status=completed
GET  /dashboard
POST /challenges/1/check-ins  status=skipped  # use tomorrow or allow same-day? 
# Prefer: completed day1, skipped day2 via check_in_date param for demo script
GET  /recovery/current
POST /ai/motivation  {challenge_id, context:morning}
POST /ai/chat        {message, challenge_id}
```

Compare every response key to SHARED-DATA-CONTRACT.  
Share Postman/curl results with Mobile.

**Demo tip:** allow `check_in_date` override so demo can show complete then skip without waiting 2 days.

---

## 14. Backend acceptance checklist

- [ ] All MUST routes registered under `/api/v1`  
- [ ] Resources match SHARED schemas 100%  
- [ ] Unique check-in per challenge per date  
- [ ] XP/streak/recovery rules correct  
- [ ] Error envelope stable  
- [ ] Seeded admin + demo + mobile users  
- [ ] Filament login works; categories/templates CRUD  
- [ ] `GET /dashboard` alone can power Mobile Home  
- [ ] `/ai/motivation` uses challenge fields; OpenAI + template fallback  
- [ ] `/ai/chat` retrieves seeded chunks and returns `sources`  
- [ ] Filament Knowledge Article create → chunks updated  
- [ ] No breaking renames after Mobile starts parsing  

---

## 15. How to talk to Mobile

When you change anything:

1. Update [SHARED-DATA-CONTRACT.md](./SHARED-DATA-CONTRACT.md) first  
2. Update API Resource  
3. Ping Mobile with: endpoint + sample JSON  

If Mobile reports mismatch, **Backend fixes Resource** unless SHARED was wrong.

---

## 16. Out of scope (hackathon)

Voice · Qdrant/Pinecone · risk ML · FAL images · full i18n · microservices  

**Do not cut:** Filament admin + MUST API + **AI motivation** + **simple MySQL RAG chat** + shared schemas.
