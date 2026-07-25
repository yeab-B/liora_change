# Issue #9 — AI Coach Chat Screen (Simple RAG)

| Field | Value |
|-------|-------|
| **Branch** | `mobile/09-ai-coach-chat` |
| **Base** | `main` |
| **Priority** | P1 — MVP-MUST AI feature for the demo |
| **Depends on** | #1, #2 |
| **Estimated time** | 5–6 hours |

---

## Business context

The second required AI feature: a simple RAG chatbot that answers behavior-change questions using a knowledge base (managed via Filament by the backend team). This is a real chat interface — the demo's "wow" moment showing the app can give grounded, relevant answers, not generic chatbot fluff.

## API endpoints

| Action | Method | Path |
|--------|--------|------|
| Start/continue chat session | `POST` | `/chat/sessions` (start) |
| Send message | `POST` | `/chat/sessions/{id}/messages` |
| Get session history | `GET` | `/chat/sessions/{id}` or `/chat/sessions/{id}/messages` |

Exact schemas: `ChatSession`, `ChatMessage`, `ChatReply`, `ChatSource` in [../teams/SHARED-DATA-CONTRACT.md](../teams/SHARED-DATA-CONTRACT.md). Note `ChatReply` likely includes `sources` (the knowledge articles used) — surfacing these builds trust and is a nice demo beat.

## What to build

**Coach Chat screen:**

1. Standard chat UI: scrollable message list (oldest → newest, auto-scroll to bottom on new message), input field + send button pinned at bottom
2. `ChatBubble` component (already scaffolded in design system): user messages right-aligned with `primary`-tinted background, assistant messages left-aligned with `surfaceVariant` background, both with a friendly avatar/icon
3. Assistant "typing"/thinking indicator (animated dots or pulsing bubble) while waiting for a reply
4. If the reply includes `sources` (knowledge articles referenced), show them as small tappable chips/expandable footer under that message ("Based on: Atomic Habits basics") — builds trust, subtle, not overwhelming
5. Empty state on first entry: a friendly greeting from "Coach" + 2-3 suggested starter questions as tappable chips (e.g. "How do I build a streak?", "I keep skipping — help?") that pre-fill and send the input
6. Input field: multiline-capable, send button disabled when empty, `Enter`/send triggers submit, disabled while awaiting a reply (queue is not required for MVP — one in-flight message at a time is fine)

## UI/UX design criteria

- [ ] Chat bubbles use rounded shapes (per design system radius), clear but calm color contrast between user/assistant — no jarring color clash
- [ ] Typing indicator feels alive (animated, not a static "Loading...") but subtle
- [ ] Source chips are visually secondary (small, muted `surfaceVariant`/outline style) — informative, not distracting from the main answer text
- [ ] Starter question chips on the empty state are inviting and clearly tappable (pill-shaped, `primaryContainer`-ish tint)
- [ ] Auto-scroll to the latest message on send/receive, but don't fight the user if they've manually scrolled up to read history (only auto-scroll if already near the bottom)
- [ ] Keyboard handling: input stays visible above the keyboard, message list resizes correctly (`resizeToAvoidBottomInset` / `SafeArea` handled)
- [ ] Long messages wrap correctly within the bubble's max width (cap bubble width at ~75-80% of screen width)
- [ ] Network/error case: a failed send shows an inline retry affordance on that specific message bubble, not a full-screen error

## State management

- `chatSessionControllerProvider` — manages session creation (lazily create a session on first message if none exists) and holds the ordered list of `ChatMessage`
- `sendMessageProvider`/method — optimistically appends the user's message to the list immediately (so it doesn't feel laggy), then appends the assistant's typing placeholder, then replaces it with the real reply (or an error state) once the API responds

## Testing requirements (MUST)

- [ ] Widget test: empty state shows greeting + starter question chips; tapping a chip sends it as a message
- [ ] Widget test: sending a message immediately shows the user's bubble (optimistic) and a typing indicator
- [ ] Widget test: on a mocked successful reply, the assistant bubble renders with the message text and, if present, source chips
- [ ] Widget test: on a mocked failure, the specific message shows an inline retry option, and the rest of the conversation is unaffected
- [ ] Widget test: input field's send button is disabled when the text field is empty and while awaiting a reply
- [ ] Manual check: full conversation flow works against the real backend, including a question that should trigger a source citation

## Definition of Done

- [ ] Chat screen built with all states above (empty/typing/success/error-per-message)
- [ ] Source citation UI implemented
- [ ] Keyboard/scroll behavior correct on a small device
- [ ] All widget tests pass
- [ ] Screenshots attached (empty state with starters, active conversation with sources — light & dark)
- [ ] PR opened against `main`, linked to Issue #9

---

## 🤖 AI Development Prompt

