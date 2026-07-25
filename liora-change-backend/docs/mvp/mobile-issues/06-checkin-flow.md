# Issue #6 — Check-in Flow (Complete / Skip)

| Field | Value |
|-------|-------|
| **Branch** | `mobile/06-checkin-flow` |
| **Base** | `main` |
| **Priority** | P0 |
| **Depends on** | #5 |
| **Estimated time** | 4–5 hours |

---

## Business context

This is the daily core loop moment — the single most important interaction in the app. It must feel fast (one or two taps), rewarding when completed, and non-judgmental when skipped. XP and streak updates should feel earned, not just a number changing.

## API endpoints

| Action | Method | Path |
|--------|--------|------|
| Submit check-in | `POST` | `/challenges/{id}/check-ins` |

Request body: `{ status: "completed" | "skipped", note?: string }` — confirm exact field names against [../teams/SHARED-DATA-CONTRACT.md](../teams/SHARED-DATA-CONTRACT.md) `CheckIn` schema. Response includes the updated streak/XP delta — see `CheckInResponse`.

## What to build

**Check-in screen/sheet** (can be a full screen or a modal bottom sheet — bottom sheet is recommended for speed):

1. Challenge title + "How did today go?"
2. Two large, clearly differentiated action buttons:
   - **"I did it!"** — `success` green, filled, with a celebratory icon
   - **"Skip today"** — neutral/outlined, `secondary` color, *not* red, calm tone
