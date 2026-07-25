# SHARED DATA CONTRACT
## Single source of truth — Backend + Mobile must match exactly

**File:** `docs/mvp/teams/SHARED-DATA-CONTRACT.md`  
**Rule:** Field names, types, enums, and JSON shapes here are **law**.  
If Backend and Mobile disagree, fix code — do not invent new names.

| Team guide | Path |
|------------|------|
| Mobile | [MOBILE-TEAM-GUIDE.md](./MOBILE-TEAM-GUIDE.md) |
| Backend | [BACKEND-TEAM-GUIDE.md](./BACKEND-TEAM-GUIDE.md) |
| Full API examples | [../05-api-contract.md](../05-api-contract.md) |
| AI Motivation + RAG | [../09-simple-ai-rag-chat.md](../09-simple-ai-rag-chat.md) |

---

## 1. Global rules (both teams)

| Rule | Value |
|------|--------|
| API base | `{HOST}/api/v1` |
| JSON keys | **snake_case only** |
| Auth mobile | `Authorization: Bearer {token}` |
| Content-Type | `application/json` |
| Accept | `application/json` |
| Calendar dates | `YYYY-MM-DD` string (e.g. `2026-07-25`) |
| Date-times | ISO-8601 UTC preferred (`2026-07-25T08:01:00Z`) |
| IDs | integer (`int`) for MVP — same in DB + JSON |
| Nulls | use JSON `null`, never omit required keys on responses when documented |
| Booleans | `true` / `false` (not `1`/`0` in JSON) |
| Money/XP | integers (no decimals for XP) |
| Percents | number with up to 2 decimals (e.g. `14.29`) |

### Success envelope

```json
{ "data": {} }
```

List (optional meta):

```json
{
  "data": [],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 0,
    "last_page": 1
  }
}
```

### Error envelope

```json
{
  "message": "string",
  "code": "STRING_CODE",
  "errors": {
    "field_name": ["string"]
  }
}
```

| HTTP | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not found |
| 422 | Validation / business rule |
| 500 | Server error |

---

## 2. Enums (exact string values)

### challenge_status
`draft` | `ready` | `active` | `paused` | `completed` | `cancelled` | `archived`

### challenge_difficulty
`beginner` | `easy` | `medium` | `hard` | `expert`

### challenge_visibility
`private` | `public`

### check_in_status
`completed` | `skipped` | `missed`

> Mobile may **send** only `completed` or `skipped`.  
> Backend may **store/return** `missed` later.

### motivation_source
`template` | `openai`

### motivation_tone
`encouraging` | `calm` | `direct` | `celebratory`

### xp_reason
`check_in_completed` | `streak_bonus` | `daily_reward` | `badge_bonus`

### recovery_reason
`skipped` | `missed`

### suggested_action_type
`check_in`

---

## 3. Core schemas

### 3.1 User

| Field | Type | Nullable | Notes |
|-------|------|----------|-------|
| id | int | no | |
| name | string | no | |
| email | string | no | |
| timezone | string | yes | IANA, e.g. `Africa/Addis_Ababa` |
| xp_total | int | no | default 0 |
| level | int | no | default 1 |
| current_streak | int | no | default 0 |
| longest_streak | int | no | default 0 |

**JSON example**

```json
{
  "id": 1,
  "name": "Alex Demo",
  "email": "alex@example.com",
  "timezone": "Africa/Addis_Ababa",
  "xp_total": 40,
  "level": 1,
  "current_streak": 0,
  "longest_streak": 3
}
```

**Dart**

```dart
class User {
  final int id;
  final String name;
  final String email;
  final String? timezone;
  final int xpTotal;
  final int level;
  final int currentStreak;
  final int longestStreak;
}
// JSON keys: xp_total → xpTotal, etc.
```

**PHP / DB**

```text
users: id, name, email, password, timezone, xp_total, level, current_streak, longest_streak, timestamps
```

---

### 3.2 AuthSession (login/register response `data`)

| Field | Type | Notes |
|-------|------|-------|
| user | User | |
| token | string | Sanctum plain text token |

```json
{
  "user": { "...User" },
  "token": "1|xxxxxxxx"
}
```

---

### 3.3 Challenge

| Field | Type | Nullable | Notes |
|-------|------|----------|-------|
| id | int | no | |
| title | string | no | |
| description | string | yes | |
| status | challenge_status | no | |
| difficulty | challenge_difficulty | no | |
| visibility | challenge_visibility | no | |
| category_id | int | yes | |
| start_date | date string | yes | set on activate |
| end_date | date string | yes | |
| duration_days | int | no | default 7 |
| progress_percent | number | no | 0–100 |
| current_streak | int | no | |
| longest_streak | int | no | |
| completed_checkins | int | no | |
| missed_checkins | int | no | skipped+missed count OK for MVP |
| checked_in_today | bool | no | |
| created_at | datetime | no | |
| updated_at | datetime | no | |

**JSON example**

