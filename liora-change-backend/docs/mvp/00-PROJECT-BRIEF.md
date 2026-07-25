# Liora Change — Project Brief (Read This First)

**Purpose of this file:** One prompt/briefing that explains the *whole* project so every team member (and any AI tool they use) starts with the same mental model before opening an issue or writing code.

**Give this file to:** every teammate, and paste it into any AI agent (Cursor, ChatGPT, etc.) as the first message before asking it to build anything.

---

## 📣 Copy-paste version (for pasting into an AI chat or team channel)

```text
PROJECT BRIEF — LIORA CHANGE (read this before building anything)

WHAT WE ARE BUILDING
Liora Change is an AI-powered behavioral transformation platform — NOT a habit tracker.
A habit tracker just logs checkboxes. Liora Change helps someone:
  1. Turn a vague intention ("I want to be healthier") into a structured CHALLENGE
     ("Morning Walk — 7 days, beginner").
  2. Take daily ACTION via a CHECK-IN (complete or skip).
  3. Get feedback: streak, XP, progress %.
  4. When they miss a day, they get RECOVERY support (a gentle nudge to restart small) —
     NOT shame, NOT a broken-streak guilt trip. This is the product's core differentiator.
  5. Get AI support: a "Motivate me" button that generates a short message from their real
     challenge data, and a coach CHATBOT that answers questions using a small knowledge base
     (simple RAG — no vector database needed for this build).
  6. Admins (not end users) manage categories, challenge templates, and the chatbot's knowledge
     articles through a Filament admin panel — separate from the mobile app.

WHY THIS MATTERS (the pitch in one sentence)
"Trackers punish failure. Liora helps you recover — with AI coaching grounded in your own
challenge and a real knowledge base."

WHO IS ON THIS PROJECT
- A Backend team (Laravel 12 + PHP 8.4 + MySQL + Filament v4 admin panel)
- A Mobile team (Flutter + Riverpod + GoRouter + Dio)
- Both teams build against ONE shared contract so integration is painless.

WHAT WE ARE ACTUALLY SHIPPING FOR THIS BUILD (MVP, not the full product vision)
IN SCOPE (must work):
  - Register / login / logout (token-based auth)
  - Create a challenge, activate it
  - Daily check-in: complete or skip
  - Streak + XP calculation
  - A dashboard endpoint that powers the mobile Home screen in one call
  - Recovery detection after a skipped/missed check-in (3-day window)
  - AI Motivation: OpenAI-generated text built from the user's real challenge (title, streak,
    progress) — with a template fallback if the AI call fails or no API key is set (never crash)
  - AI Chatbot with simple RAG: a small MySQL knowledge base (articles → text chunks), keyword
    retrieval (no vector DB), OpenAI answers grounded in that content
  - Filament admin: manage Users, Challenge Categories, Challenge Templates, Knowledge Articles
OUT OF SCOPE (do not build, do not gold-plate):
  - Voice / speech features
  - Any vector database (Qdrant/Pinecone/Weaviate) — MySQL keyword search is enough here
  - Risk-prediction ML, social/accountability partners, image/certificate generation
  - Full multi-language i18n, subscriptions/billing, microservices

THE SINGLE SOURCE OF TRUTH FOR DATA SHAPES
Every JSON field name, enum value, and endpoint shape that Backend produces and Mobile consumes
is frozen in ONE file: docs/mvp/teams/SHARED-DATA-CONTRACT.md
Rule: if code and that file disagree, the file wins — fix the code, don't rename fields to match
whatever you happened to write.

HOW THE DOCS ARE ORGANIZED (so you know where to look)
- docs/mvp/README.md                        → hub / index for everything below
- docs/mvp/01-problem-solution-demo.md      → the demo script we will perform for judges
- docs/mvp/02-scope.md                      → exact in/out scope list
- docs/mvp/04-user-flows.md                 → sequence diagrams of every user flow
- docs/mvp/05-api-contract.md               → full HTTP examples for every endpoint
- docs/mvp/06-data-model.md                 → ER diagram + table specs
- docs/mvp/08-filament-admin.md             → what the admin panel must do
- docs/mvp/09-simple-ai-rag-chat.md         → how the AI motivation + RAG chatbot work
- docs/mvp/07-integration-checklist.md      → the joint go/no-go list before demo day
- docs/mvp/teams/SHARED-DATA-CONTRACT.md    → THE frozen schema both teams must match
- docs/mvp/teams/BACKEND-TEAM-GUIDE.md      → full backend build handbook
- docs/mvp/teams/MOBILE-TEAM-GUIDE.md       → full mobile build handbook
- docs/mvp/issues/README.md                 → the 9 GitHub issues (3 backend devs × 3 each),
                                                each with a full spec + a ready AI build prompt

HOW WE WORK
- Backend: 3 developers, 9 issues total (3 each), one git branch per issue, PRs into `main`.
  Full breakdown, branch names, and merge order: docs/mvp/issues/README.md
- Mobile: builds against docs/mvp/teams/MOBILE-TEAM-GUIDE.md and the same shared contract.
- Every endpoint must return the exact JSON shape from SHARED-DATA-CONTRACT.md.
- Every backend issue ships with automated tests — "done" means tests pass AND a manual
  curl/Postman check succeeds, not just "the code compiles."
- If you need a new field or a behavior change, update SHARED-DATA-CONTRACT.md FIRST, then tell
  the other team, then implement.

THE DEMO STORY WE ARE BUILDING TOWARD (this is the acceptance test for the whole MVP)
1. Register/login as a demo user
2. Create a challenge ("Morning Walk", 7 days, beginner)
3. Activate it
4. Complete a check-in → see streak = 1 and XP go up
5. Skip a check-in → see a recovery banner (NOT a shaming message)
6. Complete another check-in → recovery clears, streak restarts
7. Tap "Motivate me" → AI text that mentions the challenge by name
8. Ask the chatbot "What should I do if I miss a day?" → grounded, supportive answer
9. Open the Filament admin panel → show Categories / Templates / Knowledge Articles / Users

If you can walk through all 9 steps without the app breaking or showing shaming language, the
MVP is done.

YOUR JOB RIGHT NOW
1. Read docs/mvp/README.md fully.
2. If you are Backend: read docs/mvp/teams/BACKEND-TEAM-GUIDE.md, then go to
   docs/mvp/issues/README.md, find your assigned issue number, read that issue file completely,
   create your branch, and use the 🤖 AI Development Prompt at the bottom of that issue file to
   start building.
3. If you are Mobile: read docs/mvp/teams/MOBILE-TEAM-GUIDE.md and
   docs/mvp/teams/SHARED-DATA-CONTRACT.md, then build screen-by-screen following
   docs/mvp/04-user-flows.md.
4. Do not invent new field names, new endpoints, or skip the recovery/AI features — they are the
   whole point of this product, not optional polish.

If anything in this brief conflicts with a specific doc file, the specific doc file wins — this
brief is the map, not the full spec.
```

---

## How to use this file

| Situation | What to do |
|-----------|------------|
| Kickoff meeting with the whole team | Read the copy-paste block above out loud / share it in chat |
| Onboarding a new teammate mid-hackathon | Send them this file first, before any issue or code |
| Starting a Cursor/AI agent session for the first time | Paste the copy-paste block as your first message, then paste the specific issue's 🤖 prompt in the next message |
| Someone asks "wait, what are we even building?" | Send this file |

## One-paragraph version (if someone only has 10 seconds)

> Liora Change is an app that turns a person's goal into a structured challenge, tracks daily check-ins, celebrates streaks with XP, and — most importantly — helps them recover after a missed day instead of shaming them. It also has an AI "Motivate me" button and a simple AI chatbot that answers coaching questions using a small knowledge base. Backend is Laravel + MySQL + Filament admin; Mobile is Flutter. Both sides build against one shared JSON contract so integration just works.
