# Issue #10 — Profile Screen, Polish, Responsiveness & Full QA

| Field | Value |
|-------|-------|
| **Branch** | `mobile/10-profile-polish-qa` |
| **Base** | `main` |
| **Priority** | P1 — must land before demo day |
| **Depends on** | All previous issues (#1–#9) |
| **Estimated time** | 5–6 hours |

---

## Business context

This is the final pass before the demo: build the Profile screen (badges/XP summary, logout), then sweep the entire app for visual consistency, responsiveness, dark mode correctness, and interaction polish. Judges notice rough edges — this issue exists specifically to remove them.

## API endpoints

| Action | Method | Path |
|--------|--------|------|
| Get profile / gamification summary | `GET` | `/profile` or `/dashboard` (may reuse dashboard data — confirm in [../05-api-contract.md](../05-api-contract.md)) |
| List badges | `GET` | `/badges` (confirm exact path) |
| Logout | `POST` | `/auth/logout` (already built in Issue #2 — reuse) |

## Part A — Profile screen (new)

1. User info header: name, email, level/XP summary, join date (optional)
2. Badges section: grid of earned badges (`BadgeIcon` + name), locked/unearned badges shown dimmed/grayscale with a lock icon (not hidden — shows progression goals)
3. Stats summary: total challenges, current streak, longest streak (whatever the API exposes)
4. "Log out" `SecondaryButton` (or a clearly separated destructive-but-calm action — muted tone, not aggressive red; a confirmation dialog before logging out)

## Part B — Full app polish pass (the real point of this issue)

Go through **every screen from Issues #1–#9** and verify/fix:

1. **Color audit** — grep the codebase for hardcoded `Color(0x...)`/`Colors.` usage outside `lib/core/theme/`; replace every instance with a theme token. Zero exceptions.
2. **Component audit** — verify every card/button/badge uses the shared widgets from `lib/core/widgets/`, not a one-off `Container`/`ElevatedButton` copy.
3. **Dark mode sweep** — open every screen in dark mode; fix any low-contrast text, invisible icons, or accidental pure-white containers that broke through.
4. **Responsiveness sweep** — test every screen at a small phone width (~360px) and a larger one (~430px+), and on a tablet-sized simulator; fix any overflow, clipping, or awkward stretching.
5. **Text scale sweep** — set OS text scale to ~130% and check every screen for clipped/overlapping text.
6. **Loading/empty/error states audit** — confirm every data-driven screen has all 4 states (per design system §8 checklist), not just the happy path.
7. **Navigation audit** — confirm every screen is reachable and has a working back action; no dead-end stub screens remain from Issue #1's placeholders.
8. **Animation/interactivity pass** — confirm buttons show pressed feedback, loading spinners appear during network calls, and streak/XP numbers animate rather than snap, consistently across screens.
9. **Empty/first-run experience** — verify a brand-new user's first app open (no challenges, no check-ins, no chat history) looks intentional and inviting everywhere, not broken.
10. **Performance sanity check** — no obvious jank scrolling the chat or challenge lists; images/icons load without flicker.

## UI/UX design criteria (for the Profile screen itself)

- [ ] Badge grid uses consistent card sizing (`AppCard`), earned vs locked visually distinct via opacity/desaturation, not color alone (locked also has a small lock icon for accessibility)
- [ ] Logout requires a confirmation dialog ("Are you sure you want to log out?") styled with theme colors, not a raw default `AlertDialog`
- [ ] Profile screen supports pull-to-refresh like Home
- [ ] All Part A criteria from the shared design system checklist (§8) apply here too

## Testing requirements (MUST)

- [ ] Widget test: Profile screen renders user info, badge grid (earned + locked), and stats from a mocked response
- [ ] Widget test: tapping "Log out" shows a confirmation dialog; confirming calls the logout flow and navigates to `/login`; canceling does nothing
- [ ] Widget test: loading/empty/error states for Profile itself
- [ ] **Regression pass:** re-run the FULL test suite (`flutter test`) — all tests from Issues #1–#9 must still pass after this issue's changes
- [ ] Manual QA: complete the "Manual QA pass" checklist from [README.md](./README.md) across the entire app, not just Profile

## Definition of Done

- [ ] Profile screen built per criteria above
- [ ] Full polish pass complete: color audit, component audit, dark mode sweep, responsiveness sweep, text scale sweep, states audit, navigation audit, animation pass — all clean
- [ ] `flutter analyze` shows zero warnings/errors app-wide
- [ ] Full `flutter test` suite passes (all issues combined)
- [ ] Screenshots attached: Profile screen (light & dark), plus a "before/after" note on anything fixed during the polish pass
- [ ] PR opened against `main`, linked to Issue #10 — this should be the last mobile PR before demo day

---

## 🤖 AI Development Prompt

```text
You are implementing Issue #10 "Profile Screen, Polish, Responsiveness & Full QA" for the Liora
Change Flutter app — the final issue before demo day. This has two parts: build a new Profile
screen, then perform a full-app consistency and quality sweep across everything built in Issues
#1–#9.

Read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (profile/badges/stats schema — confirm exact field
  names for whatever endpoint exposes badges and stats)
- docs/mvp/05-api-contract.md (profile/badges endpoint examples)
- docs/mvp/mobile-issues/00-design-system.md (the full checklist in section 8 — this is your
  audit checklist for Part B)
- docs/mvp/mobile-issues/10-profile-polish-qa.md (this issue's full spec)
- docs/mvp/mobile-issues/README.md (the "Manual QA pass" checklist at the bottom)

PART A — Build the Profile screen:

1. lib/models/badge.dart and any profile summary model needed, matching the shared contract.

2. lib/features/profile/data/profile_repository.dart with methods to fetch the profile/summary
   data and badges list from whatever endpoints the contract defines (reuse the existing
   dashboard repository/model if the data is already available there instead of duplicating a
   call).

3. lib/features/profile/application/profile_controller.dart — AsyncNotifier fetching profile
   data + badges.

4. lib/features/profile/presentation/profile_screen.dart:
   - Header: avatar/initials circle, name, email, level/XP line
   - Stats row: total challenges, current streak, longest streak as small AppCards or a stat-row
     widget
   - Badges section: a GridView of badge items — earned badges full-color/opacity with their
     icon and name; locked/unearned badges rendered at reduced opacity (e.g. 0.4) WITH a small
     lock icon overlay (do not rely on opacity alone for the distinction, for accessibility)
   - "Log out" as a SecondaryButton (muted styling, not red/aggressive), which on tap shows a
     themed confirmation AlertDialog ("Are you sure you want to log out?" / Cancel / Log out);
     confirming calls the existing authController.logout() from Issue #2 and navigates to /login
   - Standard loading/empty/error states and pull-to-refresh, consistent with Home's pattern
   - Register/replace the '/profile' route

5. Write widget tests in test/features/profile/profile_screen_test.dart: renders mocked data
   correctly (including a mix of earned and locked badges), logout confirmation dialog
   flow (cancel vs confirm), and standard loading/error state coverage.

PART B — Full app polish and QA sweep. Go through EVERY file created in Issues #1 through #9 and:

1. Search the entire lib/ directory for hardcoded colors: grep for `Color(0x`, `Colors.red`,
   `Colors.green`, `Colors.blue`, etc. OUTSIDE of lib/core/theme/app_colors.dart. Replace every
   match with the correct theme token (Theme.of(context).colorScheme.* or the
   AppSemanticColors extension). There should be ZERO matches remaining outside the theme files
   when you're done. List what you found and fixed.

2. Search for raw Container/ElevatedButton/Card usage that duplicates what a shared widget
   (PrimaryButton, SecondaryButton, AppCard, etc.) already provides, and replace with the shared
   widget for consistency. List what you found and fixed.

3. Manually (via running the app in a simulator, or by careful code review of every screen's
   ThemeData usage) verify dark mode: check each screen built in Issues #1-#9 for any hardcoded
   white/black background that doesn't flip with the theme, or low-contrast text. Fix any found.

4. Review every screen for responsiveness: ensure list/grid layouts use MediaQuery/LayoutBuilder
   where needed to avoid overflow on a ~360px-wide device, and that content is capped/centered on
   tablet widths per the design system's rule. Fix any found overflow (wrap Row children in
   Expanded/Flexible, use Wrap instead of Row where content can vary in length, etc.).

5. Verify every data-driven screen (Home, Challenge List, Challenge Detail, Coach Chat, Profile)
   implements all 4 states: loading (skeleton), empty, error (with retry), and success. Fix any
   screen that's missing one.

6. Verify GoRouter has no remaining dead-end placeholder screens from Issue #1 that should have
   been replaced by later issues — confirm every route added in app_router.dart points to its
   real implementation.

7. Verify interactive feedback is consistent: PrimaryButton/SecondaryButton show pressed and
   loading states everywhere they're used; streak/XP numbers use the animated count-up pattern
   consistently (Home, Challenge Detail, check-in celebration).

8. Re-run the ENTIRE test suite: `flutter test`. Every test from every prior issue must still
   pass. Fix any regressions your polish changes introduced.

9. Run `flutter analyze` on the whole project and resolve every warning/error, not just in files
   you touched this issue.

10. Manually complete the "Manual QA pass" checklist from docs/mvp/mobile-issues/README.md
    across the WHOLE app (rotate/resize, dark mode toggle, 130% text scale, airplane-mode error
    handling, rapid double-tap check, screen reader spot-check on the core loop).

11. Take screenshots of the new Profile screen (light & dark), and write a short summary list of
    every inconsistency you found and fixed during the Part B sweep (e.g. "Fixed: Challenge List
    status badge used Colors.red for 'paused' — changed to surfaceVariant per design system").

This issue is a quality gate, not just a feature. Be thorough — assume a judge will poke at every
corner of the app. Report every file created/modified, the full list of polish fixes made, and
confirm `flutter analyze` + `flutter test` are both completely clean at the end.
```
