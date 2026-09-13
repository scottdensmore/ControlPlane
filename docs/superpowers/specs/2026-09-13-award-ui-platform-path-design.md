# Award UI platform path — design

**Date:** 2026-09-13  
**Status:** Approved for implementation planning  
**Tracker SSOT:** GitHub Issues — parent epic [#190](https://github.com/scottdensmore/ControlPlane/issues/190). This file is the wave design only; do not treat it as a second roadmap.

**Related spikes:** [swiftui-coexistence-spike.md](../../swiftui-coexistence-spike.md), [sandbox-store-spike.md](../../sandbox-store-spike.md) (out of scope for this wave).

---

## Goal

Land the Award UI critical path so ControlPlane can ship SwiftUI Settings on macOS 26 (Tahoe) without rewriting the ObjC evidence → context → action loop.

**Approach:** Strict serial — one PR per issue: **#200 → #201 → #224 → #203**.

---

## Scope

### In scope

| Order | Issue | Outcome |
| :---: | :--- | :--- |
| 1 | [#200](https://github.com/scottdensmore/ControlPlane/issues/200) | Swift 6 language mode for app Swift (`SwitchContextIntent` + project settings); build/docs assertion that mode stays 6 |
| 2 | [#201](https://github.com/scottdensmore/ControlPlane/issues/201) | Dual-stack migration policy in `CONTRIBUTING.md`; refresh epic **#190** body for current constraints (`main`, local smoke only, sandbox design allowed) |
| 3 | [#224](https://github.com/scottdensmore/ControlPlane/issues/224) | Thin Swift read models for Context / Evidence / Action lists; ObjC remains source of truth for matching and execution |
| 4 | [#203](https://github.com/scottdensmore/ControlPlane/issues/203) | SwiftUI **General** pane hosted in the existing AppKit prefs shell; preserve `prefs.general.*` accessibility IDs; localize new strings |

### Out of scope

- Other Settings panes (#229–#234)
- Status-menu SwiftUI content (#235)
- App Sandbox / widgets / iCloud / MAS (#278 / #280+)
- MenuBarExtra or SwiftUI `Settings { }` scenes
- Evidence/action Swift templates (#225 / #226)
- Structured concurrency timer rewrite (#227)
- Status-item Force Context UITest hook (#244) — may run later in parallel, not a gate for this wave

---

## Architecture

**Locked coexistence rule:** AppKit owns process lifecycle and evidence; SwiftUI paints views. Do not replace `NSApplicationMain` with a Swift `@main` `App`. Do not add `MenuBarExtra` or scene-based Settings.

```text
NSApplicationMain → CPController (evidence → context → action)
  NSStatusItem + NSMenu                    ← unchanged this wave
  PrefsWindowController
    CPPrefsSettingsShellController         ← AppKit tabs
      General: NSHostingController(…)      ← #203
      other panes: existing XIB views      ← later
  SwitchContextIntent.swift                ← #200 Swift 6
  Settings read-model bridge               ← #224 → ObjC registries (read-only for UI)
```

### Components

| Slice | Mechanism |
| :--- | :--- |
| **#200** | Set app-target `SWIFT_VERSION` to 6; fix `SwitchContextIntent` concurrency/isolation; ObjC call sites stay on existing `CPContextAppIntentBridge` |
| **#201** | Document dual-stack in `CONTRIBUTING.md` only (pointer files stay pointers; no `AGENTS.md`); update #190 issue text/comment so the written goal matches repo reality |
| **#224** | Thin Swift structs + ObjC façade (same pattern as `CPContextAppIntentBridge`): ordered names, enablement flags — no matcher or action execution moves |
| **#203** | Replace General pane content with hosted SwiftUI; wire toggles to `CPLoginItemService`, `CPHelperDaemonService`, and existing notification prefs |

### Data flow (General)

```text
SwiftUI GeneralSettingsView
  → login / helper / notification bindings
  → CPLoginItemService / CPHelperDaemonService / prefs defaults
  → same alerts and “Open Login Items” recovery as today
```

Bridge (#224) supplies list read models for later panes; General may use it for consistency where useful, but must not invent a second prefs-only glue layer that bypasses the long-term bridge pattern.

---

## Errors and edge cases

- **Helper / Login Items:** SwiftUI presents; ObjC services decide success/failure and supply alert copy. Keep “Open Login Items” recovery paths.
- **Unsigned Debug:** Helper checkbox may show not-registered; do not pretend daemon registration works without Developer ID signing (`docs/signing.md`).
- **Bridge mapping:** Empty or missing registries return empty lists; never invent contexts, evidence sources, or actions.
- **Docs assertions:** Preserve existing `CPHelperDaemonServiceTests` contracts on `CONTRIBUTING.md` / README / signing (`SMAppService`, `CPXPCService`, no SMJobBless install wording).

---

## Testing and acceptance

### Per PR

- Run `./scripts/smoke-build.sh` (or `SKIP_RELEASE=1` when sufficient for the slice).
- Keep existing helper/docs unit assertions green.

### Slice-specific

| Slice | Extra proof |
| :--- | :--- |
| #200 | Debug + Release build under Swift 6; App Intent still works; assertion that app Swift stays on 6 |
| #201 | `CONTRIBUTING.md` describes dual-stack + coexistence spike pointer; #190 text no longer claims Actions re-enable, `master`, or a standing sandbox ban |
| #224 | Unit tests for Context / Evidence / Action list mapping; ObjC matchers unchanged |
| #203 | Settings open via `Debug OpenPrefsAtStartup`; controls reachable via `prefs.general.*`; new strings in all shipping locales |

### Wave done when

- General Settings is SwiftUI inside the AppKit shell
- Platform enablers (#200, #201, #224) are on `main`
- Epic #190 accurately describes the award track
- Other prefs panes remain XIB until later slices

---

## Delivery

| Order | Issue | Suggested branch |
| :---: | :--- | :--- |
| 1 | #200 | `feat/swift-6-language-mode` |
| 2 | #201 | `docs/agents-dual-stack` |
| 3 | #224 | `feat/settings-read-models` |
| 4 | #203 | `feat/swiftui-general-pane` |

Each slice: feature branch → local smoke → squash-merged PR onto `main` → start the next. Do not commit directly to `main`. Do not start #203 until #201 is on `main`. Prefer #224 before #203.

---

## Explicit non-goals

- Big-bang Swift rewrite of `CPController`
- Enabling App Sandbox in this wave
- Shipping MenuBarExtra or SwiftUI Settings scenes
- Collapsing `CPXPCService` or changing helper topology
