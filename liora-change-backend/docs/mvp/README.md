# Liora Change — Hackathon MVP Docs

**Audience:** Backend team + Mobile (Flutter) team  
**Purpose:** One shared source of truth to ship a simple demo that shows how we solve the problem  
**Rule:** If architecture chapters and MVP docs disagree, **MVP docs win for the hackathon**.

---

## Start here (read in order)

| # | Doc | Who needs it |
|---|-----|----------------|
| 1 | [Problem → Solution → Demo](./01-problem-solution-demo.md) | Everyone |
| 2 | [MVP Scope (in / out)](./02-scope.md) | Everyone |
| 3 | [Team Split](./03-team-split.md) | Everyone |
| 4 | [User Flows (E2E)](./04-user-flows.md) | Everyone |
| 5 | [API Contract](./05-api-contract.md) | **Backend + Mobile (main contract)** |
| 6 | [Data Model](./06-data-model.md) | Backend (Mobile: read fields) |
| 7 | [Integration Checklist](./07-integration-checklist.md) | Everyone before demo |
| 8 | [Filament Admin](./08-filament-admin.md) | **Backend (+ demo pitch)** |
| — | [Mobile Quick Ref](./MOBILE-QUICKREF.md) | Mobile pin |
| — | [Backend Quick Ref](./BACKEND-QUICKREF.md) | Backend pin |

Long-term architecture notes (optional, not required for hackathon): [`../architecture/`](../architecture/)

---

## Demo promise (one sentence)

A user can **sign up → create a challenge → check in daily → see streak/XP → get a recovery nudge after a miss**, while **admins manage templates/categories in Filament** — proving we help people change behavior, not only tick checkboxes.

---

## Stack for MVP

| Layer | Tech |
|-------|------|
| Mobile | Flutter + Riverpod + GoRouter + Dio |
| API | Laravel 12 + Sanctum + `/api/v1` |
| Admin | **Filament v4** panel at `/liora_change` (MUST for backend demo) |
| DB | MySQL |
| AI (optional stub) | Simple motivation endpoint (can be mock/template) |

---

## Base URL

```
{{BASE_URL}}/api/v1
```

Auth header after login:

```
Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
```

---

## Status legend

| Status | Meaning |
|--------|---------|
| MVP-MUST | Required for hackathon demo |
| MVP-NICE | Improves demo if time allows |
| LATER | Out of hackathon scope |
