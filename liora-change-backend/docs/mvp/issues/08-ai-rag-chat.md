# Issue #8 — Simple RAG Chatbot

| Field | Value |
|-------|-------|
| **Dev** | C |
| **Branch** | `backend/c2-ai-rag-chat` |
| **Base** | `main` |
| **Priority** | P0 — explicitly requested "chatbot with simple RAG" for the demo |
| **Depends on** | None for the tables (independent); optionally #2 Challenges API for personalization context |
| **Estimated time** | 5–6 hours |

---

## Business context

The chatbot must answer coaching questions **grounded in seeded knowledge** (not pure hallucination). No vector database is required — MySQL keyword retrieval over a small chunk table is enough for a convincing hackathon demo, and it keeps this issue fully independent of any external vector service.

## Scope

**In:** knowledge articles/chunks tables, keyword retrieval, `POST /ai/chat`, chat session/message persistence, Filament `KnowledgeArticleResource`  
**Out:** embeddings/cosine similarity (nice-to-have upgrade only if time remains), streaming responses, multi-turn summarization

## Database

### `knowledge_articles`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| title | varchar(255) | |
| body | text | full article, admin-authored |
| category | varchar(64) nullable | e.g. `recovery`, `habits`, `faq` |
| is_active | boolean | default true |
| timestamps | | |

### `knowledge_chunks`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| knowledge_article_id | FK → knowledge_articles, cascade on delete | |
| chunk_text | text | ~200–500 chars |
| chunk_index | integer | order within article |
| timestamps | | |

Add a **FULLTEXT index** on `chunk_text` (MySQL) so keyword retrieval is fast: `$table->fullText('chunk_text');` (requires InnoDB + MySQL 5.6+, which this stack has).

### `chat_sessions`

| Column | Type |
|--------|------|
| id | bigint PK |
| user_id | FK → users |
| challenge_id | FK → challenges, nullable |
| title | varchar(255) nullable |
| timestamps | |

### `chat_messages`

| Column | Type |
|--------|------|
| id | bigint PK |
| chat_session_id | FK → chat_sessions, cascade on delete |
| role | varchar(16) — `user` \| `assistant` |
| content | text |
| created_at | timestamp |

## Models

```text
app/Models/KnowledgeArticle.php  — hasMany KnowledgeChunk
app/Models/KnowledgeChunk.php    — belongsTo KnowledgeArticle
app/Models/ChatSession.php       — belongsTo User, hasMany ChatMessage
app/Models/ChatMessage.php       — belongsTo ChatSession
```

## Chunking logic (on `KnowledgeArticle` save)

```text
Split `body` into paragraphs (split on double newline).
For any paragraph longer than ~500 chars, further split into ~400-char pieces at sentence
boundaries where possible.
Delete existing chunks for that article and re-insert in order (chunk_index = 0, 1, 2...).
```

Implement as `app/Services/Ai/KnowledgeChunker.php` with a `chunk(KnowledgeArticle $article): void` method, called from a Filament resource hook (`afterSave`) or a model `saved` event listener — pick whichever is simplest to wire reliably.

## Retrieval (keyword-based — no vector DB)

```text
app/Services/Ai/SimpleRagRetriever.php

retrieve(string $query, int $limit = 5): Collection<KnowledgeChunk>
  - Use MySQL FULLTEXT MATCH...AGAINST in natural language mode against chunk_text
    (whereRaw('MATCH(chunk_text) AGAINST(? IN NATURAL LANGUAGE MODE)', [$query]))
  - Only include chunks whose article is_active = true
  - Fallback: if FULLTEXT returns nothing (e.g. very short/odd query), fall back to a simple
    LIKE '%keyword%' search on a few extracted keywords from the query, or just return the most
    recently created chunks as a last resort so the chat never returns zero context.
  - Order by relevance score (FULLTEXT natural relevance) descending, limit to $limit.
```

## Routes

```php
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::post('/ai/chat', [ChatController::class, 'send']);
    Route::get('/ai/chat/sessions', [ChatController::class, 'sessions']);               // nice-to-have
    Route::get('/ai/chat/sessions/{session}/messages', [ChatController::class, 'messages']); // nice-to-have
});
```

