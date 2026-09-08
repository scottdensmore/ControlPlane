---
name: ui-review
description: >-
  Review ControlPlane user-visible changes for HIG, accessibility, and layout.
  Use at workflow step 6 when XIBs, menus, prefs, status item, About, or Help
  change. Skip if nothing user-visible changed.
---

# UI / UX review

Workflow **step 6**. Read `AGENTS.md`. Skip this skill if the diff has no user-visible surface.

## Check

- macOS HIG on the current shipping OS: spacing, typography, standard menu shortcuts (Settings ⌘,, Quit ⌘Q, Hide ⌘H).
- VoiceOver labels on prefs and the status item. Template menu-bar images.
- Copy: Settings, not Preferences; no Growl-era or MarcoPolo leftovers.
- Bindings and layout: clipped controls, broken checkboxes, locale XIB drift versus Base.
- Help and gated-action strings match what the code actually does.
- New user-visible strings exist in `en`, `da-DK`, `de`, `fr`, `it`, `pt-BR`, and `pt-PT`.

## Report

- **Critical** — blocks ship
- **Should fix** — fix before commit
- **Nice to have** — defer, do not expand the slice

Do not redesign the prefs window unless that is the issue. Do not commit.

Critical and Should-fix items return to `tdd-slice`, then this skill again.