```json
{
  "id": 1,
  "title": "Morning Walk",
  "description": "Walk 10 minutes after waking up",
  "status": "active",
  "difficulty": "beginner",
  "visibility": "private",
  "category_id": 1,
  "start_date": "2026-07-25",
  "end_date": "2026-07-31",
  "duration_days": 7,
  "progress_percent": 14.29,
  "current_streak": 1,
  "longest_streak": 1,
  "completed_checkins": 1,
  "missed_checkins": 0,
  "checked_in_today": true,
  "created_at": "2026-07-25T10:00:00Z",
  "updated_at": "2026-07-25T10:05:00Z"
}
```

**Create request (mobile → API)**

| Field | Type | Required |
|-------|------|----------|
| title | string | yes |
| description | string | no |
| difficulty | challenge_difficulty | no (default `beginner`) |
| visibility | challenge_visibility | no (default `private`) |
| duration_days | int | no (default 7) |
| category_id | int | no |

> Do **not** send `difficulty_score`. Use `difficulty` only.

---

### 3.4 CheckIn

| Field | Type | Nullable |
|-------|------|----------|
| id | int | no |
| challenge_id | int | no |
| check_in_date | date string | no |
| status | check_in_status | no |
| note | string | yes |
| mood | int | yes | 1–5 |
| energy | int | yes | 1–5 |
| xp_earned | int | no |
| streak_after | int | no |
| created_at | datetime | no |

**Create request**

| Field | Type | Required |
|-------|------|----------|
| status | `completed` \| `skipped` | yes |
| note | string | no |
| mood | int 1–5 | no |
| energy | int 1–5 | no |
| check_in_date | date | no (default today user TZ) |

---

### 3.5 CheckInResult (`data` of create check-in)

| Field | Type |
|-------|------|
| check_in | CheckIn |
| summary | CheckInSummary |

### 3.6 CheckInSummary

| Field | Type | Notes |
|-------|------|-------|
| current_streak | int | |
| longest_streak | int | |
| xp_total | int | user total after action |
| xp_earned | int | from this action |
| challenge_progress_percent | number | |
| recovery_available | bool | true after skip/miss |

```json
{
  "check_in": { "...CheckIn" },
  "summary": {
    "current_streak": 1,
    "longest_streak": 1,
    "xp_total": 10,
    "xp_earned": 10,
    "challenge_progress_percent": 14.29,
    "recovery_available": false
  }
}
```

---

### 3.7 Dashboard (`GET /dashboard` → `data`)

| Field | Type |
|-------|------|
| user | User (subset OK: name, xp_total, level, current_streak, longest_streak) |
| today | TodaySummary |
| active_challenges | Challenge[] (can be slim) |
| recovery | Recovery \| null or object with active false |
| motivation_preview | string \| null |

### 3.8 TodaySummary

| Field | Type |
|-------|------|
| date | date string |
| active_challenges_count | int |
| completed_checkins_count | int |
| pending_checkins_count | int |

### 3.9 Recovery

| Field | Type | Notes |
|-------|------|-------|
| active | bool | |
| challenge_id | int | required if active |
| challenge_title | string | if active |
| reason | recovery_reason | if active |
| title | string | if active |
| message | string | if active |
| suggested_action | SuggestedAction | if active |

When inactive:

```json
{ "active": false }
```

### 3.10 SuggestedAction

| Field | Type |
|-------|------|
| type | `check_in` |
| challenge_id | int |
| label | string |

---

### 3.11 Progress

| Field | Type |
|-------|------|
| xp_total | int |
| level | int |
| current_streak | int |
| longest_streak | int |
| success_rate | number |
| completed_checkins | int |
| skipped_checkins | int |
| active_challenges | int |
| completed_challenges | int |

---

### 3.12 ChallengeCategory

| Field | Type |
|-------|------|
| id | int |
| name | string |
| slug | string |

### 3.13 ChallengeTemplate

| Field | Type |
|-------|------|
| id | int |
| title | string |
| description | string \| null |
| difficulty | challenge_difficulty |
| duration_days | int |
| category_id | int \| null |

### 3.14 Motivation — MVP-MUST (AI, challenge-based)

| Field | Type | Notes |
|-------|------|-------|
| message | string | generated text |
| tone | motivation_tone | |
| source | motivation_source | `openai` or `template` fallback |
| challenge_id | int \| null | challenge used for generation |
| challenge_title | string \| null | echo for UI |

```json
{
  "message": "Alex, your Morning Walk streak can restart with 5 minutes today. Shoes on — that's enough.",
  "tone": "encouraging",
  "source": "openai",
  "challenge_id": 1,
  "challenge_title": "Morning Walk"
}
```

### 3.15 ChatSession — MVP-MUST (simple RAG chatbot)

| Field | Type |
|-------|------|
| id | int |
| title | string \| null |
| challenge_id | int \| null |
| created_at | datetime |
| updated_at | datetime |

### 3.16 ChatMessage

| Field | Type |
|-------|------|
| id | int |
| session_id | int |
| role | `user` \| `assistant` |
| content | string |
| created_at | datetime |

### 3.17 ChatSource (RAG chunk citation)

| Field | Type |
|-------|------|
| title | string |
| snippet | string |

### 3.18 ChatReply (`data` of `POST /ai/chat`)

