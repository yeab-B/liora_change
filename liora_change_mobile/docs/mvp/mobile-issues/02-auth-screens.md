# Issue #2 — Auth Screens (Login / Register)

| Field | Value |
|-------|-------|
| **Branch** | `mobile/02-auth-screens` |
| **Base** | `main` |
| **Priority** | P0 |
| **Depends on** | #1 (theme, Dio client, router) |
| **Estimated time** | 4–5 hours |

---

## Business context

This is the first thing a judge sees. It must feel calm and welcoming (not a generic gray form), and it must correctly wire the token into secure storage and redirect to Home — this unlocks every other screen.

## API endpoints (see [../teams/SHARED-DATA-CONTRACT.md](../teams/SHARED-DATA-CONTRACT.md) and [../05-api-contract.md](../05-api-contract.md))

| Action | Method | Path |
|--------|--------|------|
| Register | `POST` | `/auth/register` |
| Login | `POST` | `/auth/login` |
| Logout | `POST` | `/auth/logout` |
| Get current user | `GET` | `/auth/me` |

Request/response bodies exactly as defined in the shared contract's `User` and `AuthResponse` schemas — do not rename fields.

## Screens to build

1. **Splash/bootstrap** — checks secure storage for a token on app start; if present, calls `GET /auth/me`; on success routes to `/home`, on failure clears token and routes to `/login`. Shows a simple branded loading state (logo + `LoadingSkeleton` or spinner on `background` color), never a blank white flash.
2. **Login screen** — email + password fields, "Log in" `PrimaryButton`, link to Register.
3. **Register screen** — name + email + password (+ confirm), "Create account" `PrimaryButton`, link to Login.

## UI/UX design criteria

- [ ] Uses `background` color, generous vertical spacing, logo/wordmark at top
- [ ] Form fields use Material 3 `TextFormField` with rounded borders matching the design system's card radius, `primary`-colored focus outline
- [ ] Inline validation errors appear under the field in `error` color the moment a field loses focus if invalid — not only on submit
- [ ] Password field has a show/hide toggle icon
- [ ] `PrimaryButton` shows `isLoading: true` during the network call and is disabled to prevent double-submit
- [ ] API errors (e.g. "Invalid credentials", "Email already taken") show as a friendly banner or `AppSnackbar.showError`, not a raw JSON dump
- [ ] Keyboard doesn't cover the active field — screen is wrapped in a `SingleChildScrollView`/`resizeToAvoidBottomInset`
- [ ] Smooth transition from Login ↔ Register (no jarring cut)
- [ ] Autofocus first field on screen entry; "Done"/"Next" keyboard actions move between fields and submit on the last field

## State management