3. Optional short note field (collapsed by default, "Add a note" expander)
4. On submit:
   - **Completed** → success animation (confetti-lite or a scale/check burst), then shows the XP earned and new streak count with an animated count-up, then a "Nice!" `PrimaryButton` returns to Home/Detail
   - **Skipped** → calm acknowledgment screen ("No worries — tomorrow's a fresh start") that hands off directly into the Recovery flow (Issue #7) rather than just closing
5. After either outcome, navigating back refreshes Home/Detail data (invalidate `dashboardControllerProvider` and `challengeDetailControllerProvider`)

## UI/UX design criteria

- [ ] The two action buttons are equally sized/prominent in layout (no visual bias suggesting skip is "bad") but color-differentiated (`success` vs neutral `secondary`) — the color communicates outcome, not moral judgment
- [ ] Zero use of red, warning triangles, or negative language ("failed", "broke your streak") anywhere in this flow
- [ ] Completion celebration is snappy (under ~1.5s animation) — doesn't block the user, has a clear way to continue
- [ ] XP/streak count-up animates (`TweenAnimationBuilder`) rather than snapping
- [ ] Note field is optional and clearly marked as such; keyboard doesn't cover buttons when it's expanded and focused
- [ ] Submit buttons show `isLoading` and are disabled during the request; double-tap protected (can't submit twice)
- [ ] If presented as a bottom sheet, it's tall enough to be readable but dismissible via drag/back button without accidentally submitting

## State management

- `checkInControllerProvider` (family by challenge id) — `AsyncNotifier`/state holding submit status, exposing `submit(status, note)` calling `POST /challenges/{id}/check-ins`
- On success, invalidate `dashboardControllerProvider`, `challengeDetailControllerProvider(id)`, and `checkInHistoryProvider(id)` so returning screens show fresh data without a manual pull-to-refresh

## Testing requirements (MUST)

- [ ] Widget test: tapping "I did it!" calls the repository with `status: completed` and the optional note if entered
- [ ] Widget test: tapping "Skip today" calls the repository with `status: skipped`
- [ ] Widget test: submit buttons disable during `isLoading` and re-enable (or navigate away) after resolution
- [ ] Widget test: on success, the completion view shows the XP/streak values from the mocked response
- [ ] Widget test: a failed submission (mocked error) shows an error message and does not silently drop the request
- [ ] Manual check: after check-in, returning to Home shows the updated streak without manual refresh

## Definition of Done

- [ ] Check-in screen/sheet built per criteria above, both outcomes implemented
- [ ] XP/streak animate on success; skip flows into Recovery (Issue #7) hook
- [ ] Downstream providers invalidated so Home/Detail auto-refresh
- [ ] All widget tests pass
- [ ] Screenshots attached (pre-submit, completed celebration, skipped acknowledgment — light & dark)
- [ ] PR opened against `main`, linked to Issue #6

---

## 🤖 AI Development Prompt

```text
You are implementing Issue #6 "Check-in Flow (Complete/Skip)" for the Liora Change Flutter app,
the most important daily interaction in the product.

Read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (CheckIn request schema and CheckInResponse — exact
  field names for status enum ["completed","skipped"], note, and the returned streak/XP delta
  fields)
- docs/mvp/05-api-contract.md (POST /challenges/{id}/check-ins example)
- docs/mvp/mobile-issues/00-design-system.md (success vs recovery color rules — this flow must
  NEVER use red or shaming language)
- docs/mvp/mobile-issues/06-checkin-flow.md (this issue's full spec)

Implement:

1. lib/models/check_in_response.dart matching the shared contract's response shape (status,
   updated streak count, xpEarned or similar, any newBadges array if present).

2. Extend lib/features/challenges/data/challenge_repository.dart with:
   Future<CheckInResponse> submitCheckIn({required String challengeId, required String status,
   String? note}) → POST /challenges/{id}/check-ins with body {status, note} (adjust field names
   to match the exact contract).

3. lib/features/checkins/application/check_in_controller.dart — a Riverpod
   AsyncNotifier.family<CheckInResponse?, String> (keyed by challengeId) with a submit(status,
   note) method calling the repository and, on success, invalidating
   dashboardControllerProvider, challengeDetailControllerProvider(challengeId), and
   checkInHistoryProvider(challengeId) via ref.invalidate so those screens refresh automatically
   when revisited.

4. lib/features/checkins/presentation/check_in_sheet.dart — implement as a modal bottom sheet
   (showModalBottomSheet, isScrollControlled: true, shape with the design system's card radius on
   top corners) containing:
   - Challenge title + "How did today go?" heading
   - A Row (or two full-width stacked buttons on narrow screens) with:
     - "I did it!" — a filled button using the theme's `success` color (from the
       AppSemanticColors extension built in Issue #1), with a check/trophy icon
     - "Skip today" — an OutlinedButton/SecondaryButton style, neutral tone, calm label — do NOT
       use red or a warning icon
   - A collapsible "Add a note (optional)" section revealing a TextField when tapped
   - Both buttons wire to check_in_controller.submit(status, note), show isLoading (disable both
     buttons while either is submitting), and are guarded against double-submission

5. On successful "completed" submission, transition the sheet's content (do not close and reopen
   — animate within the same sheet, e.g. via AnimatedSwitcher) to a celebration view:
   - A brief check/celebration icon animation (a simple ScaleTransition or a Lottie-free
     AnimatedScale burst is sufficient — do not add heavy new dependencies just for this)
   - Animated count-up (TweenAnimationBuilder<int>) of the new streak count and XP earned from
     the response
   - A PrimaryButton "Nice!" that pops the sheet and lets the underlying screen's providers
     (already invalidated) refresh naturally

6. On successful "skipped" submission, transition to a calm acknowledgment view: a supportive
   headline (e.g. "No worries — tomorrow's a fresh start"), brief supportive body text, and a
   PrimaryButton that pops the sheet and navigates toward the Recovery entry point (for now,
   context.push('/recovery') or equivalent — add a TODO noting Issue #7 defines the actual
   recovery screen/route; wire it up for real once that route exists).

7. On a submission failure (mocked or real error), show an inline error message within the sheet
   (not a separate screen) and re-enable the buttons so the user can retry.

8. Wire the entry point: in Issue #5's challenge_detail_screen.dart (and/or Issue #3's
   home_screen.dart), change the "Check in today" button's onPressed to open this bottom sheet
   via showModalBottomSheet(...) passing the challengeId, replacing any earlier TODO/stub
   navigation.

9. Write widget tests in test/features/checkins/check_in_sheet_test.dart covering:
   - tapping "I did it!" calls submit with status 'completed' and includes a note if one was
     typed
   - tapping "Skip today" calls submit with status 'skipped'
   - both buttons disable during isLoading
   - on a mocked successful "completed" response, the celebration view renders with the correct
     streak/XP numbers from the response
   - on a mocked successful "skipped" response, the calm acknowledgment view renders (assert no
     red color, no negative-language strings like "failed")
   - on a mocked error, an inline error message renders and buttons re-enable

10. Run `flutter analyze` and `flutter test`, fix until clean.

11. Manually test end-to-end against the real backend: check in complete, verify Home's streak
    updates without a manual refresh; check in skip, verify it hands off toward the recovery
    entry point. Take screenshots of the pre-submit sheet, the completion celebration, and the
    skip acknowledgment, in both light and dark mode.

This flow is the emotional core of the app — no red, no "failed" language, no shaming. Report
every file created/modified and confirm test + analyze results.
```
