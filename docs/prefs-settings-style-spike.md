# Spike: Settings-style Preferences (#100)

Follow-up to the short-term prefs HIG work (#31). Preferences historically used a hand-rolled `NSToolbar` + content-view swap in `PrefsWindowController`.

## Options considered

| Approach | Fit | Complexity | Risk |
| :--- | :--- | :--- | :--- |
| **A. `NSTabViewController` + `NSTabViewControllerTabStyleToolbar` hosting existing XIB `NSView`s** | Native Settings-like chrome; stays ObjC; incremental | Low–medium | Low: reuses panes, a11y ids, and resize/persist logic |
| **B. SwiftUI `Settings` scene bridged into the ObjC `LSUIElement` app** | Modern API surface | Higher (Swift bridge, scene lifecycle, hosting AppKit tables/bindings) | Higher on this ObjC/XIB line; easy to regress VoiceOver / ⌘, / sheet parenting |

## Choice

**A — ObjC `NSTabViewController` preference-style shell** (`CPPrefsSettingsShellController`).

Reasons:

1. Matches the issue preference for an incremental, ObjC-first migration.
2. Existing MainMenu.xib panes (General → Advanced) stay as-is; only the chrome changes.
3. Avoids introducing a SwiftUI settings scene beside MRC/ARC AppKit controllers, array controllers, and modal sheets parented to `prefsWindow`.
4. Keeps #31 VoiceOver identifiers (`prefs.tab.*`, `prefs.window`) and Apple-menu ⌘, wiring untouched.

## Thin slice landed

- Shell owns the preference toolbar via AppKit.
- All six panes are embedded as tab items backed by the existing views.
- `PrefsWindowController` still owns resize persistence, Advanced log buffer timer, and `runPreferences:` / menu wiring.

## Deferred

- Per-pane SwiftUI rewrites
- Deployment-target bump
- Helper/XPC

## Residual risks

- Toolbar item identifiers AppKit assigns for `NSTabViewController` can differ slightly from the hand-rolled toolbar; accessibility ids are re-applied in the shell’s toolbar delegate override.
- Window resize during tab changes no longer swaps a blank content view; watch for layout flicker on large Rules/Actions panes.
- UI tests that locate toolbar buttons by localized title remain valid; identifier-based toolbar queries should prefer `prefs.toolbar.*`.
