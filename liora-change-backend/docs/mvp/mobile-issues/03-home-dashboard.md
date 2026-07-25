# Issue #3 — Home / Dashboard Screen

| Field | Value |
|-------|-------|
| **Branch** | `mobile/03-home-dashboard` |
| **Base** | `main` |
| **Priority** | P0 |
| **Depends on** | #1, #2 |
| **Estimated time** | 5–6 hours |

---

## Business context

Home is the app's emotional center — the "daily return" moment. A member opens the app and should immediately feel their progress (streak, XP, level) and see what to do next (active challenge, check in today). This is the screen judges will see most during the demo.

## API endpoints

| Action | Method | Path |
|--------|--------|------|
| Dashboard summary | `GET` | `/dashboard` |

Response shape: see `DashboardResponse` in [../teams/SHARED-DATA-CONTRACT.md](../teams/SHARED-DATA-CONTRACT.md) — includes user level/XP, streak info, active challenge(s), today's check-in status, and (per Issue #8) a motivation slot.

## What to build

1. **Home screen** with, top to bottom:
   - Greeting header ("Good morning, Sam") + level/XP summary (small `AppCard` or inline row)
   - `StreakBadge` — current streak count, prominent
   - Active challenge `AppCard` — title, `ProgressBar`, "Check in today" `PrimaryButton` (routes to check-in flow, Issue #6) if not yet checked in today, or a "Checked in ✓" state (disabled/success look) if already done
   - "Motivate me" section slot — placeholder card for now, filled in by Issue #8
   - Recovery banner slot — appears conditionally, filled in by Issue #7
   - If no active challenge: `EmptyState` prompting "Start your first challenge" → routes to Challenge Create (Issue #4)
2. Pull-to-refresh (`RefreshIndicator`) re-fetches `/dashboard`
3. Skeleton loading state on first load (`LoadingSkeleton` cards in the same layout as loaded content, not a spinner)

## UI/UX design criteria

- [ ] Layout uses `AppCard` consistently — streak, active challenge, motivation are all cards with the same radius/padding/shadow language
- [ ] Streak number animates on change (`TweenAnimationBuilder`) rather than snapping — e.g. when returning from a check-in
- [ ] Progress bar uses `primaryContainer`/`primary` fill, rounded ends, animates its fill (`AnimatedContainer`/`TweenAnimationBuilder`) rather than jumping instantly
- [ ] "Check in today" button is large, obviously the primary action on the screen (visual hierarchy — it should be the most prominent tappable element)
- [ ] Already-checked-in state looks distinctly "done" (e.g. success-colored check icon + label) rather than just a disabled gray button
- [ ] Empty state (no active challenge) has a friendly illustration/icon + one clear CTA — never just blank space
- [ ] Content max-width capped and centered on tablet-sized screens (per design system §6)
- [ ] Pull-to-refresh uses the theme's primary color for the spinner

## State management

- `dashboardControllerProvider` — `AsyncNotifier<DashboardResponse>` fetching `/dashboard` on init and exposing a `refresh()` method for pull-to-refresh
- Re-fetch on return to Home after check-in (Issue #6) so streak/progress reflect the latest state — use `ref.invalidate` or a simple `refresh()` call in the navigation callback

## Testing requirements (MUST)

- [ ] Widget test: loading state renders skeleton cards (not a raw spinner) while the provider is loading
- [ ] Widget test: with a mocked `DashboardResponse` containing an active challenge and `checkedInToday: false`, the "Check in today" button is enabled and visible
- [ ] Widget test: with `checkedInToday: true`, the button shows the "done" state instead
- [ ] Widget test: with no active challenge, the `EmptyState` with CTA renders instead of a challenge card
- [ ] Widget test: an API error renders `ErrorRetryView` and tapping "Try again" re-triggers the fetch
- [ ] Manual check: pull-to-refresh visually works and updates data

## Definition of Done

- [ ] Home screen built exactly per design criteria above
- [ ] All 4 states (loading/empty/error/success) implemented and tested
- [ ] Streak/progress animate rather than snap
- [ ] Responsive on small + large phone widths, light + dark mode
- [ ] All widget tests pass
- [ ] Screenshots attached to PR (loading, empty, populated — light & dark)
- [ ] PR opened against `main`, linked to Issue #3

---

## 🤖 AI Development Prompt

```text
You are implementing Issue #3 "Home / Dashboard Screen" for the Liora Change Flutter app, built
on top of Issue #1 (theme + shared widgets) and Issue #2 (auth + router).

Read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (the DashboardResponse schema — exact field names,
  including streak, xp/level, activeChallenge, checkedInToday, and any motivation field)
- docs/mvp/05-api-contract.md (GET /dashboard example response)
- docs/mvp/mobile-issues/00-design-system.md (colors/components — reuse AppCard, StreakBadge,
  ProgressBar, EmptyState, LoadingSkeleton, ErrorRetryView from lib/core/widgets)
- docs/mvp/mobile-issues/03-home-dashboard.md (this issue's full spec)

Implement:

1. lib/models/dashboard_response.dart (and any nested models it needs, e.g. ActiveChallenge,
   StreakInfo) matching SHARED-DATA-CONTRACT.md exactly, with fromJson.

2. lib/features/home/data/dashboard_repository.dart — Future<DashboardResponse> getDashboard()
   calling GET /dashboard via the shared Dio client.

3. lib/features/home/application/dashboard_controller.dart — a Riverpod AsyncNotifier
   <DashboardResponse> that fetches on build() and exposes a refresh() method (calls
   ref.invalidateSelf() or re-fetches and updates state) for pull-to-refresh.

4. lib/features/home/presentation/home_screen.dart implementing this layout top to bottom inside
   a RefreshIndicator + SingleChildScrollView (respecting SafeArea and the max-width-on-tablet
   rule from the design system):
   - Greeting row: "Good [morning/afternoon/evening], {name}" computed from current time, plus
     compact level/XP text next to it
   - StreakBadge widget bound to dashboard.streak (with a TweenAnimationBuilder<int> wrapping the
     displayed number so changes animate rather than snap)
   - If dashboard.activeChallenge is present: an AppCard showing the challenge title, a
     ProgressBar (wrapped similarly with a tween for animated fill) showing progress, and:
       - if !dashboard.checkedInToday: a full-width PrimaryButton "Check in today" that navigates
         to the check-in route for that challenge (context.push('/challenges/${id}/checkin') —
         align the exact route name with whatever Issue #6 defines, add a TODO comment if the
         route doesn't exist yet)
       - if checkedInToday: a "success" styled row (check-circle icon in the success color +
         "Checked in today" label) instead of the button
   - A placeholder AppCard with a "Motivate me" title and a TODO comment noting Issue #8 fills
     this in
   - If dashboard.activeChallenge is null: render the EmptyState widget instead of the challenge
     card, with title "Start your first challenge", subtitle, and a CTA button navigating to
     '/challenges/create'
   - Leave a named Slot/child widget for a recovery banner (e.g. a
     `if (dashboard.showRecoveryBanner) const RecoveryBannerPlaceholder()`) with a TODO noting
     Issue #7 implements it — do not build the actual banner here.

5. Handle the controller's AsyncValue states in the screen:
   - loading (and no previous data): render 2-3 LoadingSkeleton-shaped cards in the same
     approximate layout instead of a bare spinner
   - error: render ErrorRetryView with the error message and an onRetry that calls
     ref.refresh(dashboardControllerProvider) or controller.refresh()
   - data: render the layout described in step 4

6. Wire pull-to-refresh: RefreshIndicator's onRefresh calls the controller's refresh() and awaits
   it; use the theme's primary color for the indicator.

7. Write widget tests in test/features/home/home_screen_test.dart using a mocked/fake
   DashboardRepository (via Riverpod's ProviderScope overrides) covering:
   - loading state shows skeletons
   - success with an active challenge + checkedInToday=false shows the enabled check-in button
   - success with checkedInToday=true shows the "done" state, no enabled check-in button
   - success with no active challenge shows EmptyState with correct CTA text
   - error state shows ErrorRetryView and tapping retry calls the repository again

8. Run `flutter analyze` and `flutter test`, fix until clean.

9. Manually verify against the real or mocked backend: check dashboard renders correctly, pull
   to refresh works, and take screenshots of the loading, empty, and populated states in both
   light and dark mode.

Use only shared widgets/theme tokens — no new hardcoded colors. List every file created/modified
and confirm test + analyze are clean in your final summary.
```
