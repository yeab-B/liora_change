# Issue #1 — Project Setup & Design System (Theme)

| Field | Value |
|-------|-------|
| **Branch** | `mobile/01-setup-theme` |
| **Base** | `main` |
| **Priority** | P0 — everything else depends on this |
| **Depends on** | None |
| **Estimated time** | 3–4 hours |

---

## Business context

Before any screen is built, the app needs its skeleton: navigation, API client, secure token storage, and — critically — the **calm green design system** applied globally, so every screen built afterward is automatically on-brand instead of needing a redesign pass later.

## What to build

1. Flutter project structure (`lib/core`, `lib/features`, `lib/models`, `lib/router`)
2. Riverpod app-wide `ProviderScope`
3. GoRouter skeleton with placeholder routes for every screen (even if the screen is just a "Coming soon" stub) so navigation never dead-ends while other issues are in progress
4. Dio client with base URL config + auth interceptor (attach token, handle 401)
5. Secure token storage (`flutter_secure_storage`)
6. **Full Material 3 theme** implementing [00-design-system.md](./00-design-system.md) exactly: `ColorScheme` (light + dark), typography via `google_fonts` (Nunito or Poppins), shape theme (rounded buttons/cards), spacing constants
7. Shared widget library skeleton: `PrimaryButton`, `SecondaryButton`, `AppCard`, `StreakBadge`, `ProgressBar`, `EmptyState`, `LoadingSkeleton`, `ErrorRetryView`, `AppSnackbar` — build these now as empty/basic implementations; later issues will use them, not redefine them

## Folder structure

```text
lib/
  core/
    api/
      api_client.dart        # Dio instance + interceptors
      endpoints.dart          # path constants
    storage/
      token_storage.dart
    theme/
      app_colors.dart         # tokens from design system
      app_theme.dart          # ThemeData light/dark
      app_spacing.dart        # spacing scale constants
    widgets/
      primary_button.dart
      secondary_button.dart
      app_card.dart
      streak_badge.dart
      progress_bar.dart
      empty_state.dart
      loading_skeleton.dart
      error_retry_view.dart
      app_snackbar.dart
  features/
    auth/ challenges/ checkins/ home/ profile/ coach/   # empty folders, filled by later issues
  models/
  router/
    app_router.dart
  main.dart
```

## Config

```dart
// lib/core/api/api_client.dart
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1');
```

