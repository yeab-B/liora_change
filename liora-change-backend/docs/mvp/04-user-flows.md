# 04 — User Flows (End-to-End)

## Flow A — First win (activation)

```mermaid
sequenceDiagram
  participant U as User
  participant M as Flutter
  participant A as API

  U->>M: Register
  M->>A: POST /auth/register
  A-->>M: user + token
  U->>M: Create challenge
  M->>A: POST /challenges
  A-->>M: challenge status=draft
  U->>M: Start challenge
  M->>A: POST /challenges/{id}/activate
  A-->>M: challenge status=active
  U->>M: Check in complete
  M->>A: POST /challenges/{id}/check-ins
  A-->>M: check-in + streak + xp
  M-->>U: Celebration (streak 1)
```

**Mobile screens:** Register → Create Challenge → Challenge Detail → Check-in sheet → Home

---

## Flow B — Daily return

```mermaid
sequenceDiagram
  participant U as User
  participant M as Flutter
  participant A as API

  U->>M: Open app
  M->>A: GET /dashboard
  A-->>M: today status, streak, xp, active challenges
  alt Not checked in today
    U->>M: Complete check-in
    M->>A: POST /challenges/{id}/check-ins {status:completed}
  else Already done
    M-->>U: Show "Done for today"
  end
```

---

## Flow C — Miss / skip → recovery (the differentiator)

```mermaid
sequenceDiagram
  participant U as User
  participant M as Flutter
  participant A as API

  U->>M: Skip today
  M->>A: POST /challenges/{id}/check-ins {status:skipped, note}
  A-->>M: streak reset + recovery_available=true
  M->>A: GET /recovery/current
  A-->>M: recovery message + suggested tiny action
  M-->>U: Recovery banner (not shame)
  U->>M: Do suggested check-in / continue
  M->>A: POST /challenges/{id}/check-ins {status:completed}
  A-->>M: streak restarts at 1
```

**Copy rule (mobile + API message):**  
Never say “You failed.” Prefer “Missed day — let’s restart small.”

---

## Flow D — Motivation card (optional)

```mermaid
sequenceDiagram
  participant M as Flutter
  participant A as API

  M->>A: GET /dashboard
  M->>A: POST /ai/motivation
  Note over A: Template or LLM
  A-->>M: { message, tone }
  M-->>M: Show card on Home
```

---

## Screen map (Flutter)

| Route (suggested) | Screen | APIs used |
|-------------------|--------|-----------|
| `/login` | Login | `POST /auth/login` |
| `/register` | Register | `POST /auth/register` |
| `/home` | Dashboard | `GET /dashboard`, `GET /recovery/current`, `POST /ai/motivation` |
| `/challenges` | List | `GET /challenges` |
| `/challenges/create` | Create | `POST /challenges` |
| `/challenges/:id` | Detail | `GET /challenges/{id}`, activate, check-ins |
| `/progress` | Progress | `GET /progress` (or dashboard only for MVP) |
| `/profile` | Profile | `GET /me`, `PATCH /me` |

---

## State rules mobile must respect

1. Only **one active check-in per challenge per date** (server enforces).  
2. If challenge not `active`, disable check-in button.  
3. After skip/miss, show recovery UI when `recovery.active == true`.  
4. Optimistic UI OK, but reload dashboard after check-in.  
5. Token stored securely; send on every authenticated call.
