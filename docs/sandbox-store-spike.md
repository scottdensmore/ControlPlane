# Spike: App Sandbox, Mac App Store, widgets, iCloud sync

Design-only. **Do not flip `com.apple.security.app-sandbox` in this change.** Current `main` stays unsandboxed until the enable-sandbox slice.

**Parent:** award epic [#190](https://github.com/scottdensmore/ControlPlane/issues/190), store epic [#278](https://github.com/scottdensmore/ControlPlane/issues/278). This document is the explicit design CONTRIBUTING previously required before those issues could be filed.

**Does not replace:** [signing.md](signing.md) (helper topology), [swiftui-coexistence-spike.md](swiftui-coexistence-spike.md) (AppKit host + SwiftUI views), [nevpn-spike.md](nevpn-spike.md) (no NEVPNManager).

---

## Goal

Make ControlPlane a **trustworthy 2026 Mac utility**: sandboxed agent, WidgetKit, automatic iCloud config sync, and a **Mac App Store** flavor — without abandoning Developer ID, `SMAppService`, or the evidence → context → action loop.

## Why the old ban existed

`docs/signing.md` and `CONTRIBUTING.md` said “no App Sandbox” because Wi‑Fi, Bluetooth, USB/IOKit, and helper XPC assumed a non-sandboxed process. That was a **missing entitlements map**, not a law of nature.

The helper path was already written for a sandboxed app:

- `CPXPCService.m` `connectWithEndpointAndAuthorizationReply:` — “authorization will fail because the app is sandboxed”
- `CPHelperTool.m` `connectWithEndpointReply:` — “so that the sandboxed app can talk us directly”

`ControlPlaneTests/CPContextAppIntentTests` `testAgentLifecycleAndSandboxAreUnchanged` currently **asserts the ban**. The enable-sandbox slice must invert that assertion.

---

## Locked design

### Principle

> **Sandbox the agent. Keep the daemon unsandboxed. Ship two distribution flavors from one codebase.**

| Flavor | Updates | Privileged helper | Sparkle |
| :--- | :--- | :--- | :--- |
| **Developer ID** (notarized GitHub Release) | Sparkle after #136 | `SMAppService` LaunchDaemon (today) | Yes |
| **Mac App Store** | App Store only | **Off** — hide checkbox, gate helper actions, Shortcuts-first (#218) | **No** |

Do **not** put a root LaunchDaemon or Sparkle in the MAS binary. Review will reject both. Detect MAS with the App Store receipt (`appStoreReceiptURL` + existing bundle id `com.scottdensmore.ControlPlane`); do not invent a second bundle id unless App Store Connect forces it.

`LSUIElement` stays. Do not add a Dock-only `@main` SwiftUI App to satisfy widgets.

### Target topology

```text
ControlPlane.app (App Sandbox + Hardened Runtime)
  ├── Agent (ObjC CPController + SwiftUI panes)
  ├── CPXPCService.xpc          (Developer ID only; unused on MAS)
  ├── CPHelperTool LaunchDaemon (Developer ID only; SMAppService)
  ├── Widget extension          (sandboxed, App Group)
  └── App Group container       group.com.scottdensmore.ControlPlane
        ├── context snapshot (widget)
        └── iCloud-synced config (CloudKit / ubiquity; both flavors)
```

### Entitlements (main app, both flavors)

Start from `ControlPlane.entitlements` and **add** (do not drop Sparkle’s `disable-library-validation` on Developer ID):

| Entitlement | Why |
| :--- | :--- |
| `com.apple.security.app-sandbox` | Store + trust |
| `com.apple.security.network.client` | Sparkle (Dev ID), CloudKit |
| `com.apple.security.device.usb` | USB evidence |
| `com.apple.security.device.bluetooth` | Bluetooth evidence |
| `com.apple.security.personal-information.location` | Wi‑Fi SSID / Core Location (already have usage strings) |
| `com.apple.security.automation.apple-events` | existing Apple Events usage string |
| `com.apple.security.files.user-selected.read-write` | export/import panels |
| App Group `group.com.scottdensmore.ControlPlane` | widget + snapshot |
| iCloud (CloudKit and/or `icloud-container-identifiers`) | automatic config sync |

Helper and XPC stay **unsandboxed** empty hardened-runtime plists. Never grant `disable-library-validation` to them.

**USB / IOKit:** if sandbox + `device.usb` is not enough for the current IOKit matching, **gate USB evidence on the sandboxed build** with the same `isEvidenceApplicable` pattern as FireWire — do not add MAS-illegal IOKit temporary exceptions. Developer ID may keep a documented temporary exception only if a characterization test proves `device.usb` fails.

**Wi‑Fi:** keep CoreWLAN + Location TCC (#259). Request the sandbox location entitlement; do not use private Wi‑Fi entitlements.

### Widgets

- One small WidgetKit widget: **current Context** (name + optional confidence). Optional second widget later: next-rule hint.
- Timeline reads **only** the App Group snapshot. The agent writes on context change (`CPController` force/auto switch).
- Widget must not talk to the helper or CoreWLAN.
- UITests: snapshot writer unit tests; widget UI is manual on Tahoe.

### Automatic iCloud sync

- Replace “Save a copy to iCloud Drive” (#277) as the *automatic* path; keep manual export.
- Store the **existing** `CPConfigTransfer` JSON schema in the app’s iCloud container (Documents or CloudKit private DB wrapping that blob). Last-writer-wins with `modified` timestamp; surface conflicts on Diagnostics (#247) — do not merge rule graphs in v1.
- Same iCloud container for Dev ID and MAS so a user can migrate.
- No CloudKit in the privileged helper.

### Mac App Store flavor

When receipt says MAS:

1. Do not link-run Sparkle updater UI (exclude feed checks; `SUFeedURL` unused).
2. `CPHelperDaemonService` checkbox hidden; status treated as not registered.
3. Helper-backed actions stay gated (`isActionApplicableToSystem == NO`) or redirect to Run Shortcut (#218).
4. Login item via `SMAppService.mainAppService` remains (MAS allows).
5. Privacy nutrition / App Store listing copy matches #274.

Unsigned CI (`CODE_SIGNING_ALLOWED=NO`) cannot exercise sandbox-restricted TCC. Characterization tests must inject evidence as they do today.

---

## Ordered slices

| Order | Issue | Topic |
| :---: | :--- | :--- |
| 1 | #279 | This spike (docs + policy pointers) |
| 2 | #280 | Enable App Sandbox + invert `CPContextAppIntentTests` |
| 3 | #281 | App Group + context snapshot writer |
| 4 | #282 | WidgetKit current-context widget |
| 5 | #283 | iCloud automatic config sync |
| 6 | #284 | MAS flavor (no Sparkle, no helper) |
| 7 | Maintainer | App Store Connect listing / privacy nutrition |

---

## Approaches rejected

| Approach | Why not |
| :--- | :--- |
| Keep unsandboxed forever | Blocks MAS, weakens ADA trust, complicates widgets/iCloud |
| Sandbox + root daemon in MAS | App Review |
| Dual `@main` SwiftUI app for widgets | Breaks LSUIElement / coexistence spike |
| CloudKit in the helper | Helper stays minimal and unsandboxed |
| Second bundle id for MAS | Only if Connect requires it; default is one id |

---

## Explicit non-goals (this spike)

- Flipping sandbox on `main` in this docs change
- Inventing Sparkle secrets (#136)
- Broadening helper commands
- NEVPNManager (#129)
- MenuBarExtra / SwiftUI Settings scenes (still NO-GO)

## Hand-off

Policy docs point here. Implementation starts at the enable-sandbox issue. Helper signed smoke (`docs/signing.md`) must pass on Developer ID after sandbox is on.
