# Issue #4 — Challenge List + Create

| Field | Value |
|-------|-------|
| **Branch** | `mobile/04-challenge-list-create` |
| **Base** | `main` |
| **Priority** | P0 |
| **Depends on** | #1, #2 |
| **Estimated time** | 5–6 hours |

---

## Business context

Before a member can build a streak, they need to pick or create a challenge. This screen should feel encouraging (templates make it a 2-tap process) rather than a blank form that feels like work.

## API endpoints

| Action | Method | Path |
|--------|--------|------|
| List my challenges | `GET` | `/challenges` |
| List challenge categories | `GET` | `/challenge-categories` |
| List challenge templates | `GET` | `/challenge-templates?category_id=` |
| Create challenge | `POST` | `/challenges` |

Exact request/response fields: `Challenge`, `ChallengeCategory`, `ChallengeTemplate` schemas in [../teams/SHARED-DATA-CONTRACT.md](../teams/SHARED-DATA-CONTRACT.md).

## Screens to build

1. **Challenge List screen** — shows the member's challenges as `AppCard`s (title, category chip, status badge: active/completed/paused), tap → Challenge Detail (Issue #5). FAB or top-right "+" button → Create flow.
2. **Create Challenge screen** — two-step, friendly flow:
   - Step A: pick a category (chips/grid from `/challenge-categories`, each with an icon)
   - Step B: pick a template from that category (`/challenge-templates?category_id=`) shown as tappable cards with title + description, OR a "Custom" option that reveals a free-text title field
   - Confirm button → `POST /challenges` → on success, navigate to the new Challenge Detail (Issue #5) or back to Home with a success snackbar

## UI/UX design criteria

- [ ] Category chips use `primaryContainer` when selected, `surfaceVariant` when not — clear selected state, smooth color transition
- [ ] Template cards show a subtle "recommended"/popularity indicator if the API provides one; otherwise a clean icon + title + one-line description
- [ ] Multi-step create flow uses a simple step indicator (e.g. two dots or a segmented header) so the user always knows where they are
- [ ] Back button/step navigation within create flow doesn't lose previously selected category
- [ ] List screen has pull-to-refresh and an `EmptyState` ("No challenges yet — start one!") with a CTA that jumps straight into Create
- [ ] Status badges use distinct but calm colors: active = `primary`/`success`-tinted chip, completed = `secondary`-tinted, paused = neutral `surfaceVariant` — never red
- [ ] "Create" confirm button shows `isLoading` state and is disabled during submit; validation prevents submitting with nothing selected
- [ ] List and create screens both cap content width on tablets, respect safe areas

## State management

- `challengeListControllerProvider` — `AsyncNotifier<List<Challenge>>` for `GET /challenges`
- `createChallengeControllerProvider` — local state holding selected category id, selected template id (or custom title), and an `AsyncValue` for the submit action calling `POST /challenges`
- `categoriesProvider` / `templatesProvider` (family, keyed by category id) — simple `FutureProvider`s

## Testing requirements (MUST)

- [ ] Widget test: challenge list renders cards for each item in a mocked response
- [ ] Widget test: empty list shows `EmptyState` with correct CTA
- [ ] Widget test: selecting a category then a template enables the confirm button; confirm is disabled with nothing selected
- [ ] Widget test: submitting calls the repository with the correct payload (category/template or custom title) and navigates away on success
- [ ] Widget test: a 422 validation error from the API surfaces a visible error message, not a silent failure
- [ ] Manual check: full create flow works end-to-end against the real backend

## Definition of Done

- [ ] List + Create screens built per criteria above
- [ ] All 4 UI states present on the list screen (loading/empty/error/success)
- [ ] Create flow validated, cannot submit incomplete selection
- [ ] All widget tests pass
- [ ] Screenshots attached (list populated, empty, create step A, create step B — light & dark)
- [ ] PR opened against `main`, linked to Issue #4

---

## 🤖 AI Development Prompt

```text
You are implementing Issue #4 "Challenge List + Create" for the Liora Change Flutter app, built
on Issue #1 (theme/widgets) and Issue #2 (auth/router).

Read first:
- docs/mvp/teams/SHARED-DATA-CONTRACT.md (Challenge, ChallengeCategory, ChallengeTemplate schemas
  — exact field names and enum values for challenge status)
- docs/mvp/05-api-contract.md (endpoint examples for /challenges, /challenge-categories,
  /challenge-templates)
- docs/mvp/mobile-issues/00-design-system.md (chips, AppCard, EmptyState, spacing, colors)
- docs/mvp/mobile-issues/04-challenge-list-create.md (this issue's full spec)

Implement:

1. lib/models/challenge.dart, challenge_category.dart, challenge_template.dart matching the
   shared contract exactly, with fromJson/toJson.

2. lib/features/challenges/data/challenge_repository.dart with:
   - Future<List<Challenge>> getMyChallenges() → GET /challenges
   - Future<List<ChallengeCategory>> getCategories() → GET /challenge-categories
   - Future<List<ChallengeTemplate>> getTemplates(String categoryId) → GET
     /challenge-templates?category_id=
   - Future<Challenge> createChallenge({String? templateId, String? categoryId, String?
     customTitle}) → POST /challenges with the exact payload shape from the API contract
     (adjust param names to match the real request schema).

3. lib/features/challenges/application/challenge_list_controller.dart — AsyncNotifier
   <List<Challenge>> fetching getMyChallenges(), with a refresh() method.

4. lib/features/challenges/application/create_challenge_controller.dart — a StateNotifier (or
   Notifier) holding { selectedCategoryId, selectedTemplateId, customTitle, AsyncValue<void>
   submitState }, with methods selectCategory(id), selectTemplate(id), setCustomTitle(text), and
   submit() that calls challenge_repository.createChallenge(...) and updates submitState.

5. lib/features/challenges/presentation/challenge_list_screen.dart:
   - AppBar with a title and a '+' IconButton navigating to '/challenges/create'
   - RefreshIndicator + ListView.builder over the controller's challenges, each rendered as an
     AppCard with title, a category chip, and a status badge (active/completed/paused) using the
     colors specified in the issue (never red)
   - EmptyState when the list is empty, CTA navigates to '/challenges/create'
   - ErrorRetryView on failure
   - LoadingSkeleton list on initial load
   - Tapping a card navigates to '/challenges/{id}' (Issue #5's route)

6. lib/features/challenges/presentation/create_challenge_screen.dart — a two-step flow (use a
   simple internal `step` int state, 0 = category, 1 = template/custom):
   - Step indicator at the top (two small dots or a segmented control, current step highlighted
     in primary color)
   - Step 0: a responsive grid/wrap of category chips (icon + label) from categoriesProvider;
     tapping selects it (primaryContainer background when selected) and auto-advances to step 1
   - Step 1: templates for the selected category as tappable AppCards (title + description) plus
     one final "Custom challenge" card that reveals a TextFormField for a custom title when tapped
   - Bottom-pinned PrimaryButton "Create challenge", disabled until a valid selection exists
     (template selected OR custom title non-empty), shows isLoading during submit
   - On submit success: show AppSnackbar.showSuccess and navigate to '/challenges/{newId}' (or
     '/home' if that route isn't ready yet — add a TODO)
   - On submit failure (e.g. 422): show the API's error message via AppSnackbar.showError

7. Register both routes ('/challenges', '/challenges/create') in lib/router/app_router.dart,
   replacing the Issue #1 placeholders.

8. Write widget tests in test/features/challenges/ covering:
   - list renders cards from a mocked list
   - empty list shows EmptyState
   - error shows ErrorRetryView
   - create flow: selecting category then template enables the confirm button; with nothing
     selected the button stays disabled
   - submit calls the repository with expected params and navigates on success; shows an error
     message on a mocked failure

9. Run `flutter analyze` and `flutter test`, fix until clean.

10. Manually run the full flow against the real backend: view list, create a challenge via a
    template, confirm it appears in the list. Take screenshots of all screen states listed in the
    Definition of Done and include them in your summary.

Reuse only shared widgets/theme tokens from Issue #1 — no new one-off styling. Report every file
created/modified and confirm test + analyze results.
```
