# SwiftUI Contexts Settings pane — design

**Date:** 2026-09-13  
**Status:** Approved for implementation planning  
**Tracker SSOT:** GitHub Issues — [#229](https://github.com/scottdensmore/ControlPlane/issues/229), parent epics [#190](https://github.com/scottdensmore/ControlPlane/issues/190) / [#192](https://github.com/scottdensmore/ControlPlane/issues/192). This file is the slice design only; do not treat it as a second roadmap.

**Related:** [swiftui-coexistence-spike.md](../../swiftui-coexistence-spike.md), [2026-09-13-award-ui-platform-path-design.md](./2026-09-13-award-ui-platform-path-design.md), shipped General host (#203).

---

## Goal

Ship a SwiftUI **Contexts** Settings pane with create / rename / delete parity, hosted in the existing AppKit prefs shell, without rewriting `ContextsDataSource` persistence or the ObjC evidence loop.

---

## Product direction (locked for this track)

**Vision A — SwiftUI Settings (and later status) UI; ObjC engine stays.**

- AppKit `NSApplicationMain` → `CPController` remains lifecycle, evidence, actions, and helper host.
- Settings panes migrate pane-by-pane to SwiftUI via `NSHostingController` inside `PrefsWindowController` / `CPPrefsSettingsShellController`.
- Status menu SwiftUI (#235) is a later slice on the same coexistence rule.
- **Out of this track:** Swift `@main` `App`, `MenuBarExtra`, SwiftUI `Settings { }` scenes, big-bang rewrite of evidence/actions.

---

## Scope (#229)

### In scope

| Area | Outcome |
| :--- | :--- |
| Host | `ContextsSettingsController` + `ContextsSettingsView` (+ thin Swift host factory), installed into `contextsPrefsView` using the General install/hide pattern |
| List | SwiftUI list of contexts; indented rows for parent/child **display** if cheap; no drag-and-drop |
| CRUD | Add / Remove / Edit wired to existing `ContextsDataSource` APIs |
| Create / rename UI | Reuse the existing AppKit name sheet (`newContextSheet` / `editSelectedContext:` path) — do not rebuild sheet chrome in SwiftUI this PR |
| Delete | Existing `removeContext:` including child-warning alert |
| A11y | New `prefs.contexts.*` ids; pane root stays **only** on AppKit container `prefs.tab.contexts` (no duplicate on hosted SwiftUI root) |
| Docs | Document new ids in `docs/TESTING.md` |
| L10n | New user-visible SwiftUI strings in all shipping locales (`en`, `da-DK`, `de`, `fr`, `it`, `pt-BR`, `pt-PT`) |
| Tests | Source/unit assertions for host + ids; minimal create-context UITest or selectors ready for [#204](https://github.com/scottdensmore/ControlPlane/issues/204) |

### Out of scope (defer)

- Drag-and-drop reparent
- Icon color / color-preview sheet fields (keep sheet name-only usage for create/rename if color UI stays unused from SwiftUI)
- Live confidence column
- Full retirement of every Contexts XIB control beyond what the host hides/replaces
- Other Settings panes (#230+)
- Expanding `CPSettingsReadModelBridge` for UUID/parent (optional later; this slice may talk to `ContextsDataSource` directly via the ObjC host, same as General talks to login/helper services)

---

## Architecture

```text
PrefsWindowController
  contextsPrefsView                    ← AppKit container; prefs.tab.contexts
    [legacy outline / buttons hidden]
    ContextsSettingsController.view    ← NSHostingController(ContextsSettingsView)
      list + Add / Remove / Edit
        → closures / selectors
      ContextsDataSource
        createContextWithName:fromUI:
        editSelectedContext: / name update
        removeContext:
        existing NSPanel sheet for name
```

### Components

| Piece | Responsibility |
| :--- | :--- |
| `ContextsSettingsView` | SwiftUI list + toolbar buttons; a11y ids on interactive controls |
| `ContextsSettingsViewModel` | Observable list state; refresh from data source; hold apply closures |
| `ContextsSettingsHost` | `makeViewController(model:)` → `NSViewController` for ObjC |
| `ContextsSettingsController` | ObjC host owning model + hosting controller; `view` + refresh |
| `PrefsWindowController` | `installContextsSettingsHostedView` (mirror General); hide legacy outline/buttons; wire data source |
| `ContextsDataSource` | Unchanged persistence / sheet / delete alerts — called, not rewritten |

### Suggested accessibility ids

| Id | Control |
| :--- | :--- |
| `prefs.tab.contexts` | AppKit pane container only (existing) |
| `prefs.contexts.list` | Context list |
| `prefs.contexts.add` | Add |
| `prefs.contexts.remove` | Remove |
| `prefs.contexts.edit` | Edit / rename |
| `prefs.contexts.sheet.name` | Name field on existing sheet (set from ObjC if missing) |
| `prefs.contexts.sheet.confirm` | Sheet confirm button (set from ObjC if missing) |

---

## Errors and edge cases

- Delete with children: keep existing warning alert from `ContextsDataSource`.
- Empty selection: Remove/Edit disabled or no-op matching today’s button behavior.
- Create under selection: preserve “parent = selected row, else root” semantics from `newContextPromptingForName:`.
- Registration/persistence failures: surface through existing data-source paths; do not invent a second error UI.
- UITest harness: continue `CPUITestRunning=1` + OpenPrefsAtStartup; navigate via `prefs.toolbar.contexts`.

---

## Acceptance mapping

| Criterion (issue #229) | Design coverage |
| :--- | :--- |
| Contexts pane is SwiftUI and feature-parity for create/rename/delete | In-scope CRUD via data source + SwiftUI list/host |
| UITest create-context still green (update selectors if needed) | Add ids + minimal journey or lock selectors for #204 |

---

## Implementation notes for the plan

- Follow TDD where practical: failing source assertion for `prefs.contexts.*` and host symbol names before wiring.
- Prefer existing localized button titles from XIB/`NSLocalizedString` over new English-only copy.
- One thin PR; Conventional Commit `feat(settings): … (#229)`; squash-merge to `main`.
- Verify with `./scripts/smoke-build.sh` and UITest ad-hoc signing per `docs/TESTING.md`.
