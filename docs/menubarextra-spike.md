# Spike: SwiftUI MenuBarExtra / Settings beside ObjC CPController (#138)

Design-only. **No production SwiftUI menu-bar or Settings scene in this change.** Parent epic: [#116](https://github.com/scottdensmore/ControlPlane/issues/116). Related: [#100](https://github.com/scottdensmore/ControlPlane/issues/100) / `docs/prefs-settings-style-spike.md` (Settings chrome already chose AppKit).

## Goal

Decide whether ControlPlane should adopt SwiftUI `MenuBarExtra` and/or a SwiftUI `Settings` scene on the Tahoe / macOS 26 line (`MACOSX_DEPLOYMENT_TARGET` **16.0**) **without breaking** the existing `LSUIElement` lifecycle owned by ObjC `CPController`.

## Current topology

```text
Source/main.m
  → NSApplicationMain
  → MainMenu.xib / NSApp.delegate = CPController
       → evidence sources → contexts → actions
       → NSStatusItem (sbItem) + NSMenu (sbMenu)
       → PrefsWindowController + CPPrefsSettingsShellController (AppKit tabs)
```

Facts that constrain any SwiftUI host:

- Product is an **`LSUIElement` menu-bar agent** (`Info.plist`); no Dock icon. Windows must call `[NSApp activateIgnoringOtherApps:YES]` before becoming key (prefs, About, reopen) — covered by `CPMenuBarImageTests` / prefs characterization.
- Entry is classic **`NSApplicationMain`**; there are **zero** `.swift` sources in the app target today (`AGENTS.md`: Objective-C + XIBs).
- Status item is not decorative chrome: `CPController` owns hide/show timers, icon / context title / both (`menuBarOption`), template + optional tint via `CPMenuBarImage`, VoiceOver identifiers (`status.item.*` / `status.menu.*`), live context menu mutation, and config-transfer menu injection.
- Preferences already migrated chrome to **ObjC `NSTabViewController`** and explicitly deferred SwiftUI `Settings` (`docs/prefs-settings-style-spike.md`).
- Epic #116 lists **full SwiftUI rewrite of Settings / MenuBarExtra** as out of scope except design spikes until feasible.
- `docs/TESTING.md` already defers `MenuBarExtra` as a lifecycle / evidence-wiring risk.

## What SwiftUI would require

`MenuBarExtra` and `Settings { … }` are **SwiftUI `Scene`s**. The supported product shape is a Swift `@main` `App`:

```text
@main struct ControlPlaneApp: App {
  @NSApplicationDelegateAdaptor(CPController.self) var appDelegate  // or a thin Swift adaptor
  var body: some Scene {
    MenuBarExtra(…) { … }
    Settings { … }   // optional
  }
}
```

That replaces `NSApplicationMain` + XIB-driven delegate wiring with scene-phase ownership. Bridging can keep `CPController` as `NSApplicationDelegate`, but the status item and (if adopted) settings window stop being the simple AppKit objects `CPController` / `PrefsWindowController` mutate today.

## Options considered

| Option | Fit | Complexity | Risk |
| :--- | :--- | :--- | :--- |
| **A. Coexistence — keep `NSApplicationMain` / `CPController` `NSStatusItem`, add SwiftUI scenes “beside” it** | Poor: `MenuBarExtra`/`Settings` want an `App`/`Scene` host; dual hosts fight activation and menu-bar ownership | Medium–high (Swift target, bridging headers, dual status items or awkward scene stubs) | **High:** double status items, broken hide-from-menu-bar, prefs not key on Tahoe, dual `NSApplication` / scene edge cases already painful for tests |
| **B. Hybrid rewrite — Swift `@main` `App` + `@NSApplicationDelegateAdaptor` to `CPController`, replace status item with `MenuBarExtra`; keep XIB prefs** | Partial modernization of chrome only | High | **High:** reimplement hide timer, attributed title, tint, a11y ids, dynamic `NSMenu` edits inside SwiftUI/`NSMenu` bridging; easy to regress evidence timers that assume current launch path |
| **C. Full SwiftUI MenuBarExtra + Settings rewrite** | Clean API surface on a greenfield app | Very high (rewrite prefs panes, bindings, sheets, VO ids, UI tests) | **Very high** on this ObjC/XIB/MRC-ARC line; contradicts #116 out-of-scope and #100 AppKit choice |
| **D. Stay on AppKit `NSStatusItem` + existing Settings-style shell** | Matches shipped agent model; template catalog already done (#32 / #89) | None now | Low: no new lifecycle; Liquid Glass contrast already handled via template PNGs |

### Cost sketch (order of magnitude)

| Path | Rough engineering | What you gain |
| :--- | :--- | :--- |
| **A coexistence** | Weeks of integration + ongoing dual-stack bugs | Almost nothing users notice; higher CI/UI-test fragility |
| **B hybrid MenuBarExtra only** | Multi-slice epic (launch, menu parity, a11y, hide/show, smoke) | SwiftUI menu-bar API; little HIG win over current button API |
| **C full Settings + MenuBarExtra** | Large rewrite (months-class) | Modern SwiftUI prefs — already rejected for chrome in #100 |
| **D stay** | Docs / this spike | Keep working LSUIElement lifecycle; invest #116 budget in evidence/actions/helper |

## LSUIElement lifecycle risks (why coexistence fails)

1. **Scene vs delegate ownership.** `MenuBarExtra` is not a drop-in for `-[NSStatusBar statusItemWithLength:]`. Introducing scenes without owning `@main` leaves an unsupported half-bridge; owning `@main` changes how the agent launches relative to `main.m` / XIB outlets (`sbMenu`, `prefsWindow`).
2. **Activation.** Prefs/About/reopen already depend on explicit activation. SwiftUI `Settings` scene presentation has historically been awkward for accessory agents; regressing “Settings is key/front” breaks the documented Tahoe smoke path.
3. **Status-item semantics.** ControlPlane removes and recreates the item (`doHideFromStatusBar:`), sets `button.image` / `attributedTitle`, and mutates `sbMenu` at runtime. `MenuBarExtra` is built for declarative content, not this mutable AppKit menu controller pattern.
4. **Test host.** Logic tests already avoid an app-hosted bundle because dual `NSApplication` crashes this agent (`docs/TESTING.md`). A SwiftUI `App` entry raises the same class of host conflicts for any future UI test expansion.
5. **No incremental ROI.** Brand glyph already ships as **template** Asset Catalog images via `CPMenuBarImage` (`Resources/Images.xcassets/cp-icon.imageset`); status item uses the non-deprecated `NSStatusItem.button` API. SF Symbols / `MenuBarExtra` remain optional cosmetics, not a correctness fix.

## Recommendation

### **NO-SHIP — keep AppKit `NSStatusItem`; do not adopt `MenuBarExtra` or SwiftUI `Settings` on this ObjC line**

Reasons:

1. Coexistence (option A) does not cleanly sit “beside” `CPController` without either dual menu-bar owners or a launch-path rewrite.
2. A hybrid or full SwiftUI host (B/C) is a product rewrite, not a thin #116 slice; epic scope already defers that rewrite.
3. Settings chrome already chose AppKit (`CPPrefsSettingsShellController`); adding SwiftUI `Settings` would reopen #100 without new user value.
4. Current template status-item path meets Tahoe / Liquid Glass contrast needs with characterization tests.

**Not in this PR:** no Swift sources, no `App`/`Scene` scaffolding, no status-item behavior change.

## Pointer — stay on the existing template status item

| Piece | Location |
| :--- | :--- |
| Create / update / hide status item | `Source/CPController.m` — `showInStatusBar:`, `setMenuBarImage:`, `setStatusTitle:`, `doHideFromStatusBar:`, `startOrStopHidingFromStatusBar` |
| Template image prep | `Source/CPMenuBarImage.{h,m}` — `menuBarImageNamed:size:`, `configureAsMenuBarTemplate:size:` |
| Catalog artwork | `Resources/Images.xcassets/cp-icon.imageset` (`template-rendering-intent`) |
| Tests / deferred note | `ControlPlaneTests/CPMenuBarImageTests.m`; `docs/TESTING.md` (“Deferred … MenuBarExtra”) |
| Prefs activation (LSUIElement) | `PrefsWindowController` `runPreferences:`; `CPController` `applicationShouldHandleReopen:…` |

Revisit only if ControlPlane undertakes an intentional **SwiftUI app rewrite** (new epic, not a status-item polish issue). Until then, treat `MenuBarExtra` / SwiftUI `Settings` as **closed / no-ship** for the classic agent.

## Non-goals (this spike)

- Shipping SwiftUI code or enabling a Swift app target
- Changing `LSUIElement`, login items, or helper install
- SF Symbols migration for `cp-icon` (optional later; not blocked on MenuBarExtra)
- Reversing the #100 AppKit Settings-style shell decision
