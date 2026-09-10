# Spike: SwiftUI + Swift 6 coexistence beside CPController (#199)

Design-only. **No production SwiftUI Settings scene, MenuBarExtra, or UI rewrite in this change.** Discard any throwaway prototypes; rebuild under TDD in later slices.

**Parent epics:** [#190](https://github.com/scottdensmore/ControlPlane/issues/190) (WWDC award), [#191](https://github.com/scottdensmore/ControlPlane/issues/191) (platform), [#192](https://github.com/scottdensmore/ControlPlane/issues/192) (SwiftUI shell).

**Supersedes for the award track:** Wave 1 [`docs/menubarextra-spike.md`](menubarextra-spike.md) (**NO-SHIP** under [#116](https://github.com/scottdensmore/ControlPlane/issues/116) / [#138](https://github.com/scottdensmore/ControlPlane/issues/138)). That Wave 1 verdict remains correct for **SwiftUI `Scene`s** (`MenuBarExtra` / `Settings { }`). This spike reopens the product goal under a different coexistence shape: **AppKit owns lifecycle; SwiftUI owns views**.

Related: [`docs/prefs-settings-style-spike.md`](prefs-settings-style-spike.md) (#100 AppKit Settings-style chrome), `Source/SwitchContextIntent.swift` (proven thin Swift beside ObjC).

---

## Goal

Decide how ControlPlane can ship award-grade SwiftUI Settings and status-menu chrome on macOS 26 (Tahoe / deploy **16.0**) **without breaking** the ObjC `CPController` evidence → context → action loop, `LSUIElement` activation, privileged-helper prefs, or UITest accessibility IDs.

---

## What changed since Wave 1

| Wave 1 assumption (`menubarextra-spike.md`) | Today (`master` @ this spike) |
| :--- | :--- |
| “Zero `.swift` sources in the app target” | **False.** `SwitchContextIntent.swift` + `ControlPlane-Bridging-Header.h` + `CPContextAppIntentBridge` already ship App Intents beside `CPController`. |
| Settings chrome deferred SwiftUI forever (#100) | Chrome is AppKit `NSTabViewController` (`CPPrefsSettingsShellController`). Award epic #192 wants **pane content** (and later search/sidebar) in SwiftUI — not a contradiction if hosting stays AppKit-owned. |
| Epic #116 deferred full SwiftUI rewrite | Epic #190/#191/#192 **authorize** deliberate dual-stack migration; still forbid big-bang rewrite and App Sandbox. |
| Coexistence = dual `App`/`Scene` hosts | That shape is still unsafe. Coexistence = **host SwiftUI views inside the existing AppKit agent**. |

Wave 1 closed the wrong door for the award track if read as “never SwiftUI UI.” It correctly closed **MenuBarExtra / SwiftUI Settings scenes** as drop-ins beside `NSApplicationMain`.

---

## Current topology (source of truth)

```text
Source/main.m
  → NSApplicationMain
  → MainMenu.xib / NSApp.delegate = CPController
       → evidence sources → contexts → actions   (ObjC, stays)
       → NSStatusItem (sbItem) + NSMenu (sbMenu)
       → PrefsWindowController + CPPrefsSettingsShellController (AppKit tabs / XIB panes)
       → SwitchContextIntent.swift → CPContextAppIntentBridge → CPController
```

Constraints that any award-track UI must preserve:

1. **`LSUIElement` agent** — prefs/About/reopen call `[NSApp activateIgnoringOtherApps:YES]` before key (`PrefsWindowController` `runPreferences:`, `CPController` reopen path).
2. **Status item is mutable AppKit state** — create/remove (`doHideFromStatusBar:`), template image (`CPMenuBarImage`), attributed title, live context menu injection, VoiceOver ids `status.item.*` / `status.menu.*`.
3. **Logic tests have no app host** — dual `NSApplication` crashes this agent (`docs/TESTING.md`). UITests use `CPUITestRunning=1` + `-Debug OpenPrefsAtStartup YES`, not menu-bar geometry clicks.
4. **Helper / Login Items / no App Sandbox** — out of scope for this spike; Settings panes must keep calling existing ObjC services.

---

## Coexistence model (locked design)

### Principle

> **AppKit owns process lifecycle and evidence. SwiftUI paints.**

Do **not** replace `NSApplicationMain` with a Swift `@main` `App` for award-track Settings/status work. Do **not** add SwiftUI `MenuBarExtra` or `Settings { }` scenes “beside” the ObjC delegate. Host SwiftUI with `NSHostingController` / `NSHostingView` (and, for menus, AppKit `NSMenu` with hosted content or `NSPopover` if a later slice chooses that presentation).

Proven pattern already in-tree:

```text
Swift (SwitchContextIntent)
  → ObjC bridge (CPContextAppIntentBridge)
  → CPController (force switch / list tokens)
  → no window activation (openAppWhenRun = false)
```

Extend that pattern for UI:

```text
SwiftUI View (pane / menu section)
  → Swift read-model / bridge (#224)
  → ObjC registries / PrefsWindowController / CPController
  → same activation and helper paths as today
```

### Target topology (after #191/#192 slices)

```text
NSApplicationMain + CPController          ← unchanged owner
  NSStatusItem + NSMenu (or popover host) ← AppKit chrome; SwiftUI content optional
  prefsWindow (AppKit NSWindow)           ← activation / ⌘, / LSUIElement
    CPPrefsSettingsShellController        ← keep until search/sidebar slice
      NSHostingController(GeneralView…)   ← first SwiftUI pane (#203)
      … other panes migrate one-by-one
  App Intents / future Swift evidence     ← thin Swift; ObjC still executes matchers until templates ship
```

---

## Surface decisions

### 1. SwiftUI Settings **scene** (`Settings { }` in an `App` body)

| | |
| :--- | :--- |
| **Verdict** | **NO-GO** |
| Why | Requires Swift `@main` scene ownership or an unsupported dual-host. LSUIElement Settings-from-menu historically opens behind other apps unless activation is carefully owned; ControlPlane already solved that with AppKit `runPreferences:`. Scene-based Settings also fights the existing `prefsWindow` outlet, sheet parenting, resize persistence, and `prefs.*` accessibility IDs. |
| Award alternative | Host SwiftUI **pane views** inside the existing prefs window / tab shell. |

### 2. SwiftUI Settings **content** (views hosted in AppKit)

| | |
| :--- | :--- |
| **Verdict** | **GO** |
| Why | Incremental, pane-by-pane (#203 then #229–#234). Keeps `CPController` evidence loop, activation, helper checkboxes, and UITest launch args. Matches #100’s “keep shell AppKit” spirit while unlocking award-grade Forms, Dynamic Type, and Liquid Glass-friendly controls. |
| First ship | General pane only; leave other tabs as XIB views in the same shell. |

### 3. `MenuBarExtra`

| | |
| :--- | :--- |
| **Verdict** | **NO-GO** (reaffirmed; stronger on Tahoe) |
| Why | Not a drop-in for hide/show timers, attributed titles, or dynamic `NSMenu` mutation. Wave 1 risks remain. On macOS 26, system “Allow in Menu Bar” / visibility semantics bind poorly to `MenuBarExtra` scene lifetime (community reports of accessory apps vanishing when the icon is disabled); ControlPlane’s `doHideFromStatusBar:` needs an item that can disappear while the process and evidence loop stay alive. Liquid Glass contrast is already handled by template catalog art (`CPMenuBarImage` / #32 / #89). |
| Overlap with #228 | This doc **is** the MenuBarExtra vs `NSStatusItem` decision record for the award track. #228 may close as “superseded by #199” or keep a one-page Tahoe smoke checklist only — do not re-litigate MenuBarExtra. |

### 4. `NSStatusItem` + SwiftUI menu content

| | |
| :--- | :--- |
| **Verdict** | **GO** |
| Why | Keep AppKit `NSStatusItem` ownership in `CPController` (create/remove, image, title, a11y). Migrate **menu content** later (#235) via hosted SwiftUI inside the existing menu/popover while preserving `status.menu.*` identifiers and Force Context / Settings / About / Quit. |
| Not required for Liquid Glass | Template `NSStatusItem.button` already meets Tahoe smoke in `docs/TESTING.md`. |

### 5. Swift `@main` `App` replacing `main.m`

| | |
| :--- | :--- |
| **Verdict** | **NO-GO for #191/#192** |
| Why | High risk to evidence timers, XIB outlets (`sbMenu`, `prefsWindow`), test host assumptions, and Sparkle/login-item launch paths. Revisit only under an explicit rewrite epic — not needed to paint Settings/status in SwiftUI. |

### 6. Platform enablers (not UI)

| Surface | Verdict |
| :--- | :--- |
| Swift 6 language mode for new Swift (#200) | **GO** |
| `AGENTS.md` dual-stack policy (#201) | **GO** |
| Shared Swift read models (#224) | **GO** (before multi-pane Settings bind to live data) |
| Migrate one evidence / one action to Swift (#225/#226) | **GO** as templates after bridge; optional parallel to shell |
| Structured concurrency for polling (#227) | Spike only; do not block Settings panes |

---

## GO / NO-GO summary

| Surface | Decision | Epic |
| :--- | :--- | :--- |
| SwiftUI `Settings` **scene** | **NO-GO** | — |
| SwiftUI Settings **panes** in AppKit window | **GO** | #192 |
| `MenuBarExtra` | **NO-GO** | — (closes Wave 1 reopen) |
| `NSStatusItem` + SwiftUI menu content | **GO** | #192 / #235 |
| Swift `@main` replacing `NSApplicationMain` | **NO-GO** (award track) | — |
| Swift 6 + bridges + AGENTS dual-stack | **GO** | #191 |

**One-line product call:** Ship award UI by hosting SwiftUI inside the existing LSUIElement AppKit agent; do not adopt SwiftUI menu-bar/Settings scenes.

---

## UITest hooks and accessibility ID strategy

### Keep (stable contracts)

| Identifier / hook | Role |
| :--- | :--- |
| `prefs.window` | Preferences `NSWindow` |
| `prefs.settingsShell` | Tab shell host view |
| `prefs.tab.<pane>` | Pane content root (e.g. `prefs.tab.general`) |
| `prefs.toolbar.<pane>` | Toolbar items |
| `prefs.general.*` | Controls (e.g. `useNotifications`, `allowPrivilegedHelper`) |
| `prefs.diagnostics.*` | Diagnostics probes |
| `status.item.controlplane` | Status button |
| `status.menu.*` | Menu items (`preferences`, `about`, `quit`, …) |
| Env `CPUITestRunning=1` | Skip notification auth friction |
| Arg `-Debug OpenPrefsAtStartup YES` | Open prefs without clicking the menu bar |

### Rules for SwiftUI panes / menus

1. **Stable string IDs, not localized titles**, for XCUITest queries. Mirror today’s dotted namespace; do not invent a second taxonomy.
2. Apply `.accessibilityIdentifier("prefs.general.useNotifications")` (etc.) on the SwiftUI control that replaces the AppKit one; keep the **same** string through migration so #241–#243 journeys stay green.
3. Put the identifier on the **interactive** element (Toggle/Button), and keep a pane-root id on the outermost hosted view (`prefs.tab.general`) for navigation asserts.
4. Prefer **Debug launch hooks** over status-item clicks (#202 harness, then #244 for Force Context). Menu-bar geometry remains unreliable under XCUITest (`docs/TESTING.md`).
5. When hosting SwiftUI in a menu/popover, expose the same `status.menu.*` ids via `.accessibilityIdentifier` or AppKit wrappers so VoiceOver (#238) and UITests share one map.
6. Document new ids in `docs/TESTING.md` in the same table as today (#255). Locale gate for new user-visible SwiftUI strings is #252 — not this spike.

### Anti-patterns

- Depending on `MenuBarExtra` or scene `SettingsLink` for UITest entry.
- Renaming ids mid-migration without updating `ControlPlaneUITests` in the same slice.
- Hitting toolbar buttons only by localized title once SwiftUI search/sidebar (#237) lands — prefer `prefs.toolbar.*`.

---

## Fit / complexity / maintenance

| Approach | Fit | Complexity | Maintenance |
| :--- | :--- | :--- | :--- |
| **A. Dual Scene host** (Wave 1 option A) | Poor | High | Dual activation + dual status owners |
| **B. `@main` + MenuBarExtra** | Poor for hide/show + evidence | Very high | Scene lifecycle owns the agent |
| **C. Full SwiftUI rewrite** | Clean on greenfield | Months | Abandons ObjC investment |
| **D. AppKit host + SwiftUI views (chosen)** | Matches LSUIElement + award goal | Medium, sliceable | One lifecycle; panes migrate independently |
| **E. Stay XIB forever** | Stable | Low | Fails #190 award bar |

Prefer **gating/retiring dead actions** and AppKit chrome that already works over clever scene replacements. Invest award budget in panes, trust UX (#194), and a11y (#193), not in re-platforming launch.

---

## Ordered thin slices

Implementers: rebuild under `tdd-slice`. Do **not** promote spike prototypes. Each slice is independently shippable onto `master`.

### Platform foundation — epic [#191](https://github.com/scottdensmore/ControlPlane/issues/191)

| Order | Issue | Goal | Likely files | How red is proven | Out of scope |
| :---: | :--- | :--- | :--- | :--- | :--- |
| P0 | [#199](https://github.com/scottdensmore/ControlPlane/issues/199) (this doc) | Lock GO/NO-GO + slice order | `docs/swiftui-coexistence-spike.md` | Docs review / issue AC checklist | Any production UI |
| P1 | [#200](https://github.com/scottdensmore/ControlPlane/issues/200) | Swift 6 language mode for app Swift | `project.pbxproj`, `SwitchContextIntent.swift` as needed | Build fails under Swift 6 until fixed; `ControlPlaneTests` still green | UI panes |
| P2 | [#201](https://github.com/scottdensmore/ControlPlane/issues/201) | Dual-stack policy in `AGENTS.md` | `AGENTS.md` only (pointers stay pointers) | Docs assertion / review vs this spike | Implementing SwiftUI |
| P3 | [#224](https://github.com/scottdensmore/ControlPlane/issues/224) | Shared Swift read models (Context / Evidence / Action lists) | New Swift types + ObjC façades; tests | Failing mapping tests → green bridge; ObjC matchers unchanged | Settings UI; matcher rewrites |
| P4 | [#225](https://github.com/scottdensmore/ControlPlane/issues/225) / [#226](https://github.com/scottdensmore/ControlPlane/issues/226) | One evidence + one action Swift template | One source + one action + registry tests | Characterization red → Swift type registered | Mass migration |
| P5 | [#227](https://github.com/scottdensmore/ControlPlane/issues/227) | Concurrency spike for timers | Spike doc only | Design AC | Production timer rewrite in spike PR |

### SwiftUI shell — epic [#192](https://github.com/scottdensmore/ControlPlane/issues/192)

Depends on P0; **strongly prefer P3 (#224) before panes that bind live lists**. General pane can start with narrow ObjC selectors if needed.

| Order | Issue | Goal | Likely files | How red is proven | Out of scope |
| :---: | :--- | :--- | :--- | :--- | :--- |
| S0 | [#228](https://github.com/scottdensmore/ControlPlane/issues/228) | Mark MenuBarExtra **NO-GO**; optional Tahoe smoke note | Point at this doc; tiny TESTING note if needed | Issue AC / docs | Shipping MenuBarExtra |
| S1 | [#203](https://github.com/scottdensmore/ControlPlane/issues/203) | SwiftUI **General** pane hosted in AppKit shell | New SwiftUI General view; `PrefsWindowController` / shell host; a11y ids preserved | UITest or characterization: General controls via same `prefs.general.*` ids; Debug+Release | Other panes; Settings scene |
| S2 | [#229](https://github.com/scottdensmore/ControlPlane/issues/229)–[#234](https://github.com/scottdensmore/ControlPlane/issues/234) | Contexts → Evidence → Rules → Actions → Advanced → Diagnostics | One PR per pane | Per-pane UITest or unit+manual smoke; ids stable | Big-bang all panes |
| S3 | [#235](https://github.com/scottdensmore/ControlPlane/issues/235) (+ [#263](https://github.com/scottdensmore/ControlPlane/issues/263)) | SwiftUI status **menu content** on `NSStatusItem` | `CPController` menu wiring; SwiftUI menu/popover content | Manual status smoke + #244 hook; `status.menu.*` preserved | `MenuBarExtra` |
| S4 | [#237](https://github.com/scottdensmore/ControlPlane/issues/237) | Search / sidebar polish | Shell host evolution | UITest navigation still via ids | Rewriting evidence logic |
| S5 | [#262](https://github.com/scottdensmore/ControlPlane/issues/262), [#236](https://github.com/scottdensmore/ControlPlane/issues/236), [#257](https://github.com/scottdensmore/ControlPlane/issues/257) | Rule sheets; retire unused XIBs; About polish | XIBs / About | Locale + VO checks | Helper topology |

### Parallel (do not serialize)

| Track | Issues | Note |
| :--- | :--- | :--- |
| UITest harness | [#202](https://github.com/scottdensmore/ControlPlane/issues/202) → [#244](https://github.com/scottdensmore/ControlPlane/issues/244) → journeys | Start early; Debug hooks > menu-bar clicks |
| Trust / a11y / product | #194 / #193 / #196 children | Consume SwiftUI shell; do not wait for full XIB retirement |
| TESTING docs | [#255](https://github.com/scottdensmore/ControlPlane/issues/255) | After first SwiftUI pane lands |

---

## Explicit non-goals (this spike / #199)

- Shipping SwiftUI Settings or MenuBarExtra
- Helper / `SMAppService` changes
- Enabling App Sandbox
- Replacing `NSApplicationMain` / rewriting `CPController`
- Promoting any prototype code into the app target

---

## Pointers for implementers

| Concern | Where |
| :--- | :--- |
| Status item lifecycle | `Source/CPController.m` — `showInStatusBar:`, `doHideFromStatusBar:`, `setMenuBarImage:`, `setStatusTitle:` |
| Template / Liquid Glass icon | `Source/CPMenuBarImage.{h,m}`, `Resources/Images.xcassets/cp-icon.imageset` |
| Prefs shell | `Source/CPPrefsSettingsShellController.m`, `Source/PrefsWindowController.m` |
| Swift ↔ ObjC bridge template | `Source/SwitchContextIntent.swift`, `Source/CPContextAppIntentBridge.{h,m}`, `Source/ControlPlane-Bridging-Header.h` |
| UITest launch | `ControlPlaneUITests/ControlPlaneUITests.m`, `docs/TESTING.md` |
| Wave 1 Scene NO-SHIP | `docs/menubarextra-spike.md` (still valid for Scenes; superseded for “never SwiftUI UI”) |
| AppKit Settings chrome choice | `docs/prefs-settings-style-spike.md` |

**Hand-off:** After verify/review of this docs-only PR, close #199 AC. Platform implementer starts at #200/#201/#224 under `tdd-slice`. Shell implementer starts General (#203) only after coexistence rules are in `AGENTS.md` (#201) or explicitly waived by the parent agent for a parallel slice that does not invent a second policy.
