# Issue #7 — Recovery Banner & Flow

| Field | Value |
|-------|-------|
| **Branch** | `mobile/07-recovery-flow` |
| **Base** | `main` |
| **Priority** | P1 — key differentiator for the demo's "punchline" moment |
| **Depends on** | #3, #6 |
| **Estimated time** | 3–4 hours |

---

## Business context

This is the feature that makes Liora Change different from a plain habit tracker: when someone skips or breaks a streak, the app responds with support, not shame. This is explicitly called out as the demo's emotional punchline — it must look and feel intentional, warm, and helpful.

## API endpoints

| Action | Method | Path |
|--------|--------|------|
| Get recovery suggestion | `GET` | `/recovery/suggestion` or `/challenges/{id}/recovery` (confirm exact path in [../05-api-contract.md](../05-api-contract.md)) |
| Acknowledge / restart | `POST` | `/recovery/acknowledge` (or equivalent — confirm in contract) |

Response shape: `RecoveryResponse` in [../teams/SHARED-DATA-CONTRACT.md](../teams/SHARED-DATA-CONTRACT.md) — includes a supportive message and a suggested action (e.g. "restart streak," "adjust difficulty").

## What to build

1. **Recovery banner** (embedded on Home, per Issue #3's placeholder slot) — appears when the dashboard indicates a recent skip/broken streak:
   - Amber (`recovery` token) `AppCard`, warm icon (sprout, heart, or hand — never a warning triangle or red X)
   - Short supportive headline (e.g. "Life happens. Let's pick this back up.")
   - CTA button → opens the full Recovery screen
2. **Recovery screen** — fetched via the recovery endpoint:
   - Supportive message (from API, with a sensible local fallback string if the API call fails or is slow)
   - Suggested action card(s) (e.g. "Restart your streak today" / "Try an easier version of this challenge")
   - Primary CTA to accept the suggestion (calls the acknowledge endpoint) → returns to Home with the banner cleared and a warm confirmation snackbar
   - Secondary/dismiss option ("Maybe later") that just closes the screen without being treated as another failure

## UI/UX design criteria

- [ ] **Zero red, zero warning iconography, zero shaming copy** anywhere in this feature — this is the hardest constraint and the most important one
- [ ] Banner and screen both use the `recovery` amber token consistently (same hex as defined in the design system, not an ad-hoc "similar" orange)
- [ ] Banner has a gentle entrance (fade/slide in) rather than popping in abruptly
- [ ] Recovery screen doesn't feel like a dead-end or punishment page — it has clear, actionable, positive next steps and a way out that isn't "admit defeat"
- [ ] If the AI-generated supportive message (from Issue #8's motivation system, if reused here) is slow to load, a static warm fallback message shows immediately rather than a blank/loading screen
- [ ] Accepting the suggestion gives clear positive feedback (snackbar + banner disappearing) so the user knows something good just happened

## State management

- Dashboard response (Issue #3) should expose a flag like `hasActiveRecoveryPrompt` / `recoverySuggestion` — coordinate the exact field with backend via the shared contract
- `recoveryControllerProvider` — `AsyncNotifier` for fetching the detailed suggestion and an `acknowledge()` method; on success, invalidate `dashboardControllerProvider` so the banner disappears from Home

## Testing requirements (MUST)

- [ ] Widget test: when dashboard data has no recovery flag, the banner does not render on Home
- [ ] Widget test: when the flag is present, the banner renders with the correct amber styling (assert on the color token used, not a literal hex, to catch accidental red usage)
- [ ] Widget test: tapping the banner CTA navigates to the Recovery screen
- [ ] Widget test: Recovery screen shows a fallback message immediately if the API call is pending/slow, then updates when data arrives
- [ ] Widget test: accepting the suggestion calls acknowledge() and, on success, navigates back and the banner condition clears (verify via provider invalidation/refetch trigger)
- [ ] Manual check: trigger a real skip via Issue #6, confirm banner appears on Home and the full flow works

## Definition of Done

- [ ] Banner + full Recovery screen built, zero red/shaming elements anywhere (verified visually)
- [ ] Fallback message covers slow/failed API responses
- [ ] Accept flow clears the banner and confirms warmly
- [ ] All widget tests pass
- [ ] Screenshots attached (banner on Home, Recovery screen — light & dark)
- [ ] PR opened against `main`, linked to Issue #7

---

## 🤖 AI Development Prompt

```text
You are implementing Issue #7 "Recovery Banner & Flow" for the Liora Change Flutter app — the
feature that differentiates this product emotionally: no shame after a skip, only support.

Read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (RecoveryResponse schema and the dashboard field that
  signals a recovery prompt is available — confirm exact field names)
- docs/mvp/05-api-contract.md (recovery endpoint examples)
- docs/mvp/mobile-issues/00-design-system.md (the `recovery` amber token — this is the ONLY
  color allowed for this feature's emphasis color; re-read the "hard rule" about never using red)
- docs/mvp/mobile-issues/07-recovery-flow.md (this issue's full spec)
- Issue #3's home_screen.dart (there is a placeholder/TODO comment marking where this banner
  slot goes) and Issue #6's check_in_sheet.dart (the skip acknowledgment hands off toward this
  feature's entry route)

Implement:

1. lib/models/recovery_response.dart matching the shared contract (supportive message, suggested
   action(s), any identifiers needed for the acknowledge call).

2. lib/features/recovery/data/recovery_repository.dart with:
   - Future<RecoveryResponse> getSuggestion() (or per-challenge variant, matching the confirmed
     API path)
   - Future<void> acknowledge({String? actionId}) → POST to the confirmed acknowledge endpoint

3. lib/features/recovery/application/recovery_controller.dart — AsyncNotifier<RecoveryResponse>
   fetching getSuggestion() on build(), with a fallback: if the fetch is still pending after a
   short delay OR fails, the UI (not the provider) should render a static local fallback message
   (e.g. "Life happens. Let's pick this back up — you've got this.") rather than blocking on the
   network. Add an acknowledge() method that calls the repository and, on success, invalidates
   dashboardControllerProvider from Issue #3.

4. lib/core/widgets/recovery_banner.dart — replace Issue #3's RecoveryBannerPlaceholder with the
   real implementation: an AppCard styled with the `recovery` amber background/accent (from
   AppSemanticColors), a warm icon (use something like Icons.spa, Icons.favorite_outline, or
   Icons.wb_sunny — NOT Icons.warning or Icons.error), a short supportive headline, and a
   PrimaryButton/text-button CTA navigating to '/recovery'. Wrap its appearance in a fade/slide-in
   transition (AnimatedOpacity or a simple implicit animation on first build).

5. Update lib/features/home/presentation/home_screen.dart to render RecoveryBanner conditionally
   based on the dashboard response's recovery flag, replacing the earlier placeholder/TODO.

6. lib/features/recovery/presentation/recovery_screen.dart:
   - Renders the supportive message (from the controller's data once loaded, or the local
     fallback string immediately if loading/error — never a blank screen)
   - Renders suggested action(s) as AppCards with clear, positive labels (e.g. "Restart today",
     "Try an easier version")
   - A PrimaryButton "Let's do this" (or similar warm label) calling
     recoveryController.acknowledge(), showing isLoading, and on success showing
     AppSnackbar.showSuccess with a warm message and navigating back (context.pop() or
     context.go('/home'))
   - A secondary text button "Maybe later" that simply navigates back without calling
     acknowledge and without any negative framing

7. Register/replace the '/recovery' route in lib/router/app_router.dart.

8. Update Issue #6's check_in_sheet.dart skip-acknowledgment CTA to navigate to '/recovery' for
   real (remove the earlier TODO).

9. Write widget tests:
   - test/core/widgets/recovery_banner_test.dart: banner does not render when the dashboard has
     no recovery flag; renders with the recovery-token color (assert against
     AppSemanticColors.recovery, not a literal hex) when the flag is present; tapping it
     navigates to /recovery
   - test/features/recovery/recovery_screen_test.dart: shows the fallback message immediately
     when the controller is loading; updates to the API message once loaded (mocked); tapping
     "Let's do this" calls acknowledge() and shows a success snackbar; tapping "Maybe later" pops
     without calling acknowledge()
   - Add an explicit test/lint-style assertion (e.g. a simple grep-style test or code review note
     in your summary) confirming no Colors.red / warning icon is used anywhere in these new files

10. Run `flutter analyze` and `flutter test`, fix until clean.

11. Manually test end-to-end: trigger a skip via Issue #6's flow against the real backend,
    confirm the banner appears on Home, open it, accept the suggestion, confirm the banner
    disappears and Home refreshes. Take screenshots of the banner and the full Recovery screen in
    both light and dark mode.

This is the most emotionally important feature in the app — triple-check there is no red, no
warning/error iconography, and no negative language ("failed", "broke your streak", "you missed")
anywhere in what you build. Report every file created/modified and confirm test + analyze results.
```