| Field | Type |
|-------|------|
| session_id | int |
| message | ChatMessage (assistant) |
| sources | ChatSource[] |
| used_challenge_id | int \| null |

```json
{
  "session_id": 3,
  "message": {
    "id": 12,
    "session_id": 3,
    "role": "assistant",
    "content": "Missing a day is normal. Do the smallest version of Morning Walk today — even 5 minutes counts.",
    "created_at": "2026-07-25T12:00:00Z"
  },
  "sources": [
    { "title": "Recovery basics", "snippet": "After a miss, restart with a tiny action..." }
  ],
  "used_challenge_id": 1
}
```

### 3.19 KnowledgeArticle (admin / internal; optional list API)

| Field | Type |
|-------|------|
| id | int |
| title | string |
| category | string \| null |
| is_active | bool |

### 3.20 XpLedgerItem

| Field | Type |
|-------|------|
| id | int |
| amount | int |
| reason | xp_reason |
| challenge_id | int \| null |
| created_at | datetime |

### 3.21 BadgeUnlocked

| Field | Type |
|-------|------|
| id | int |
| code | string |
| name | string |
| description | string |
| unlocked_at | datetime |

---

## 4. Endpoint ↔ schema map

| Method | Path | Request schema | Response `data` schema | Auth |
|--------|------|----------------|------------------------|------|
| POST | `/auth/register` | RegisterRequest | AuthSession | no |
| POST | `/auth/login` | LoginRequest | AuthSession | no |
| POST | `/auth/logout` | — | `{message}` | yes |
| GET | `/me` | — | User | yes |
| PATCH | `/me` | UpdateMeRequest | User | yes |
| GET | `/challenges` | query status? | Challenge[] | yes |
| POST | `/challenges` | CreateChallengeRequest | Challenge | yes |
| GET | `/challenges/{id}` | — | Challenge | yes |
| POST | `/challenges/{id}/activate` | — | Challenge | yes |
| POST | `/challenges/{id}/check-ins` | CreateCheckInRequest | CheckInResult | yes |
| GET | `/challenges/{id}/check-ins` | — | CheckIn[] | yes |
| GET | `/dashboard` | — | Dashboard | yes |
| GET | `/recovery/current` | — | Recovery | yes |
| GET | `/progress` | — | Progress | yes |
| POST | `/ai/motivation` | MotivationRequest | Motivation | yes |
| POST | `/ai/chat` | ChatRequest | ChatReply | yes |
| GET | `/ai/chat/sessions` | — | ChatSession[] | yes |
| GET | `/ai/chat/sessions/{id}/messages` | — | ChatMessage[] | yes |
| GET | `/challenge-categories` | — | ChallengeCategory[] | yes |
| GET | `/challenge-templates` | — | ChallengeTemplate[] | yes |
| GET | `/xp/history` | — | XpLedgerItem[] | yes |
| GET | `/badges/unlocked` | — | BadgeUnlocked[] | yes |

### Request schemas (compact)

**RegisterRequest:** `name`, `email`, `password`, `password_confirmation`, `timezone?`  
**LoginRequest:** `email`, `password`, `device_name?`  
**UpdateMeRequest:** `name?`, `timezone?`  
**CreateChallengeRequest:** `title`, `description?`, `difficulty?`, `visibility?`, `duration_days?`, `category_id?`  
**CreateCheckInRequest:** `status`, `note?`, `mood?`, `energy?`, `check_in_date?`  
**MotivationRequest:** `challenge_id` (required if user has challenges), `context?` (`morning`\|`recovery`\|`general`)  
**ChatRequest:** `message` (required string max 1000), `session_id?`, `challenge_id?`

### motivation_context enum
`morning` | `recovery` | `general`

### chat_role enum
`user` | `assistant`

---

## 5. Business numbers (same on both sides)

| Rule | Value |
|------|-------|
| XP per completed check-in | +10 |
| XP on skip | 0 |
| Streak on completed (yesterday done or first) | +1 |
| Streak on skip | reset to 0 |
| Level | `floor(xp_total / 100) + 1` |
| progress_percent | `(completed_checkins / duration_days) * 100` rounded 2 decimals |
| One check-in per challenge per date | unique constraint |
| Activate | `draft` or `ready` → `active` (MVP allows draft→active) |

---

## 6. Field naming cheat sheet (NEVER rename)

| Use this | Do NOT use |
|----------|------------|
| `difficulty` | `difficulty_score`, `level_name` |
| `check_ins` (path) | `/habits/tasks/...` |
| `xp_total` | `totalXp`, `points` |
| `progress_percent` | `progress`, `percent_complete` |
| `check_in_date` | `date`, `day` |
| `recovery_available` | `needs_recovery` only (unless both agree) |
| `token` | `access_token` |
| `current_streak` | `streak` |

---

## 7. Integration lock

Before coding models:

1. Copy schemas from **this file**  
2. Backend: API Resources must output these keys  
3. Mobile: `fromJson` must read these keys  
4. Any new field → update **this file first**, then both teams  

**Change protocol:** propose in chat → update SHARED-DATA-CONTRACT → Backend ships → Mobile consumes.
