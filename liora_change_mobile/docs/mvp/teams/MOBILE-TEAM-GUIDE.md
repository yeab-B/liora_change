# MOBILE TEAM GUIDE (Flutter)
## Full integration handbook

**You build:** Flutter app (Riverpod + GoRouter + Dio + Material 3)  
**You talk to:** Laravel REST `/api/v1` with Sanctum Bearer token  
**You do NOT use:** Filament admin UI  

| Must read | Why |
|-----------|-----|
| [SHARED-DATA-CONTRACT.md](./SHARED-DATA-CONTRACT.md) | **Same schemas as Backend** |
| [../05-api-contract.md](../05-api-contract.md) | Full request/response examples |
| [../04-user-flows.md](../04-user-flows.md) | Screens + sequences |
| [../MOBILE-QUICKREF.md](../MOBILE-QUICKREF.md) | One-page pin |

---

## 1. Your mission (hackathon)

Ship a demo where a member can:

1. Register / Login  
2. Create + activate a challenge  
3. Check in (complete / skip)  
4. See streak, XP, progress on Home  
5. See **recovery banner** after skip  
6. Tap **Motivate me** → AI text based on their challenge  
7. Use **Coach chat** → simple RAG answers  

**Punchline UI:** after skip, never show “You failed” — show recovery help + AI support.

---

## 2. Project setup

### 2.1 Suggested packages

| Package | Use |
|---------|-----|
| `dio` | HTTP |
| `flutter_riverpod` | State |
| `go_router` | Routes |
| `flutter_secure_storage` | Save token |
| `intl` | Dates |
| `hive` / `hive_flutter` | Optional offline cache |

### 2.2 Config

```text
API_BASE_URL = http://<BACKEND_LAN_IP>:8000/api/v1
```

- Emulator Android → often `http://10.0.2.2:8000/api/v1`  
- iOS simulator → `http://localhost:8000/api/v1`  
- Physical device → laptop LAN IP, same Wi‑Fi  
- Always send:

```http
Accept: application/json
Content-Type: application/json
Authorization: Bearer <token>   # after login
```

### 2.3 Dio interceptor (required behavior)

1. Attach Bearer token if present  
2. On **401** → clear token → go to `/login`  
3. On **422** → expose `message` + `errors` map to forms  
4. Parse only `snake_case` JSON (use `@JsonKey(name: 'xp_total')` or manual)

---

## 3. Folder suggestion

```text
lib/
  core/
    api/          # dio client, endpoints, interceptors
    storage/      # token
    theme/
  features/
    auth/
    challenges/
    checkins/
    home/         # dashboard + recovery
    profile/
  models/         # MUST match SHARED-DATA-CONTRACT
  router/
```

---

## 4. Dart models (must match shared contract)

Map JSON **snake_case** → Dart camelCase in parsers only.  
**Wire names stay snake_case.**

### 4.1 Enums

```dart
enum ChallengeStatus { draft, ready, active, paused, completed, cancelled, archived }
enum ChallengeDifficulty { beginner, easy, medium, hard, expert }
enum ChallengeVisibility { private_, public_ } // map: private/public
enum CheckInStatus { completed, skipped, missed }
```

Serialize enums as **exact strings** from [SHARED-DATA-CONTRACT](./SHARED-DATA-CONTRACT.md).

### 4.2 Models to implement

| Dart class | JSON schema name | Used on |
|------------|------------------|---------|
| `User` | User | auth, me, dashboard |
| `AuthSession` | AuthSession | login/register |
| `Challenge` | Challenge | list/detail/create |
| `CheckIn` | CheckIn | history |
| `CheckInSummary` | CheckInSummary | after check-in |
| `CheckInResult` | CheckInResult | after check-in |
| `DashboardData` | Dashboard | home |
| `TodaySummary` | TodaySummary | home |
| `Recovery` | Recovery | home / recovery |
| `SuggestedAction` | SuggestedAction | recovery CTA |
| `ProgressData` | Progress | progress screen |
| `ChallengeTemplate` | ChallengeTemplate | create flow |
| `ChallengeCategory` | ChallengeCategory | create flow |
| `Motivation` | Motivation | home motivation |
| `ChatSession` | ChatSession | coach screen |
| `ChatMessage` | ChatMessage | coach screen |
| `ChatReply` | ChatReply | after send |
| `ChatSource` | ChatSource | optional “Based on” chips |