Dio interceptor: attach `Authorization: Bearer <token>` from secure storage on every request if present; on `401` response, clear token and redirect to `/login` via a router-level listener (e.g. a `Riverpod` auth-state provider that GoRouter's `redirect` reads).

## UI/UX design criteria (this issue's real deliverable)

- [ ] `ColorScheme` exactly matches the hex values in [00-design-system.md](./00-design-system.md) §1, for both light and dark
- [ ] Custom `success` / `recovery` / `error` colors are accessible via a `ThemeExtension` (so any widget can do `Theme.of(context).extension<AppColors>()!.recovery`) — not hardcoded per-screen
- [ ] Typography uses `google_fonts` Nunito or Poppins across the whole app via `ThemeData.textTheme`
- [ ] Button/card shapes use the radii from §3 (14px buttons, 20px cards)
- [ ] `PrimaryButton` supports a `isLoading` prop that swaps the label for a spinner and disables the tap
- [ ] App respects `ThemeMode.system` (auto light/dark)
- [ ] Placeholder routes exist for every screen in the app so GoRouter never 404s during development

## Testing requirements (MUST)

- [ ] Widget test: `PrimaryButton` renders label normally, renders a spinner and is non-tappable when `isLoading: true`
- [ ] Widget test: app boots and renders the initial route without throwing (`testWidgets` smoke test wrapping `MaterialApp.router`)
- [ ] Manual check: toggle OS dark mode → app follows automatically without a restart
- [ ] Manual check: increase OS text size to 130% → `PrimaryButton` label doesn't clip

## Definition of Done

- [ ] Folder structure created as specified
- [ ] Theme matches design system exactly (colors, type, shape)
- [ ] Dio client + token storage + 401 handling works
- [ ] GoRouter has a route for every planned screen (stubs OK)
- [ ] Shared widget skeletons exist and are used by nothing hardcoded elsewhere
- [ ] `flutter test` passes
- [ ] PR opened against `main`, linked to Issue #1

---

## 🤖 AI Development Prompt

Paste this into your AI coding agent on branch `mobile/01-setup-theme`:

```text
You are implementing Issue #1 "Project Setup & Design System" for the Liora Change Flutter app.

Context to read first:
- docs/mvp/00-PROJECT-BRIEF.md (what the whole project is)
- docs/mvp/teams/MOBILE-TEAM-GUIDE.md (integration conventions: Dio, Riverpod, GoRouter, token
  handling, folder suggestion)
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (so route/model naming stays consistent later)
- docs/mvp/mobile-issues/00-design-system.md (the COMPLETE visual spec: exact colors, typography,
  shape, spacing, and the list of shared widgets you must scaffold)
- docs/mvp/mobile-issues/01-project-setup-theme.md (this issue's full spec)

Build the following in a fresh (or existing, if already scaffolded) Flutter project:

1. Add dependencies: flutter_riverpod, go_router, dio, flutter_secure_storage, google_fonts,
   intl. Use the latest stable versions.

2. Create the folder structure exactly as shown in the issue's "Folder structure" section.

3. lib/core/theme/app_colors.dart — define the light and dark ColorScheme objects using the
   EXACT hex values from docs/mvp/mobile-issues/00-design-system.md section 1 (both tables:
   light theme and dark theme). Also define a Flutter ThemeExtension class (e.g. AppSemanticColors)
   exposing `success`, `recovery`, and a note that `error` uses the standard Material error color
   from the ColorScheme, so widgets can access recovery/success colors via
   Theme.of(context).extension<AppSemanticColors>().

4. lib/core/theme/app_theme.dart — build ThemeData.light() and ThemeData.dark() using
   useMaterial3: true, the ColorSchemes from step 3, a TextTheme built with GoogleFonts.nunito()
   (or poppins, pick one and use it consistently) matching the type scale in design system
   section 2, and shape theming (ElevatedButtonTheme/OutlinedButtonTheme with 14px rounded
   corners, CardTheme with 20px rounded corners) per section 3. Register both themes plus
   themeMode: ThemeMode.system in the root MaterialApp.router.

5. lib/core/theme/app_spacing.dart — a simple class/const set exposing the spacing scale
   (4, 8, 12, 16, 24, 32, 48) as named constants (e.g. AppSpacing.md = 16).

6. lib/core/api/api_client.dart — a Dio instance configured with baseUrl from
   String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1'),
   default headers Accept/Content-Type: application/json, and an interceptor that (a) reads the
   token from lib/core/storage/token_storage.dart and attaches
   'Authorization': 'Bearer $token' when present, and (b) on receiving a 401 response, clears
   the stored token and exposes this via a Riverpod StateProvider<bool> (e.g. authExpiredProvider)
   that the router redirect logic (built in a later issue) can react to — for now just implement
   the clearing + provider update, routing logic comes with Issue #2.

7. lib/core/storage/token_storage.dart — wraps flutter_secure_storage with simple
   read/write/delete methods for a single 'auth_token' key.

8. lib/router/app_router.dart — a GoRouter instance with placeholder routes (simple
   Scaffold(body: Center(child: Text('Coming soon'))) screens are fine for now) for: /login,
   /register, /home, /coach, /challenges, /challenges/create, /challenges/:id, /profile. Wire
   this router into main.dart via MaterialApp.router.

9. Build the shared widgets listed in docs/mvp/mobile-issues/00-design-system.md section 4,
   starting with functional basic versions (they will be refined by later issues but must be
   usable now):
   - lib/core/widgets/primary_button.dart: a PrimaryButton(label, onPressed, isLoading) that
     renders a Material 3 FilledButton styled per the theme, swaps its child for a
     SizedBox(height:20,width:20,child:CircularProgressIndicator) and sets onPressed to null when
     isLoading is true.
   - lib/core/widgets/secondary_button.dart: OutlinedButton variant, same isLoading behavior.
   - lib/core/widgets/app_card.dart: a Card wrapper enforcing the 20px radius and consistent
     padding (AppSpacing.md).
   - lib/core/widgets/streak_badge.dart: icon + number using the theme's success color.
   - lib/core/widgets/progress_bar.dart: a rounded LinearProgressIndicator using
     primaryContainer/primary colors.
   - lib/core/widgets/empty_state.dart: icon + title + subtitle + optional CTA button, centered.
   - lib/core/widgets/loading_skeleton.dart: a simple shimmering placeholder box (a basic
     AnimatedContainer opacity pulse is acceptable if you don't want to add a shimmer package).
   - lib/core/widgets/error_retry_view.dart: icon + message + "Try again" PrimaryButton calling
     an onRetry callback.
   - lib/core/widgets/app_snackbar.dart: static helper methods AppSnackbar.showSuccess(context,
     message) and AppSnackbar.showError(context, message) using theme colors, not raw
     Colors.green/Colors.red.

10. Write widget tests:
    - test/core/widgets/primary_button_test.dart: verify the label renders normally, and that
      when isLoading is true a CircularProgressIndicator is shown and tapping does not trigger
      onPressed.
    - test/smoke_test.dart: pump the root app widget wrapped in ProviderScope and assert it
      builds without throwing and shows the initial route.

11. Run `flutter analyze` and `flutter test` until clean and green.

12. Manually verify: run the app, toggle the OS/simulator dark mode setting, and confirm theme
    switches automatically. Take a screenshot of the placeholder home screen in both light and
    dark mode and include both in your summary.

Do not hardcode any hex color directly inside a widget file — every color must come from
Theme.of(context) or the AppSemanticColors extension. When finished, list every file created and
confirm `flutter analyze` and `flutter test` are clean.
```