- `authControllerProvider` (Riverpod `AsyncNotifier` or similar) exposing `login()`, `register()`, `logout()`, and current `AsyncValue<User?>` state
- On success: persist token via `token_storage.dart`, update auth state, `context.go('/home')`
- Router-level redirect (build now, from Issue #1's stub): if unauthenticated and route is not `/login`/`/register`, redirect to `/login`; if authenticated and route is `/login`/`/register`, redirect to `/home`

## Testing requirements (MUST)

- [ ] Widget test: Login form shows a validation error when submitting with an empty email
- [ ] Widget test: Login form disables the submit button while `isLoading` is true
- [ ] Widget test: successful login (mocked Dio/repository) triggers navigation to `/home`
- [ ] Widget test: failed login (mocked 401/422) shows an error message, stays on `/login`
- [ ] Manual check: password field toggle works; keyboard doesn't obscure fields on a small simulator

## Definition of Done

- [ ] Splash/bootstrap, Login, Register screens built and match design system
- [ ] Token persisted securely; app relaunch keeps user logged in until logout/expiry
- [ ] Router redirect logic enforces auth boundary
- [ ] All widget tests pass
- [ ] Screenshots (light + dark) attached to PR
- [ ] PR opened against `main`, linked to Issue #2

---

## 🤖 AI Development Prompt

```text
You are implementing Issue #2 "Auth Screens (Login/Register)" for the Liora Change Flutter app,
building on top of Issue #1's theme, Dio client, token storage, and GoRouter skeleton.

Read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (User and AuthResponse schemas — exact field names)
- docs/mvp/05-api-contract.md (auth endpoint request/response examples)
- docs/mvp/mobile-issues/00-design-system.md (colors, components, spacing — reuse PrimaryButton,
  AppCard, etc. from lib/core/widgets, do not redefine)
- docs/mvp/mobile-issues/02-auth-screens.md (this issue's full spec)

Implement:

1. lib/models/user.dart and lib/models/auth_response.dart — data classes matching the EXACT
   field names in SHARED-DATA-CONTRACT.md for User and AuthResponse, with fromJson/toJson
   (use json_serializable if already set up, otherwise hand-write fromJson factory constructors).

2. lib/features/auth/data/auth_repository.dart — methods:
   - Future<AuthResponse> register({required String name, required String email, required
     String password, required String passwordConfirmation})  → POST /auth/register
   - Future<AuthResponse> login({required String email, required String password}) → POST
     /auth/login
   - Future<void> logout() → POST /auth/logout
   - Future<User> me() → GET /auth/me
   All using the shared Dio client from lib/core/api/api_client.dart. Throw a typed exception
   (e.g. ApiException with a human-readable message extracted from the backend's error envelope)
   on failure so the UI layer can display it directly.

3. lib/features/auth/application/auth_controller.dart — a Riverpod AsyncNotifier<User?> (or
   StateNotifier<AsyncValue<User?>>) with methods login(), register(), logout(), and a
   bootstrap() method that: reads the token from secure storage, if present calls me(), sets
   state to the resulting user on success or clears the token and sets state to null on failure.
   On login/register success, persist the returned token via token_storage.dart before updating
   state.

4. lib/router/app_router.dart — update the GoRouter's `redirect` callback to read the auth
   controller's current state: if state is null (unauthenticated) and the target location is not
   /login or /register, redirect to /login. If state is a logged-in User and target is /login or
   /register, redirect to /home. Add a top-level route '/' that shows a Splash screen while
   auth_controller.bootstrap() is running (use its AsyncValue.isLoading), then the redirect logic
   takes over once resolved.

5. lib/features/auth/presentation/splash_screen.dart — background-colored screen with the app
   name/logo centered and a LoadingSkeleton or CircularProgressIndicator(color: theme primary)
   below it while bootstrap() runs.

6. lib/features/auth/presentation/login_screen.dart — a Form with email and password
   TextFormFields (rounded border per theme, password field has an obscureText toggle via a
   trailing IconButton), inline validators (email format, password non-empty), a PrimaryButton
   labeled "Log in" bound to authController.login(), wired to isLoading from the controller's
   AsyncValue, a text link "Don't have an account? Sign up" navigating to /register, and an error
   banner (AppSnackbar.showError or an inline banner) shown when the controller state has an
   error. Wrap the form in a SingleChildScrollView so the keyboard never covers fields.

7. lib/features/auth/presentation/register_screen.dart — same pattern with name, email,
   password, confirm password fields, PrimaryButton "Create account", link back to /login.

8. On successful login/register, navigate with context.go('/home').

9. Write widget tests:
   - test/features/auth/login_screen_test.dart: (a) tapping submit with an empty email shows a
     validation message and does not call the repository; (b) mock the auth repository to return
     a successful AuthResponse and verify navigation is triggered (you can test the controller
     logic directly with a fake repository if full navigation testing is complex, and cover the
     UI-level loading/error rendering separately); (c) mock a failure and verify an error message
     renders and the button re-enables.

10. Run `flutter analyze` and `flutter test`, fix everything until clean.

11. Manually run the app against the real backend (or a mocked server) and verify: register a
    new user, get redirected to Home stub, kill and relaunch the app, confirm it goes straight to
    Home (token persisted), then log out and confirm it returns to Login. Take screenshots of
    Login and Register in both light and dark mode.

Use only shared widgets and theme colors from Issue #1 — do not introduce new hardcoded colors
or one-off button styles. Report every file created/modified and confirm test + analyze results.
```