**Copy field lists from SHARED-DATA-CONTRACT — do not invent fields.**

### 4.3 Example parser (Challenge)

```dart
Challenge fromJson(Map<String, dynamic> j) => Challenge(
  id: j['id'] as int,
  title: j['title'] as String,
  description: j['description'] as String?,
  status: ChallengeStatus.values.byName(j['status'] as String),
  difficulty: ChallengeDifficulty.values.byName(j['difficulty'] as String),
  visibility: (j['visibility'] as String) == 'public'
      ? ChallengeVisibility.public_
      : ChallengeVisibility.private_,
  categoryId: j['category_id'] as int?,
  startDate: j['start_date'] as String?,
  endDate: j['end_date'] as String?,
  durationDays: j['duration_days'] as int,
  progressPercent: (j['progress_percent'] as num).toDouble(),
  currentStreak: j['current_streak'] as int,
  longestStreak: j['longest_streak'] as int,
  completedCheckins: j['completed_checkins'] as int,
  missedCheckins: j['missed_checkins'] as int,
  checkedInToday: j['checked_in_today'] as bool,
  createdAt: j['created_at'] as String,
  updatedAt: j['updated_at'] as String,
);
```

---

## 5. Screens + exact API calls

### 5.1 Route map

| Route | Screen | APIs |
|-------|--------|------|
| `/login` | LoginPage | `POST /auth/login` |
| `/register` | RegisterPage | `POST /auth/register` |
| `/home` | HomePage | `GET /dashboard`, `POST /ai/motivation` |
| `/coach` | CoachChatPage | `POST /ai/chat`, optional session history |
| `/challenges` | ChallengeListPage | `GET /challenges` |
| `/challenges/create` | CreateChallengePage | `POST /challenges`, optional templates |
| `/challenges/:id` | ChallengeDetailPage | `GET /challenges/:id`, activate, check-ins |
| `/profile` | ProfilePage | `GET /me`, `PATCH /me` |

### 5.2 Login

**Request**

```json
{
  "email": "demo@liora.change",
  "password": "password",
  "device_name": "flutter_android"
}
```

**Save:** `data.token`, `data.user`  
**Then:** navigate `/home`

### 5.3 Register

```json
{
  "name": "Alex",
  "email": "alex@example.com",
  "password": "password",
  "password_confirmation": "password",
  "timezone": "Africa/Addis_Ababa"
}
```

Send device timezone if possible (`FlutterTimezone` / similar).

### 5.4 Home (bind Dashboard)

Call `GET /dashboard` → parse `data`.

| UI widget | Data path |
|-----------|-----------|
| Greeting | `data.user.name` |
| XP | `data.user.xp_total` |
| Level | `data.user.level` |
| Streak | `data.user.current_streak` |
| Today pending | `data.today.pending_checkins_count` |
| Challenge cards | `data.active_challenges[]` |
| Recovery banner | `data.recovery` if `active == true` |

**Recovery banner**

- Title: `recovery.title`  
- Body: `recovery.message`  
- CTA button: `recovery.suggested_action.label`  
- On tap: open challenge `suggested_action.challenge_id` check-in sheet  

### 5.5 Create challenge

**Form fields → JSON**

| Form | JSON key |
|------|----------|
| Title | `title` |
| Description | `description` |
| Difficulty dropdown | `difficulty` (`beginner`…) |
| Duration days | `duration_days` |
| Category (optional) | `category_id` |

`POST /challenges` → then either:

- auto `POST /challenges/{id}/activate`, or  
- button “Start challenge” on detail  

### 5.6 Check-in sheet

**Complete**

```json
{ "status": "completed", "note": "optional", "mood": 4, "energy": 4 }
```

**Skip**

```json
{ "status": "skipped", "note": "optional reason", "mood": 2, "energy": 2 }
```

**After response**

- Show toast: `+{summary.xp_earned} XP` · streak `{summary.current_streak}`  
- If `summary.recovery_available == true` → refresh home / show recovery  
- Disable check-in if `challenge.checked_in_today == true`  

