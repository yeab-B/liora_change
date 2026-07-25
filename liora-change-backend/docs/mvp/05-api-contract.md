# 05 — API Contract (Hackathon MVP)

**Base URL:** `{{BASE_URL}}/api/v1`  
**Auth:** Laravel Sanctum Bearer token  
**JSON:** `snake_case` keys  
**Date:** `YYYY-MM-DD` for calendar dates; ISO-8601 datetime elsewhere  

This file is the **contract between Backend and Mobile**.  
Do not change response shapes without updating this doc and notifying the other team.

---

## 0. Common formats

### 0.1 Success envelope (single resource)

```json
{
  "data": { }
}
```

### 0.2 Success envelope (list)

```json
{
  "data": [ ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 1,
    "last_page": 1
  }
}
```

MVP may omit `meta` for tiny lists.

### 0.3 Error envelope

```json
{
  "message": "Human readable error",
  "code": "VALIDATION_ERROR",
  "errors": {
    "email": ["The email has already been taken."]
  }
}
```

| HTTP | When |
|------|------|
| 200 | OK |
| 201 | Created |
| 401 | Missing/invalid token |
| 403 | Forbidden |
| 404 | Not found |
| 422 | Validation / business rule |
| 429 | Rate limit (optional) |
| 500 | Server error |

### 0.4 Auth header

```http
Authorization: Bearer {token}
Accept: application/json
```

---

## 1. Auth — MVP-MUST

### 1.1 Register

`POST /auth/register` · Public

**Request**

```json
{
  "name": "Alex Demo",
  "email": "alex@example.com",
  "password": "password",
  "password_confirmation": "password",
  "timezone": "Africa/Addis_Ababa"
}
```

**Validation**
- `name` required string max 255  
- `email` required unique email  
- `password` required min 8 confirmed  
- `timezone` optional string  

**Response `201`**

```json
{
  "data": {
    "user": {
      "id": "uuid-or-int",
      "name": "Alex Demo",
      "email": "alex@example.com",
      "timezone": "Africa/Addis_Ababa"
    },
    "token": "1|xxxxxxxx"
  }
}
```

---

### 1.2 Login

`POST /auth/login` · Public

**Request**

```json
{
  "email": "alex@example.com",
  "password": "password",
  "device_name": "flutter_android"
}
```

**Response `200`**

```json
{
  "data": {
    "user": {
      "id": "uuid-or-int",
      "name": "Alex Demo",
      "email": "alex@example.com",
      "timezone": "Africa/Addis_Ababa"
    },
    "token": "2|xxxxxxxx"
  }
}
```

**Errors:** `422` invalid credentials

---

### 1.3 Logout

`POST /auth/logout` · Auth

**Response `200`**

```json
{
  "message": "Logged out"
}
```

---

### 1.4 Me

`GET /me` · Auth

**Response `200`**

```json
{
  "data": {
    "id": "uuid-or-int",
    "name": "Alex Demo",
    "email": "alex@example.com",
    "timezone": "Africa/Addis_Ababa",
    "xp_total": 120,
    "level": 2,
    "current_streak": 3,
    "longest_streak": 7
  }
}
```

---

### 1.5 Update me

`PATCH /me` · Auth

**Request**

```json
{
  "name": "Alex",
  "timezone": "Africa/Addis_Ababa"
}
```

**Response `200`:** same shape as `GET /me`

---

## 2. Challenges — MVP-MUST

### Challenge object

