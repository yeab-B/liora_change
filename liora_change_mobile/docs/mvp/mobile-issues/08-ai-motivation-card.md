# Issue #8 — AI Motivation Card

| Field | Value |
|-------|-------|
| **Branch** | `mobile/08-ai-motivation` |
| **Base** | `main` |
| **Priority** | P1 — MVP-MUST AI feature for the demo |
| **Depends on** | #3, #5 |
| **Estimated time** | 3–4 hours |

---

## Business context

One of the two required AI features. When a member taps "Motivate me," the backend generates a short, personalized motivational message based on their specific challenge (via OpenAI, with a template fallback). This card should feel like a small delightful moment, not a chatbot — it's a one-tap, read-only nudge.

## API endpoints

| Action | Method | Path |
|--------|--------|------|
| Get AI motivation | `POST` | `/ai/motivation` (body: `{ challenge_id }`) |

Response shape: `MotivationResponse` in [../teams/SHARED-DATA-CONTRACT.md](../teams/SHARED-DATA-CONTRACT.md) — includes the generated `message` text and a flag indicating whether it came from AI or the template fallback (e.g. `source: "ai" | "template"`), plus possibly a short tag/mood.

## What to build

**Motivation card**, embedded on Home (replacing Issue #3's placeholder) and optionally on Challenge Detail:

1. Default/idle state: `AppCard` with a "Motivate me ✨" `PrimaryButton` or tappable card, short static label like "Need a boost?"
2. Loading state: skeleton/shimmer inside the card (not a full-screen block) — this should feel light, under ~2-3 seconds typically
3. Loaded state: the generated message displayed prominently (larger, friendly typography), a small subtle sparkle/AI icon indicating it's AI-generated, and a "New message" / refresh action to regenerate
4. Error/fallback: if the API fails entirely, show a warm static fallback message locally (never a broken/error-looking card for this feature) with a retry option

## UI/UX design criteria

- [ ] Card uses `primaryContainer` or a soft gradient tint (still within the green palette) to feel distinct/special compared to plain white cards — this is a "delight" moment
- [ ] Small sparkle/star icon (✨ or `Icons.auto_awesome`) near the message signals "AI-generated" clearly but subtly
- [ ] Message text uses a slightly larger/emphasized style (`titleMedium` or custom) — it should read like a message from a supportive coach, not body copy
- [ ] Tapping "Motivate me" shows a brief, tasteful loading animation inside the card (shimmer or a subtle pulsing icon), never a full-screen spinner for this lightweight action
- [ ] Regenerate action is clearly a secondary, low-emphasis control (icon button, not another full `PrimaryButton`) to avoid visual competition with the main check-in CTA
- [ ] If the response is a template fallback (`source: "template"`) vs AI (`source: "ai"`), the visual treatment can stay identical — the user should never perceive this as "broken," it should feel seamless either way
- [ ] Card animates in smoothly on first load and on message change (fade/cross-fade between old and new message, not an abrupt swap)

## State management

- `motivationControllerProvider` (family by challenge id, or global if simpler) — `AsyncNotifier` with a `generate()`/`refresh()` method calling `POST /ai/motivation`
- Debounce/guard rapid repeated taps on "Motivate me" (disable button while loading)
- Consider a short local cache (e.g. don't refetch if the same challenge's message was fetched in the last N minutes) to avoid unnecessary API/AI cost during demo rehearsal — simple in-memory cache is enough, no need for persistence

## Testing requirements (MUST)

- [ ] Widget test: idle state shows the "Motivate me" affordance
- [ ] Widget test: tapping it shows a loading state inside the card, button disabled during the call
- [ ] Widget test: on success, the message from the mocked response renders with the AI sparkle indicator
- [ ] Widget test: on failure, a static local fallback message renders (never a broken error card)
- [ ] Widget test: regenerate action triggers a new call and cross-fades to the new message
- [ ] Manual check: works end-to-end against the real backend/OpenAI integration; also test with backend's template-fallback path if there's a way to force it (e.g. by disabling AI backend-side) to confirm mobile handles both `source` values identically well

## Definition of Done

- [ ] Motivation card built and integrated into Home (and optionally Challenge Detail)
- [ ] Idle/loading/loaded/fallback states all implemented per criteria
- [ ] All widget tests pass
- [ ] Screenshots attached (idle, loading, loaded with AI message — light & dark)
- [ ] PR opened against `main`, linked to Issue #8

---

## 🤖 AI Development Prompt

```text
You are implementing Issue #8 "AI Motivation Card" for the Liora Change Flutter app — one of the
two required AI features for the hackathon demo.

Read first:
- docs/mvp/09-simple-ai-rag-chat.md (explains the backend AI motivation feature end-to-end,
  including the AI vs template fallback behavior — mobile must treat both outcomes identically)
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (MotivationResponse schema — exact field names for
  message, source, and any mood/tag field)
- docs/mvp/05-api-contract.md (POST /ai/motivation example request/response)
- docs/mvp/mobile-issues/00-design-system.md (primaryContainer usage, spacing, animation
  guidance for cross-fades)
- docs/mvp/mobile-issues/08-ai-motivation-card.md (this issue's full spec)
- The TODO/placeholder left in Issue #3's home_screen.dart marking where this card slot goes

Implement:

1. lib/models/motivation_response.dart matching the shared contract (message: String, source:
   String ('ai' | 'template'), any optional mood/tag field), with fromJson.

2. lib/features/motivation/data/motivation_repository.dart:
   Future<MotivationResponse> getMotivation({required String challengeId}) → POST /ai/motivation
   with body { challenge_id: challengeId } (confirm exact field name against the contract).

3. lib/features/motivation/application/motivation_controller.dart — a Riverpod
   AsyncNotifier.family<MotivationResponse?, String> (keyed by challengeId) starting in a null/
   idle data state (no auto-fetch on build — this is opt-in via a button tap), exposing a
   generate() method that sets loading and calls the repository, and a simple in-memory
   timestamp-based guard so rapid double-taps within ~1 second are ignored while a request is
   in-flight (rely on AsyncValue's isLoading check in the UI as the primary guard).

4. lib/features/motivation/presentation/motivation_card.dart — replacing Issue #3's placeholder,
   built as a StatefulWidget/ConsumerWidget with an AnimatedSwitcher (or AnimatedCrossFade)
   wrapping its inner content, cycling between three visual states:
   - Idle: an AppCard tinted with primaryContainer, containing a short label ("Need a boost?")
     and a PrimaryButton or tappable row labeled "Motivate me ✨" (use Icons.auto_awesome) that
     calls motivationController.generate(challengeId)
   - Loading: the same card shell with a LoadingSkeleton-style shimmer line or two in place of
     the message, and the button disabled/showing isLoading
   - Loaded: the same card shell now showing the message text prominently (use titleMedium or a
     custom slightly-larger style), a small Icons.auto_awesome icon near it, and a low-emphasis
     IconButton (e.g. Icons.refresh) in a corner to regenerate — tapping it calls generate()
     again and the AnimatedSwitcher cross-fades from the old message to the new one
   - On error (the AsyncValue has an error and no cached previous message): render the SAME idle-
     looking card but with a warm static local fallback string (define 2-3 varied local fallback
     strings and pick one, e.g. "Keep going — every step counts." ) instead of any error icon/red
     styling; still offer the "Motivate me" tap to retry
   Note: whether `source` is 'ai' or 'template' from a successful API response, render identically
   — do not show any different styling or label based on that field; it exists for
   backend/analytics purposes only.

5. Wire lib/features/home/presentation/home_screen.dart (from Issue #3) to render
   MotivationCard(challengeId: activeChallenge.id) in place of the earlier placeholder card, only
   when there is an active challenge.

6. (Optional but recommended) Add the same MotivationCard to Issue #5's
   challenge_detail_screen.dart below the progress section.

7. Write widget tests in test/features/motivation/motivation_card_test.dart covering:
   - idle state shows the "Motivate me" affordance and no message
   - tapping it transitions to a loading state, button disabled
   - on a mocked successful response, the message and sparkle icon render, and the state is
     tagged 'ai' or 'template' interchangeably (test both, assert IDENTICAL widget structure
     other than the text content)
   - on a mocked failure, a fallback message renders (assert it is NOT an error-styled widget —
     no red, no error icon)
   - tapping the regenerate icon triggers a new call and updates the displayed message

8. Run `flutter analyze` and `flutter test`, fix until clean.

9. Manually test against the real backend: tap "Motivate me" on a real active challenge, confirm
   a relevant AI-generated message appears within a reasonable time, tap regenerate for a second
   message. Take screenshots of the idle, loading, and loaded states in both light and dark mode.

This feature must always feel delightful and reliable, even when the backend falls back to a
template or fails outright — never expose that as a visible error state. Report every file
created/modified and confirm test + analyze results.
```