### 5.7 Activate

`POST /challenges/{id}/activate` · empty body  
Only show if `status` is `draft` or `ready`.

### 5.8 AI Motivation (MUST)

On Home (and optionally Challenge detail):

```json
POST /ai/motivation
{
  "challenge_id": 1,
  "context": "morning"
}
```

Use `context: "recovery"` when recovery banner is active.

**UI**
- Button: “Motivate me”  
- Loading spinner while waiting  
- Show `data.message`  
- Small subtitle: challenge title from `data.challenge_title`  
- If `source == template`, still show (offline/fallback OK)

### 5.9 AI Coach Chat + RAG (MUST)

Screen: message list + text field.

**First message / new chat**

```json
POST /ai/chat
{
  "message": "What should I do if I miss a day?",
  "session_id": null,
  "challenge_id": 1
}
```

Save returned `session_id` for follow-ups.

**Next messages**

```json
POST /ai/chat
{
  "message": "Make it smaller for my morning walk",
  "session_id": 3,
  "challenge_id": 1
}
```

**UI tips**
- Show user bubbles + assistant bubbles from `role`  
- Optional: show `sources[].title` under assistant message (“Based on: Recovery basics”)  
- Pass active `challenge_id` whenever possible  
- Disable send while request in flight  
- Max input length 1000  

Suggested starter chips:
- “Motivate me for today”  
- “I missed a day — help”  
- “How do streaks work?”  

---

## 6. State management tips (Riverpod)

| Provider | Holds |
|----------|-------|
| `authTokenProvider` | String? |
| `currentUserProvider` | User? |
| `dashboardProvider` | AsyncValue\<DashboardData\> |
| `challengesProvider` | AsyncValue\<List\<Challenge\>\> |
| `challengeDetailProvider(id)` | AsyncValue\<Challenge\> |
| `chatSessionIdProvider` | int? |
| `chatMessagesProvider` | List\<ChatMessage\> |

**After every check-in / activate:** invalidate `dashboardProvider` + detail provider.

---

## 7. UI states you must handle

| State | UX |
|-------|----|
| Loading | shimmer / spinner |
| Empty challenges | CTA “Create your first challenge” |
| Already checked in today | “Done for today” |
| Recovery active | banner, warm colors, no shame copy |
| 422 validation | under-field errors from `errors.email` etc. |
| Network error | retry button |

### Copy rules

| Bad | Good |
|-----|------|
| You failed | Missed day — let’s restart small |
| Streak destroyed | Streak paused — one small step today |
| Loser | You’ve got this — tiny win counts |

---

## 8. Data you store on device

| Key | Where | Notes |
|-----|-------|-------|
| `auth_token` | secure storage | required |
| `user_json` | secure/prefs | optional cache |
| dashboard cache | Hive optional | stale OK briefly |

**Do not** store password.  
**Do not** invent local schema different from API for server entities.

---

## 9. Demo account (mobile)

```text
email: demo@liora.change
password: password
```

---

## 10. Mobile acceptance checklist

- [ ] All models parse SHARED schemas without crashes  
- [ ] Login/register/logout work  
- [ ] Create → activate → complete check-in works  
- [ ] Skip shows recovery UI  
- [ ] Home uses `GET /dashboard` fields only (no hardcode fake XP)  
- [ ] Motivation calls `POST /ai/motivation` with `challenge_id`  
- [ ] Coach chat calls `POST /ai/chat` and keeps `session_id`  
- [ ] 401 → login  
- [ ] 422 → show field errors  
- [ ] No `difficulty_score` in requests  
- [ ] No calls to Filament URLs  

---

## 11. How to talk to Backend

When something breaks, send:

1. Method + full path  
2. Request JSON  
3. Status code  
4. Response JSON  
5. Expected schema name from SHARED-DATA-CONTRACT  

**Never silently rename fields on mobile to “make it work”.** Ask Backend to match the contract (or update SHARED first).

---

## 12. Out of scope for Mobile (hackathon)

- Filament admin  
- Voice  
- Building RAG yourself (Backend does retrieval; you only call `/ai/chat`)  
- Push notifications  
- Complex social features  
- Offline-first sync engine (simple cache OK)