```text
You are implementing Issue #9 "AI Coach Chat Screen (Simple RAG)" for the Liora Change Flutter
app — the second required AI feature for the hackathon demo.

Read first:
- docs/mvp/09-simple-ai-rag-chat.md (explains the backend's simple RAG implementation end-to-end
  — MySQL knowledge chunks + OpenAI — so you understand what kind of answers/sources to expect)
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (ChatSession, ChatMessage, ChatReply, ChatSource schemas
  — exact field names, especially how sources are nested in a reply)
- docs/mvp/05-api-contract.md (chat endpoint request/response examples)
- docs/mvp/mobile-issues/00-design-system.md (ChatBubble component spec, colors, radius)
- docs/mvp/mobile-issues/09-ai-coach-chat.md (this issue's full spec)

Implement:

1. lib/models/chat_session.dart, chat_message.dart, chat_source.dart matching the shared
   contract exactly, with fromJson. A ChatMessage should have at minimum: id, role ('user' |
   'assistant'), text, optional List<ChatSource> sources, optional sendStatus (a LOCAL-only enum
   you add: sending | sent | failed — not part of the API contract, used for optimistic UI).

2. lib/features/coach/data/chat_repository.dart:
   - Future<ChatSession> startSession() → POST /chat/sessions
   - Future<ChatMessage> sendMessage({required String sessionId, required String text}) → POST
     /chat/sessions/{id}/messages, returning the ASSISTANT's reply message (parse whatever shape
     the contract defines for the response, which should include the reply text and sources)
   - Future<List<ChatMessage>> getHistory(String sessionId) → GET
     /chat/sessions/{id}/messages (if session resumption is in scope; otherwise this can just
     return an empty list for a fresh session — check the contract)

3. lib/features/coach/application/chat_controller.dart — a Riverpod
   StateNotifier<ChatState>/Notifier managing: sessionId (nullable, created lazily), messages
   (List<ChatMessage>), isWaitingForReply (bool). Method sendMessage(String text):
   - if no sessionId yet, call startSession() first
   - immediately append a local ChatMessage(role: user, text: text, sendStatus: sending) to the
     list (optimistic UI) and set isWaitingForReply = true
   - call chat_repository.sendMessage(...); on success, mark that user message sendStatus: sent
     and append the returned assistant ChatMessage to the list; on failure, mark the user message
     sendStatus: failed and do NOT append an assistant message
   - set isWaitingForReply = false when done
   Add a retrySend(messageId) method that re-attempts sending a message currently marked failed.

4. lib/core/widgets/chat_bubble.dart — a ChatBubble(message) widget: right-aligned with
   primary-tinted background + onPrimary text for role == user, left-aligned with surfaceVariant
   background + onSurface text for role == assistant, rounded corners per design system, max
   width ~75-80% of screen width (use FractionallySizedBox or a manual constraint), a small
   assistant avatar icon (e.g. Icons.spa or a simple circular icon) on assistant bubbles. If
   message.sendStatus == failed, show a small inline "Failed to send · Retry" text/button below
   the bubble that calls the retry callback passed in.

5. lib/features/coach/presentation/coach_chat_screen.dart:
   - AppBar titled "Coach"
   - A ListView (reversed or with a ScrollController tracking near-bottom state) rendering
     ChatBubble for each message in chatController.messages, plus a "typing" indicator bubble
     (simple animated dots, e.g. three AnimatedOpacity-pulsing dots in a surfaceVariant bubble)
     appended at the end when isWaitingForReply is true
   - When messages is empty: render an empty/greeting state instead of the list — a friendly
     "Coach" avatar + greeting text + 2-3 starter question chips (pill-shaped, primaryContainer
     tint) that, when tapped, call chatController.sendMessage(thatQuestionText) directly
   - Bottom-pinned input row: a multiline-capable TextField + a send IconButton/PrimaryButton
     that's disabled when the text is empty OR isWaitingForReply is true; submitting calls
     sendMessage(text) and clears the field
   - Auto-scroll to bottom on new message ONLY if the user was already near the bottom before the
     new message arrived (track scroll position; if they've scrolled up to read history, don't
     yank them back down)
   - Wrap in SafeArea and ensure the input stays above the keyboard (resizeToAvoidBottomInset)

6. If a message has non-empty sources, render them under the assistant's ChatBubble as small
   muted chips (e.g. "Based on: {source.title}") — tappable is a nice-to-have (could show a
   simple dialog/snackbar with more detail) but not required for MVP.

7. Register/replace the '/coach' route in lib/router/app_router.dart, and ensure there's a way
   to reach it from Home (e.g. a nav bar/icon button) if one doesn't already exist — add a simple
   entry point if needed.

8. Write widget tests in test/features/coach/coach_chat_screen_test.dart covering:
   - empty state renders greeting + starter chips; tapping a chip triggers sendMessage with that
     chip's text
   - sending a message immediately shows the user's bubble and a typing indicator (before the
     mocked response resolves)
   - on a mocked successful reply with sources, the assistant bubble and source chips render
   - on a mocked failure, the user's message bubble shows the failed/retry affordance and no
     assistant bubble is added; tapping retry re-attempts and can succeed
   - send button is disabled when the input is empty or while awaiting a reply

9. Run `flutter analyze` and `flutter test`, fix until clean.

10. Manually test against the real backend: ask a real behavior-change question (e.g. "How do I
    build a streak?"), confirm a grounded answer with source citations appears, and test a network
    failure (turn off Wi-Fi mid-send) to confirm the retry affordance works. Take screenshots of
    the empty state with starter chips and an active conversation with source citations, in both
    light and dark mode.

Report every file created/modified and confirm test + analyze results.
```