```json
{
  "id": "uuid-or-int",
  "title": "Morning Walk",
  "description": "Walk 10 minutes after waking up",
  "status": "active",
  "difficulty": "beginner",
  "visibility": "private",
  "category_id": null,
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

**Status enum:** `draft | ready | active | paused | completed | cancelled | archived`  
**Difficulty enum:** `beginner | easy | medium | hard | expert`  
**Visibility enum:** `private | public`

---

### 2.1 List challenges

`GET /challenges` · Auth  

Query (optional): `status=active`, `page=1`

**Response `200`**

```json
{
  "data": [
    { "id": 1, "title": "Morning Walk", "status": "active", "progress_percent": 14.29, "checked_in_today": false }
  ]
}
```

---

### 2.2 Create challenge (draft)

`POST /challenges` · Auth

**Request**

```json
{
  "title": "Morning Walk",
  "description": "Walk 10 minutes after waking up",
  "difficulty": "beginner",
  "visibility": "private",
  "duration_days": 7,
  "category_id": null
}
```

**Validation**
- `title` required  
- `description` optional  
- `difficulty` optional (default `beginner`)  
- `visibility` optional (default `private`)  
- `duration_days` optional integer min 1 max 90 (default 7)  

**Response `201`:** `{ "data": { ...challenge, "status": "draft" } }`

> Note: older Postman used `difficulty_score`. **Contract field is `difficulty`.** Backend may accept both during transition.

---

### 2.3 Show challenge

`GET /challenges/{id}` · Auth · Owner only

**Response `200`:** `{ "data": { ...challenge } }`

---

### 2.4 Activate challenge

`POST /challenges/{id}/activate` · Auth

**Rules**
- Allowed from `draft` or `ready` → `active`  
- Sets `start_date` = today (user timezone)  
- Sets `end_date` = start + duration_days - 1  

**Response `200`:** challenge with `status: "active"`

**Error `422`**

```json
{
  "message": "Challenge cannot be activated from completed",
  "code": "INVALID_STATUS_TRANSITION"
}
```

---

### 2.5 Pause / Resume / Complete (MVP-NICE)

| Method | Path | Effect |
|--------|------|--------|
| POST | `/challenges/{id}/pause` | active → paused |
| POST | `/challenges/{id}/resume` | paused → active |
| POST | `/challenges/{id}/complete` | active → completed |

---

## 3. Check-ins — MVP-MUST

### Check-in object

```json
{
  "id": "uuid-or-int",
  "challenge_id": 1,
  "check_in_date": "2026-07-25",
  "status": "completed",
  "note": "Felt great",
  "mood": 4,
  "energy": 3,
  "xp_earned": 10,
  "streak_after": 1,
  "created_at": "2026-07-25T08:01:00Z"
}
```

**status:** `completed | skipped | missed`  
- Mobile sends `completed` or `skipped`  
- Backend may auto-create `missed` via scheduler later (not required for demo)

---

### 3.1 Create check-in

`POST /challenges/{id}/check-ins` · Auth

**Request**

```json
{
  "status": "completed",
  "note": "Felt great",
  "mood": 4,
  "energy": 3,
  "check_in_date": "2026-07-25"
}
```

**Validation**
- `status` required in `completed,skipped`  
- `note` optional string max 1000  
- `mood` optional int 1–5  
- `energy` optional int 1–5  
- `check_in_date` optional (default: today in user timezone)  

**Business rules**
1. Challenge must be `active`  
2. One check-in per challenge per date (idempotent upsert OK)  
3. `completed` → increment streak + award XP  
4. `skipped` → reset current streak to 0 + mark recovery available  
5. Response must include updated streak/xp summary  

**Response `201`**

```json
{
  "data": {
    "check_in": {
      "id": 10,
      "challenge_id": 1,
      "check_in_date": "2026-07-25",
      "status": "completed",
      "note": "Felt great",
      "mood": 4,
      "energy": 3,
      "xp_earned": 10,
      "streak_after": 1,
      "created_at": "2026-07-25T08:01:00Z"
    },
    "summary": {
      "current_streak": 1,
      "longest_streak": 1,
      "xp_total": 10,
      "xp_earned": 10,
      "challenge_progress_percent": 14.29,
      "recovery_available": false
    }
  }
}
```

**Skip example request**

```json
{
  "status": "skipped",
  "note": "Rained heavily",
  "mood": 2,
  "energy": 2
}
```

**Skip summary should include** `"recovery_available": true`

---

### 3.2 List check-ins for challenge

`GET /challenges/{id}/check-ins` · Auth

**Response `200`:** `{ "data": [ ...check_ins ] }`

---

## 4. Dashboard & Progress — MVP-MUST

### 4.1 Dashboard

`GET /dashboard` · Auth

**Response `200`**

```json
{
  "data": {
    "user": {
      "name": "Alex Demo",
      "xp_total": 40,
      "level": 1,
      "current_streak": 0,
      "longest_streak": 3
    },
    "today": {
      "date": "2026-07-26",
      "active_challenges_count": 1,
      "completed_checkins_count": 0,
      "pending_checkins_count": 1
    },
    "active_challenges": [
      {
        "id": 1,
        "title": "Morning Walk",
        "status": "active",
        "progress_percent": 28.57,
        "current_streak": 0,
        "checked_in_today": false
      }
    ],
    "recovery": {
      "active": true,
      "challenge_id": 1,
      "title": "Missed day — restart small",
      "message": "One missed walk does not erase your progress. Try a 5-minute walk today."
    },
    "motivation_preview": null
  }
}
```

Mobile can render Home entirely from this payload.

---

### 4.2 Progress (optional separate)

`GET /progress` · Auth  

**Response `200`**

```json
{
  "data": {
    "xp_total": 40,
    "level": 1,
    "current_streak": 0,
    "longest_streak": 3,
    "success_rate": 75.0,
    "completed_checkins": 3,
    "skipped_checkins": 1,
    "active_challenges": 1,
    "completed_challenges": 0
  }
}
```

---

### 4.3 Statistics / Calendar — MVP-NICE

`GET /statistics`  
`GET /calendar?month=2026-07`

Calendar item example:

```json
{
  "date": "2026-07-25",
  "status": "completed"
}
```

Statuses: `completed | skipped | missed | none`

---

## 5. Recovery — MVP-MUST

### 5.1 Current recovery

`GET /recovery/current` · Auth

**When active**

```json
{
  "data": {
    "active": true,
    "challenge_id": 1,
    "challenge_title": "Morning Walk",
    "reason": "skipped",
    "title": "Let's restart gently",
    "message": "You skipped yesterday. Today, do the smallest version: 5 minutes.",
    "suggested_action": {
      "type": "check_in",
      "challenge_id": 1,
      "label": "Check in now"
    }
  }
}
```

**When not active**

```json
{
  "data": {
    "active": false
  }
}
```

**Backend rule (simple):** recovery active if user has a `skipped` or `missed` check-in on an active challenge in the last 3 days AND has not completed a check-in since.

---

## 6. Gamification — MVP-MUST (minimal) + NICE

### XP rules (backend)

| Event | XP |
|-------|----|
| Check-in completed | +10 |
| Streak day 3 bonus | +5 |
| Streak day 7 bonus | +15 |
| Skip | +0 |

Level formula (simple): `level = floor(xp_total / 100) + 1`

### 6.1 XP history — MVP-NICE

`GET /xp/history` · Auth

```json
{
  "data": [
    {
      "id": 1,
      "amount": 10,
      "reason": "check_in_completed",
      "challenge_id": 1,
      "created_at": "2026-07-25T08:01:00Z"
    }
  ]
}
```

### 6.2 Badges unlocked — MVP-NICE

`GET /badges/unlocked`

```json
{
  "data": [
    {
      "id": 1,
      "code": "first_checkin",
      "name": "First Step",
      "description": "Completed your first check-in",
      "unlocked_at": "2026-07-25T08:01:00Z"
    }
  ]
}
```

Suggested seed badges: `first_checkin`, `streak_3`, `streak_7`, `comeback` (first check-in after recovery).

### 6.3 Daily reward claim — MVP-NICE

`POST /rewards/daily/claim`

```json
{
  "data": {
    "claimed": true,
    "xp_earned": 5,
    "xp_total": 45
  }
}
```

---

## 7. AI Motivation — MVP-NICE (stub allowed)

`POST /ai/motivation` · Auth

**Request**

```json
{
  "challenge_id": 1,
  "context": "morning"
}
```

**Response `200`**

```json
{
  "data": {
    "message": "Alex, a 10-minute walk keeps your Morning Walk alive. Start tiny — shoes on is enough.",
    "tone": "encouraging",
    "source": "template"
  }
}
```

`source`: `template | openai`  
If provider fails → return template fallback (never 500 for demo if avoidable).

---

## 8. Templates / Categories — MVP-NICE

### 8.1 Categories

`GET /challenge-categories`

```json
{
  "data": [
    { "id": 1, "name": "Health", "slug": "health" },
    { "id": 2, "name": "Focus", "slug": "focus" }
  ]
}
```

### 8.2 Templates

`GET /challenge-templates`

```json
{
  "data": [
    {
      "id": 1,
      "title": "7-Day Morning Walk",
      "description": "Walk 10 minutes each morning",
      "difficulty": "beginner",
      "duration_days": 7,
      "category_id": 1
    }
  ]
}
```

Mobile create screen can prefill from template.

---

## 9. Endpoint checklist (implementation board)

| # | Method | Path | Priority | Owner |
|---|--------|------|----------|-------|
| 1 | POST | `/auth/register` | MUST | Backend |
| 2 | POST | `/auth/login` | MUST | Backend |
| 3 | POST | `/auth/logout` | MUST | Backend |
| 4 | GET | `/me` | MUST | Backend |
| 5 | PATCH | `/me` | MUST | Backend |
| 6 | GET | `/challenges` | MUST | Backend |
| 7 | POST | `/challenges` | MUST | Backend |
| 8 | GET | `/challenges/{id}` | MUST | Backend |
| 9 | POST | `/challenges/{id}/activate` | MUST | Backend |
| 10 | POST | `/challenges/{id}/check-ins` | MUST | Backend |
| 11 | GET | `/challenges/{id}/check-ins` | MUST | Backend |
| 12 | GET | `/dashboard` | MUST | Backend |
| 13 | GET | `/recovery/current` | MUST | Backend |
| 14 | GET | `/progress` | NICE | Backend |
| 15 | POST | `/ai/motivation` | NICE | Backend |
| 16 | GET | `/challenge-templates` | NICE | Backend |
| 17 | GET | `/xp/history` | NICE | Backend |
| 18 | GET | `/badges/unlocked` | NICE | Backend |

---

## 10. Compatibility with existing Postman stages

| Existing Postman | Maps to this contract |
|------------------|-----------------------|
| Stage 1 auth | §1 Auth |
| Stage 2 challenges | §2 Challenges |
| Stage 3 habits tasks complete/skip | §3 Check-ins (`status`) |
| Stage 3 progress/dashboard | §4 Dashboard |
| Stage 5 xp/badges/rewards | §6 Gamification |

**Mobile should implement this contract, not older path names** (`/habits/tasks/...`).  
Backend may keep aliases temporarily if needed, but primary paths are above.

---

## 11. Example full happy-path script ( foreman / curl )

```bash
BASE=http://localhost:8000/api/v1

