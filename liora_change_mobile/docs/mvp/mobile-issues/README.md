# Mobile Issues — 10 Issues (Flutter App)

**Team:** Mobile (Flutter)  
**Base branch:** `main` (mobile repo)  
**Rule:** Every issue must ship a **working, tested, on-brand screen** — not just "the API call works." Visual polish and UX are part of Definition of Done, not an afterthought.

> **Before you start:** read [../00-PROJECT-BRIEF.md](../00-PROJECT-BRIEF.md) (what the whole project is), then [../teams/MOBILE-TEAM-GUIDE.md](../teams/MOBILE-TEAM-GUIDE.md) (how to integrate), then **[00-design-system.md](./00-design-system.md)** (the calm-green visual language every screen must follow).

---

## Issue index

| # | Title | Branch | Depends on |
|---|-------|--------|------------|
| 1 | [Project Setup & Design System](./01-project-setup-theme.md) | `mobile/01-setup-theme` | None — do first |
| 2 | [Auth Screens (Login/Register)](./02-auth-screens.md) | `mobile/02-auth-screens` | #1 |
| 3 | [Home / Dashboard Screen](./03-home-dashboard.md) | `mobile/03-home-dashboard` | #1, #2 |
| 4 | [Challenge List + Create](./04-challenge-list-create.md) | `mobile/04-challenge-list-create` | #1, #2 |
| 5 | [Challenge Detail + Activate](./05-challenge-detail-activate.md) | `mobile/05-challenge-detail` | #4 |
| 6 | [Check-in Flow (Complete/Skip)](./06-checkin-flow.md) | `mobile/06-checkin-flow` | #5 |
| 7 | [Recovery Banner & Flow](./07-recovery-flow.md) | `mobile/07-recovery-flow` | #3, #6 |
| 8 | [AI Motivation Card](./08-ai-motivation-card.md) | `mobile/08-ai-motivation` | #3, #5 |
| 9 | [AI Coach Chat Screen](./09-ai-coach-chat.md) | `mobile/09-ai-coach-chat` | #1, #2 |
| 10 | [Profile, Polish, Responsiveness & QA](./10-profile-polish-qa.md) | `mobile/10-profile-polish-qa` | All above |

---

## Suggested build order (if only 1-2 people)

```text
1 → 2 → 3 → 4 → 5 → 6 → 7 (parallel with 8, 9) → 10 last
```

If you have 3 mobile devs, a reasonable split is:

| Dev | Issues |
|-----|--------|
| Dev X | #1, #2, #10 |
| Dev Y | #3, #4, #5 |
| Dev Z | #6, #7, #8, #9 |

---

## Golden rules for every issue

1. **Design system is law.** [00-design-system.md](./00-design-system.md) defines every color, spacing value, and shared widget. No hardcoded hex colors, no one-off paddings.
2. **Data shapes are law.** [../teams/SHARED-DATA-CONTRACT.md](../teams/SHARED-DATA-CONTRACT.md) defines every JSON field you parse. Don't rename fields to make your code prettier.
3. **Never shame the user.** Skipped/missed check-ins use the `recovery` amber color and warm copy — never red, never "You failed."
4. **Every screen needs 4 states:** loading (skeleton), empty (icon+CTA), error (retry), and success/content. An issue that only handles the happy path is not done.
5. **Test on more than one screen size.** At minimum: a small phone (~360px width) and a larger phone (~430px width), both light and dark mode.
6. **One branch per issue**, branched from latest `main`.
7. **Widget tests required** for anything with logic (forms, state-dependent UI) — see each issue's testing section.

---

## Definition of Done (every issue)

- [ ] Branch created from latest `main`, named as specified
- [ ] Screen(s) match [00-design-system.md](./00-design-system.md): theme colors only, shared widgets, correct spacing/radius
- [ ] All 4 UI states implemented: loading, empty, error, success
- [ ] Responsive: no overflow/clipping on a small phone or at 130% text scale
- [ ] Works in light AND dark mode
- [ ] Interactive: buttons show pressed/loading states, no dead taps
- [ ] Widget tests added and passing (`flutter test`)
- [ ] Manually verified against a running backend (or mocked API) — screenshot attached to PR
- [ ] No hardcoded colors, no `Colors.red` for recovery/skip states
- [ ] PR opened against `main`, issue linked

---

## Manual QA pass (run before every PR, and again before demo day)

1. Rotate device / resize simulator window — nothing overflows
2. Toggle system dark mode — colors still look intentional, not inverted-and-broken
3. Increase system text size to ~130% — no clipped text
4. Turn off Wi-Fi mid-request — error state with retry appears, not a crash
5. Tap every button twice quickly — no duplicate navigation/duplicate API calls
6. Screen reader (VoiceOver/TalkBack) on at least the primary flow — labels make sense
