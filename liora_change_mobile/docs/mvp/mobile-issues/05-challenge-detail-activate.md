# Issue #5 — Challenge Detail + Activate

| Field | Value |
|-------|-------|
| **Branch** | `mobile/05-challenge-detail` |
| **Base** | `main` |
| **Priority** | P0 |
| **Depends on** | #4 |
| **Estimated time** | 4–5 hours |

---

## Business context

After creating a challenge, the member needs a home base for it — progress, history, and (if newly created) an explicit "Activate" step before it starts counting toward streaks. This screen is also where they'll return to check in from (linking to Issue #6).

## API endpoints

| Action | Method | Path |
|--------|--------|------|
| Get challenge detail | `GET` | `/challenges/{id}` |
| Activate challenge | `POST` | `/challenges/{id}/activate` |
| List check-ins for challenge | `GET` | `/challenges/{id}/check-ins` |

Exact fields: `Challenge`, `CheckIn` schemas in [../teams/SHARED-DATA-CONTRACT.md](../teams/SHARED-DATA-CONTRACT.md).

## What to build

1. **Challenge Detail screen**:
   - Header: title, category chip, status badge
   - `ProgressBar` + streak/XP summary for this specific challenge
   - If status is `pending`/`draft` (not yet active): prominent "Activate challenge" `PrimaryButton` — calls `POST /challenges/{id}/activate`, updates status on success
   - If status is `active`: "Check in today" `PrimaryButton` (routes to Issue #6's check-in flow) if not yet checked in today, else a "done" state
   - History section: simple list/calendar-strip of recent check-ins (completed vs skipped, using `success`/`recovery` colors — never red)
   - Empty history state if no check-ins yet ("Your journey starts today")

## UI/UX design criteria

- [ ] Status-dependent primary action (Activate vs Check-in) is unambiguous — only one primary CTA visible at a time, styled with `PrimaryButton`
- [ ] History list/strip uses small circular or pill indicators: `success` color filled for completed days, `recovery` color (amber, not red) for skipped days, neutral outline for future/untouched days
- [ ] Activation has a satisfying success moment (snackbar + brief animation on the status badge changing color) rather than just silently changing text
- [ ] Screen supports back navigation to Challenge List cleanly (`AppBar` back button, standard GoRouter pop)
- [ ] Loading/empty/error states all present per design system
- [ ] Long challenge titles/descriptions wrap gracefully, never overflow the card edge

## State management

- `challengeDetailControllerProvider` (family keyed by challenge id) — `AsyncNotifier<Challenge>` for `GET /challenges/{id}`, plus an `activate()` method calling the activate endpoint and refreshing state
- `checkInHistoryProvider` (family keyed by challenge id) — `FutureProvider<List<CheckIn>>` for the history strip

## Testing requirements (MUST)

- [ ] Widget test: challenge with `pending` status shows "Activate challenge" button, not check-in button
- [ ] Widget test: tapping activate calls the repository and, on success, the screen re-renders with `active` status and the check-in button
- [ ] Widget test: challenge with `active` status and `checkedInToday: false` shows the check-in CTA
- [ ] Widget test: history strip renders completed vs skipped days with visually distinct (tested via key/color property, not literal pixel) indicators
- [ ] Widget test: error state renders `ErrorRetryView`
- [ ] Manual check: activation flow works end-to-end against the real backend

## Definition of Done

- [ ] Detail screen built with status-aware primary action
- [ ] Activation flow works and updates UI immediately on success
- [ ] History strip/list implemented with correct color semantics
- [ ] All widget tests pass
- [ ] Screenshots attached (pending/activate state, active/checkin state, with history — light & dark)
- [ ] PR opened against `main`, linked to Issue #5

---

## 🤖 AI Development Prompt

```text
You are implementing Issue #5 "Challenge Detail + Activate" for the Liora Change Flutter app,
building on Issue #4's Challenge model/repository and the shared theme/widgets from Issue #1.

Read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (Challenge and CheckIn schemas, especially the exact
  status enum values, e.g. pending/active/completed/paused, and check-in status values, e.g.
  completed/skipped)
- docs/mvp/05-api-contract.md (GET /challenges/{id}, POST /challenges/{id}/activate, GET
  /challenges/{id}/check-ins examples)
- docs/mvp/mobile-issues/00-design-system.md (success/recovery color usage — recovery is amber,
  never red; ProgressBar, AppCard components)
- docs/mvp/mobile-issues/05-challenge-detail-activate.md (this issue's full spec)

Implement:

1. Extend lib/features/challenges/data/challenge_repository.dart with:
   - Future<Challenge> getChallenge(String id) → GET /challenges/{id}
   - Future<Challenge> activateChallenge(String id) → POST /challenges/{id}/activate
   - Future<List<CheckIn>> getCheckIns(String challengeId) → GET /challenges/{id}/check-ins
   Add lib/models/check_in.dart matching the shared contract's CheckIn schema if it doesn't exist
   yet.

2. lib/features/challenges/application/challenge_detail_controller.dart — a Riverpod
   AsyncNotifier family (keyed by challengeId) wrapping getChallenge(id), exposing an activate()
   method that calls activateChallenge(id) and updates state with the returned (now-active)
   challenge on success, surfacing errors via AsyncValue.

3. lib/features/challenges/application/check_in_history_provider.dart — a FutureProvider.family
   <List<CheckIn>, String> calling getCheckIns(challengeId).

4. lib/features/challenges/presentation/challenge_detail_screen.dart, accepting a challengeId
   route param, structured as:
   - AppBar with back button and the challenge title
   - Status badge + category chip row
   - ProgressBar showing this challenge's progress percentage (from the Challenge model)
   - Conditional primary action:
     - status == pending/draft → PrimaryButton "Activate challenge" calling
       controller.activate(), showing isLoading during the call, and on success showing
       AppSnackbar.showSuccess plus the badge visibly updating color/text
     - status == active && !checkedInToday → PrimaryButton "Check in today" navigating to the
       check-in route from Issue #6 (e.g. context.push('/challenges/$id/checkin'); add a TODO if
       that route isn't registered yet)
     - status == active && checkedInToday → a "done" success-styled row, no button
     - status == completed/paused → an appropriate read-only state (e.g. a disabled-looking
       summary card), no primary CTA
   - History section: consume check_in_history_provider(challengeId); render a horizontal strip
     (Wrap or a horizontal ListView) of small circular indicators — filled success color for
     completed, filled recovery amber color for skipped, outlined neutral for no data yet. Below
     or beside each, a short date label. If the list is empty, show a friendly EmptyState
     ("Your journey starts today").
   - Wrap the whole body's data-dependent sections in the standard loading/error/success handling
     using LoadingSkeleton and ErrorRetryView per the design system.

5. Register the '/challenges/:id' route in lib/router/app_router.dart, replacing the Issue #1
   placeholder, passing the id param into challenge_detail_controller's family provider.

6. Write widget tests in test/features/challenges/challenge_detail_screen_test.dart covering:
   - pending challenge shows Activate button; tapping it (mocked success) updates to show the
     active/check-in state
   - active + checkedInToday=false shows the check-in CTA
   - active + checkedInToday=true shows the done state, no enabled button
   - history strip renders the correct number of indicators with distinguishable
     completed/skipped styling (assert on widget/key/color properties)
   - error state renders ErrorRetryView

7. Run `flutter analyze` and `flutter test`, fix until clean.

8. Manually verify against the real backend: create a challenge (from Issue #4's flow), activate
   it here, confirm the UI updates immediately without a manual refresh. Take screenshots of the
   pending/activate state and the active/checkin state with a populated history strip, in both
   light and dark mode.

Use only shared widgets/theme tokens — recovery/skipped indicators must use the theme's amber
`recovery` color, never Colors.red or any hardcoded red hex. Report every file created/modified
and confirm test + analyze results.
```