## Endpoint spec

### `POST /api/v1/ai/chat` (auth)

**Request**

```json
{ "message": "What should I do if I miss a day?", "session_id": null, "challenge_id": 1 }
```

**Validation:** `message` required|string|max:1000 · `session_id` nullable|integer (must belong to the authenticated user if provided, else `403`/`404`) · `challenge_id` nullable|integer (must belong to the authenticated user if provided)

**Flow (implement exactly):**

1. If `session_id` given, load it (owner-checked); else create a new `chat_sessions` row for this user (and `challenge_id` if given).
2. Persist the user's message as a `chat_messages` row (`role: user`).
3. Call `SimpleRagRetriever::retrieve($message)` → up to 5 chunks.
4. Load the last ~6 messages in this session (for short-term memory).
5. If `challenge_id` present, load a short challenge summary (title, streak, progress — reuse logic from Issue #7 if merged, or keep it simple/local here).
6. Build the OpenAI prompt: system instruction + retrieved chunks (as reference material) + recent message history + the new user message.
7. Call `OpenAiClient` (reuse the same class from Issue #7 if it's on `main`; otherwise implement a local minimal version here and de-duplicate later — do not block this issue on #7).
8. If OpenAI succeeds, use its reply. If it fails/no key, **fallback**: return the single best-matching chunk's text (or a short canned FAQ answer) as the assistant reply so the chat never appears broken.
9. Persist the assistant's reply as a `chat_messages` row (`role: assistant`).
10. Return the response shape below.

**System instruction (use verbatim or close to it):**

```text
You are Liora Change's AI coach. Answer using the provided reference material when relevant.
You are supportive, brief (under 100 words), and never claim to be a doctor or therapist.
If the user seems to be in crisis, gently suggest they reach out to a trusted person or local
support service — do not attempt therapy.
```

**Response `200`**

```json
{
  "data": {
    "session_id": 3,
    "message": {
      "id": 12, "session_id": 3, "role": "assistant",
      "content": "Missing a day is normal. For Morning Walk, restart with 5 minutes today — the goal is returning, not perfection.",
      "created_at": "2026-07-25T12:00:00Z"
    },
    "sources": [ { "title": "Recovery basics", "snippet": "After a miss, restart with a tiny action instead of quitting." } ],
    "used_challenge_id": 1
  }
}
```

### `GET /api/v1/ai/chat/sessions` (auth) — nice-to-have

`{ "data": [ ChatSession, ... ] }` for the authenticated user, newest first.

### `GET /api/v1/ai/chat/sessions/{id}/messages` (auth) — nice-to-have

`{ "data": [ ChatMessage, ... ] }` ordered oldest first (natural conversation order), owner-checked.

## Filament — Knowledge Articles (this issue owns this resource)

Create `app/Filament/Resources/KnowledgeArticleResource.php`:
- Form: `title` (TextInput), `body` (Textarea/RichEditor, large), `category` (TextInput or Select with a few preset options), `is_active` (Toggle)
- Table: `title`, `category`, `is_active`, `created_at`
- On save (create/update), trigger `KnowledgeChunker::chunk($article)`

## Seed knowledge (required — write at least these 5, more is better)

| title | category | body (short) |
|-------|----------|---------------|
| Tiny habits starter | habits | Start absurdly small; consistency beats intensity. |
| Recovery basics | recovery | After a miss, restart with a tiny action instead of quitting; one miss is not a failure. |
| Humane streaks | streaks | Streaks are a tool for motivation, not a measure of self-worth; a broken streak doesn't erase progress. |
| How check-ins work | faq | A check-in records a completed or skipped day for a challenge; each challenge allows one check-in per calendar day. |
| Writing a good challenge | faq | Good challenges are specific, small, and tied to a clear trigger/time of day. |

Add a `KnowledgeSeeder.php` (or a method in the shared `DemoSeeder.php`) that creates these via `firstOrCreate` and triggers chunking.

## Testing requirements (MUST)

`tests/Feature/Api/V1/ChatApiTest.php`:

- [ ] Sending a first message with no `session_id` creates a new `chat_sessions` row and returns a `session_id`
- [ ] Sending a follow-up with the returned `session_id` appends to the same session (assert message count grows)
- [ ] A question matching seeded "Recovery basics" content returns a reply/sources referencing that content (assert via `Http::fake()` mocked OpenAI response AND via the no-key template fallback path — test both)
- [ ] With no `OPENAI_API_KEY`, chat still returns `200` with a usable fallback reply, never `500`
- [ ] `message` over 1000 chars → `422`
- [ ] `session_id` belonging to another user → `403`/`404`
- [ ] Unauthenticated request → `401`
- [ ] `KnowledgeChunker` splits a multi-paragraph article body into more than one chunk row

Use `Http::fake([...])` — no real OpenAI calls in tests.

## Definition of Done

- [ ] All 4 tables + models created; FULLTEXT index present on `knowledge_chunks.chunk_text`
- [ ] `POST /ai/chat` matches SHARED-DATA-CONTRACT `ChatReply` shape exactly
- [ ] Retrieval never returns empty context when chunks exist (fallback logic works)
- [ ] Chat never returns `500` due to AI provider issues
- [ ] Filament `KnowledgeArticleResource` triggers re-chunking on save
- [ ] Seed data present (≥5 articles)
- [ ] Tests green: `php artisan test --filter=ChatApiTest`
- [ ] PR opened against `main`, linked to Issue #8

---

## 🤖 AI Development Prompt

Paste this into your AI coding agent on branch `backend/c2-ai-rag-chat`:

```text
You are implementing Issue #8 "Simple RAG Chatbot" for the Liora Change Laravel 12 backend.

Context to read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (sections 3.15-3.19: ChatSession, ChatMessage, ChatSource,
  ChatReply, KnowledgeArticle — exact field names)
- docs/mvp/09-simple-ai-rag-chat.md (full design: sections 3, 4, 5 — retrieval approach, why no
  vector DB is needed for MVP)
- docs/mvp/teams/BACKEND-TEAM-GUIDE.md sections 3.8-3.11, 7.7, 9
- docs/mvp/issues/08-ai-rag-chat.md (this issue's full spec, including exact system prompt,
  chunking rules, and retrieval fallback behavior)
- If app/Services/Ai/OpenAiClient.php already exists on main (from Issue #7), reuse it directly.
  If it does not exist yet on this branch, implement a local minimal version in
  app/Services/Ai/OpenAiClient.php with a chat(array $messages, ?string $model = null): ?string
  method using Laravel's Http:: facade against https://api.openai.com/v1/chat/completions,
  returning null on any failure/missing key (never throwing). This avoids blocking on Issue #7.

Build the following:

1. Migration `create_knowledge_articles_table`: id, title (varchar 255), body (text), category
   (varchar 64 nullable), is_active (boolean default true), timestamps.

2. Migration `create_knowledge_chunks_table`: id, knowledge_article_id (FK, cascade delete),
   chunk_text (text), chunk_index (integer), timestamps, PLUS a MySQL FULLTEXT index on
   chunk_text (use $table->fullText('chunk_text') in the migration; make sure the table engine
   supports it — InnoDB with MySQL 5.6+ does).

3. Migration `create_chat_sessions_table`: id, user_id (FK users), challenge_id (FK challenges,
   nullable), title (varchar 255 nullable), timestamps.

4. Migration `create_chat_messages_table`: id, chat_session_id (FK chat_sessions, cascade
   delete), role (varchar 16), content (text), created_at only (no updated_at needed, but fine
   to include timestamps() for simplicity).

5. Models: app/Models/KnowledgeArticle.php (hasMany KnowledgeChunk), app/Models/KnowledgeChunk.php
   (belongsTo KnowledgeArticle), app/Models/ChatSession.php (belongsTo User, hasMany ChatMessage),
   app/Models/ChatMessage.php (belongsTo ChatSession).

6. app/Services/Ai/KnowledgeChunker.php with a chunk(KnowledgeArticle $article): void method
   implementing the splitting rules in the issue's "Chunking logic" section exactly (split by
   paragraphs, further split long paragraphs to ~400 chars, delete old chunks and re-insert with
   sequential chunk_index).

7. app/Services/Ai/SimpleRagRetriever.php with a retrieve(string $query, int $limit = 5): Collection
   method implementing the exact retrieval strategy in the issue's "Retrieval" section: MySQL
   FULLTEXT MATCH...AGAINST natural language mode on chunk_text, scoped to active articles only,
   with a LIKE-based or "most recent chunks" fallback if FULLTEXT returns zero results, so the
   chat is never left with empty context when chunks exist in the table.

8. app/Http/Requests/Api/V1/ChatRequest.php validating message (required, string, max:1000),
   session_id (nullable, integer, must belong to authenticated user), challenge_id (nullable,
   integer, must belong to authenticated user).

9. app/Services/Ai/ChatService.php with a method like
   respond(User $user, string $message, ?int $sessionId, ?int $challengeId): array implementing
   the full 10-step flow in the issue's "Flow (implement exactly)" section: resolve/create
   session, persist user message, retrieve chunks via SimpleRagRetriever, load last ~6 messages,
   optionally load a short challenge summary, build the OpenAI prompt using the exact system
   instruction from the issue file, call OpenAiClient, fall back to the best-matching chunk text
   (or a short canned answer) if the AI call fails, persist the assistant message, and return an
   array matching the ChatReply shape (session_id, message, sources, used_challenge_id) exactly
   as shown in the issue's "Response 200" example.

10. app/Http/Controllers/Api/V1/ChatController.php with send() (calls ChatService::respond and
    wraps the result in { "data": {...} } with HTTP 200 — never 500 for AI provider issues, only
    422/403/404 for validation/ownership problems), and optionally sessions()/messages() for the
    nice-to-have history endpoints per the issue file.

11. Wire POST /api/v1/ai/chat (and optionally the two history GET routes) inside the auth:sanctum
    v1 group in routes/api.php.

12. app/Filament/Resources/KnowledgeArticleResource.php — build out the form (title TextInput,
    body Textarea or RichEditor, category TextInput, is_active Toggle) and table columns (title,
    category, is_active, created_at) per the issue's "Filament" section. Hook KnowledgeChunker::
    chunk() to run after create/update (a model 'saved' event listener on KnowledgeArticle is the
    simplest reliable place to put this, wired in a service provider or the model's booted()
    method).

13. Add a seeder (new database/seeders/KnowledgeSeeder.php, or a method inside the shared
    DemoSeeder.php if it already exists on this branch/main — do not remove other devs' seed
    methods) that creates the 5 knowledge articles listed in the issue's "Seed knowledge" table
    via firstOrCreate, and explicitly calls KnowledgeChunker::chunk() for each so chunks exist
    immediately after seeding. Wire it into DatabaseSeeder.php.

14. Write tests/Feature/Api/V1/ChatApiTest.php covering every case in the issue's "Testing
    requirements" section, using Http::fake([...]) for both a mocked successful OpenAI response
    and a simulated failure — do NOT call the real OpenAI API in tests. Also add a focused unit
    test (tests/Unit/KnowledgeChunkerTest.php or similar) asserting a multi-paragraph article
    produces multiple chunk rows in the correct order.

15. Run `php artisan test --filter=ChatApiTest` and the chunker test until fully green, then the
    full `php artisan test` suite to confirm nothing else broke.

16. Manually verify with curl: seed the knowledge base (php artisan db:seed), then POST
    /api/v1/ai/chat with message "What should I do if I miss a day?" and confirm the reply
    references recovery-style content (check the `sources` array), both with and without a real
    OPENAI_API_KEY set locally. Paste the curl output in your summary.

Do not rename any JSON field from SHARED-DATA-CONTRACT.md. Never let this endpoint return 500 due
to an AI provider issue. When finished, list every file created or modified and confirm all tests
pass.
```