# Register
curl -s -X POST $BASE/auth/register \
  -H 'Accept: application/json' -H 'Content-Type: application/json' \
  -d '{"name":"Alex","email":"alex@example.com","password":"password","password_confirmation":"password","timezone":"UTC"}'

# Login (save token)
curl -s -X POST $BASE/auth/login \
  -H 'Accept: application/json' -H 'Content-Type: application/json' \
  -d '{"email":"alex@example.com","password":"password","device_name":"demo"}'

TOKEN=paste_token_here

# Create challenge
curl -s -X POST $BASE/challenges \
  -H "Authorization: Bearer $TOKEN" -H 'Accept: application/json' -H 'Content-Type: application/json' \
  -d '{"title":"Morning Walk","description":"10 min walk","difficulty":"beginner","duration_days":7}'

# Activate
curl -s -X POST $BASE/challenges/1/activate \
  -H "Authorization: Bearer $TOKEN" -H 'Accept: application/json'

# Check-in complete
curl -s -X POST $BASE/challenges/1/check-ins \
  -H "Authorization: Bearer $TOKEN" -H 'Accept: application/json' -H 'Content-Type: application/json' \
  -d '{"status":"completed","note":"Done","mood":4,"energy":4}'

# Dashboard
curl -s $BASE/dashboard -H "Authorization: Bearer $TOKEN" -H 'Accept: application/json'
```
