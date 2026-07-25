# Mobile Design System — Liora Change

**Single source of truth for UI.** Every mobile issue references this file. If a screen doesn't match this, it's not done — regardless of whether the API call works.

**Vibe:** calm, supportive, green/nature-inspired — like a wellness app, not a productivity spreadsheet. Never alarming, never red-for-failure. Rounded, friendly, breathable spacing.

---

## 1. Color palette (calm green — consistent everywhere)

Define this once as a Flutter `ColorScheme` (Material 3, `useMaterial3: true`) and **never hardcode a hex color inside a widget** — always reference the theme.

### Light theme

| Token | Hex | Use |
|-------|-----|-----|
| `primary` | `#3F7D58` | Main buttons, active states, app bar accents |
| `onPrimary` | `#FFFFFF` | Text/icons on primary |
| `primaryContainer` | `#C2F1D3` | Selected chips, highlighted cards, progress fill |
| `onPrimaryContainer` | `#0B3B22` | Text on primaryContainer |
| `secondary` | `#6B9080` | Secondary buttons, less prominent accents |
| `surface` | `#FFFFFF` | Cards, sheets |
| `surfaceVariant` | `#EAF3ED` | Subtle section backgrounds |
| `background` | `#FAFDF9` | Screen background (warm off-white, not stark white) |
| `onBackground` / `onSurface` | `#1B1F1C` | Primary text |
| `outline` | `#C6D2CB` | Borders, dividers |
| **`success`** (custom) | `#2E7D32` | Streak flame, completed check-in, XP gain |
| **`recovery`** (custom — NOT red) | `#F5A623` | Recovery banner, "missed day" state — warm amber, never alarming |
| **`error`** (real system errors only) | `#D64545` | Network failure, form validation — never used for "you missed a day" |

### Dark theme

Derive from the same seed color (`#3F7D58`) using `ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark)` and override `success`/`recovery`/`error` with slightly desaturated versions:

| Token | Hex |
|-------|-----|
| `success` (dark) | `#66BB6A` |
| `recovery` (dark) | `#FFB84D` |
| `error` (dark) | `#E57373` |

### Hard rule

**Recovery / skipped state is NEVER red.** Red is reserved for genuine system errors (network down, form invalid). A missed check-in is `recovery` amber with warm, supportive copy — see Issue #7.

## 2. Typography

Use **Nunito** or **Poppins** via `google_fonts` package — rounded, friendly, approachable. Not a sharp/corporate sans.

| Style | Size | Weight | Use |
|-------|------|--------|-----|
| `displaySmall` | 28 | 700 | Big streak number, motivation headline |
| `titleLarge` | 20 | 700 | Screen titles, challenge titles |
| `titleMedium` | 16 | 600 | Card headers |
| `bodyLarge` | 15 | 500 | Primary body text |
| `bodyMedium` | 14 | 400 | Secondary text, descriptions |
| `labelSmall` | 12 | 600 | Chips, badges, timestamps |

Support Flutter's text scale factor (accessibility) — never wrap text in a fixed-height box that clips at larger scales.

## 3. Shape & spacing

| Token | Value |
|-------|-------|
| Card radius | 20px |
| Button radius | 14px |
| Chip/badge radius | 999px (pill) |
| Spacing scale | 4, 8, 12, 16, 24, 32, 48 (use these only — no arbitrary padding numbers) |
| Screen horizontal padding | 20px |
| Min tap target | 48×48 |

Cards use a soft shadow (`elevation: 1-2` or a subtle `BoxShadow` with low opacity), never a hard black border.

## 4. Shared components (build once in `lib/core/widgets/`, reuse everywhere)

| Widget | Purpose | Used in issues |
|--------|---------|-----------------|
| `PrimaryButton` | Filled, primary color, rounded, loading-state support (spinner replaces label) | All |
| `SecondaryButton` | Outlined variant | All |
| `AppCard` | Rounded surface container with consistent padding/shadow | #3, #4, #5 |
| `StreakBadge` | Flame icon + number, `success` color | #3, #5 |
| `ProgressBar` (linear, rounded ends) | Challenge progress %, `primaryContainer` track / `primary` fill | #5 |
| `RecoveryBanner` | Amber card, warm icon (not warning triangle — use something like a sprout/heart icon), title + message + CTA button | #7 |
| `EmptyState` | Icon + friendly text + CTA, used whenever a list is empty | #3, #4 |
| `LoadingSkeleton` | Shimmer placeholder, never a bare spinner on full-screen loads | All |
| `ErrorRetryView` | Icon + message + "Try again" button for network failures | All |
| `ChatBubble` | User (right, primary tint) vs assistant (left, surfaceVariant) | #9 |
| `AppSnackbar` helper | Consistent toast styling (success = green check, info = neutral) | All |

**Rule:** if two screens need "a card with a title and a value," that's one shared widget, not two copies.

## 5. Interaction & motion (make it feel alive, not static)

- Buttons: subtle scale-down (0.97) on press via `InkWell`/`AnimatedScale` — never a dead tap.
- Screen transitions: GoRouter default or a simple fade/slide — no jarring instant cuts.
- Streak/XP increase: animate the number counting up (e.g. `TweenAnimationBuilder`) rather than snapping.
- Pull-to-refresh on Home and Challenge List.
- Skeleton loaders for first paint, not blank white screens.
- Success feedback: brief scale/confetti-lite micro-animation on check-in complete (keep it tasteful, not gimmicky).
- Empty and error states are never a blank screen — always icon + message + action.

## 6. Responsiveness

- Support phone widths from ~360px to ~480px+ and tablet widths (basic — content should not overflow or look broken on a 10" tablet, even if not pixel-optimized).
- Use `LayoutBuilder`/`MediaQuery` to cap content width on large screens (e.g. max 600px centered) rather than stretching cards edge-to-edge.
- Test both portrait orientations at minimum; landscape should not crash (scrollable, no fixed-height overflow).
- Respect safe areas (`SafeArea`) on all screens, especially with notches/dynamic island.
- Support both light and dark system theme (`ThemeMode.system`) unless a screen has a specific reason not to.

## 7. Accessibility

- All interactive elements have a `Semantics`/`tooltip` label (icon-only buttons especially).
- Color is never the *only* signal — recovery banner has an icon + text, not just an amber background.
- Minimum contrast ratio 4.5:1 for body text against its background (verify with the palette above).
- Support system font scaling up to at least 130% without layout breakage.

## 8. "Feels like a real app" checklist (apply to every issue)

- [ ] Uses only theme colors — zero hardcoded hex values in widget code
- [ ] Uses shared components from `lib/core/widgets/` — no copy-pasted one-off cards
- [ ] Has a loading state (skeleton, not blank)
- [ ] Has an empty state (icon + friendly text + CTA)
- [ ] Has an error state with retry
- [ ] Buttons show a loading spinner while a request is in flight and are disabled during it
- [ ] Works in both light and dark mode
- [ ] No text overflow/clipping at default OR 130% text scale
- [ ] No hardcoded "magic number" paddings outside the spacing scale
- [ ] Every screen reachable and back-navigable via GoRouter without a dead end
