# Testing ControlPlane

## Current status (macOS-16 / Tahoe)

- **Debug build:** works (`xcodebuild -scheme ControlPlane -configuration Debug`)
- **Unit tests:** `ControlPlaneTests` logic bundle (no app host — avoids dual `NSApplication` crash with this LSUIElement agent)
- **UI tests:** `ControlPlaneUITests` for prefs journeys; status-item clicks are unreliable under XCUITest
- **Smoke script:** `scripts/smoke-build.sh`
- **CI:** `.github/workflows/ci.yml` runs Debug build + `ControlPlaneTests` on PRs/`master` (no helper bless, `CODE_SIGNING_ALLOWED=NO`)
- **UI quarantine:** `.github/workflows/ui-tests-quarantine.yml` runs `ControlPlaneUITests` with `continue-on-error: true`
- **Signing / helper bless:** see [`docs/signing.md`](signing.md) (manual signed smoke; CI cannot bless)

## Commands

```bash
# Unit tests only
xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane \
  -destination 'platform=macOS' -derivedDataPath /tmp/ControlPlaneDerived \
  CODE_SIGNING_ALLOWED=NO test -only-testing:ControlPlaneTests

# UI tests (prefs journeys; set CPUITestRunning to skip notification auth UI)
xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane \
  -destination 'platform=macOS' -derivedDataPath /tmp/ControlPlaneDerived \
  CODE_SIGNING_ALLOWED=NO test -only-testing:ControlPlaneUITests

# Full local smoke (Debug + Release + unit tests)
./scripts/smoke-build.sh

# CI-shaped smoke (skip Release)
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

## What unit tests cover

| Suite | Behavior |
| :--- | :--- |
| `SharedNumberFormatterTests` | Percent formatter singleton used in confidence UI |
| `PrefsHIGShortTermTests` | Prefs a11y labels, agent menu shortcuts, standard About, Help accuracy (#31) |
| `PrefsSettingsStyleShellTests` | Settings-style `NSTabViewController` shell presence + pane/⌘, continuity (#100) |
| `CPMenuBarImageTests` | Menu-bar template prep (#89); Asset Catalog template/brand/AppIcon + button API checks (#32) |
| `CPSystemInfoTests` | `getOSVersion` encoding + hardware model; IOKit display bridge null-ID safety (#88) |
| `CPNotificationsGateTests` | `EnableNotifications` gates `postUserNotification` |
| `CPNotificationsMigrationTests` | `EnableGrowl` migrates to `EnableNotifications` |
| `SparkleVendoredArchitectureTests` | Vendored `Sparkle.framework` is Sparkle 2.x + universal (`x86_64` + `arm64`); `Info.plist` has no `SUPublicDSAKeyFile` |
| `InfoPlistPrivacyTests` | TCC usage strings present (Location mentions Wi‑Fi SSID); ATS no longer allows arbitrary loads |
| `CPLoginItemServiceTests` | SMAppService status → Start at Login checkbox mapping |
| `RetiredSharingActionTests` | FTP/TFTP/Web/Internet Sharing gated; SMB-only file sharing; legacy AFP fails clearly |
| `ActionTypeRegistryTests` | Action type ↔ class map + `actionFromDictionary` |
| `RunShortcutActionTests` | Run Shortcut (#34) type map, applicability gate, empty-name failure |
| `ToggleableActionTests` | Toggleable parameter parsing (`NSNumber` / `"on"` / `"0"`) via MuteAction |
| `ApplicabilityCharacterizationTests` | Retired sharing + Screen Saver Password + Natural Scrolling + Toggle Bluetooth + Display Brightness + TM Destination + Network Location/VPN/Firewall Rule + Notification Center Alerts/DND gated; clear execute failures |
| `PackedIPAddressTests` | IPv4/IPv6 pack validation |
| `IPv4RuleMatchTests` | Subnet rule matching via injected addresses |
| `ContextModelTests` | Context UUID, root flag, dictionary round-trip |
| `WiFiRuleMatchTests` | SSID matching with injected CoreWLAN state; Location-denied empty collection; Location TCC helper messages (#84) |
| `USBRuleMatchTests` | Vendor/product matching with injected device list |
| `PowerRuleMatchTests` | Battery vs A/C matching via `setPowerStatusForTesting:` |
| `TimeOfDayRuleMatchTests` | Weekday time-window matching with injected clock |
| `HelperSigningRequirementTests` | Helper/XPC SMJobBless requirements use team OU (not a personal CN) |
| `CPHelperCommandRunnerTests` | Helper argv-array runner: no `system()`/`sprintf` in `CPHelperTool.m`; display-sleep validation; fixed firewall/`tmutil`/SMB/remote-login args (#86) |
| `HelpScrubTests` | Help book links to this fork; no Growl-as-current guidance (#45); Wi‑Fi Location guidance (#84) |
| `CPConfigTransferTests` | Versioned config export/import round-trip (#35) |
| `CPDiagnosticsSnapshotTests` | Diagnostics snapshot explains mis-switched context / per-rule contribution (#35) |
| `DSLoggerTests` | Unified logging subsystem string + categories; ring buffer still captures (#35) |

Manual/script: `./scripts/check-help-scrub.sh` greps Help HTML for `dustinrue/ControlPlane` and Growl recommendation phrases.

## UI test accessibility identifiers

| Identifier | Control |
| :--- | :--- |
| `prefs.window` | Preferences window |
| `prefs.settingsShell` | Settings-style prefs shell (`NSTabViewController` host view) |
| `prefs.general.useNotifications` | Use Notifications checkbox |
| `prefs.tab.general` | General tab content view |
| `prefs.tab.evidencesources` | Evidence Sources tab content view |
| `prefs.toolbar.*` | Preference toolbar items (e.g. `prefs.toolbar.general`) |

Launch with `CPUITestRunning=1` and `-Debug OpenPrefsAtStartup YES` (see `ControlPlaneUITests.m`).

## Manual status-item smoke (not automatable under XCUITest)

1. Launch ControlPlane; confirm menu bar icon appears.
2. Click status item → **Settings** opens and is key/front (LSUIElement activation).
3. Click status item → **Active Contexts** submenu lists contexts.
4. Force a context from the menu; confirm menu bar label/icon updates.
5. Enable **Hide from status bar**; confirm icon reappears after relaunch.

### Tahoe / Liquid Glass (#89 / #32)

On macOS 26 with the default translucent menu bar:

1. Confirm the status-item icon remains readable (Asset Catalog `cp-icon` + template rendering).
2. Toggle System Settings → Appearance / wallpaper contrast; icon should stay usable.
3. Open **Settings** and **About** from the status menu; windows must activate and accept input; About should show the colored `ControlPlane` brand image (not a washed-out template).
4. Toggle menu-bar display prefs (icon / context / both) and **Hide from status bar**; confirm behavior is unchanged.

## Manual Diagnostics + logging probe (#35)

1. Configure conflicting Home/Work rules (Power@Home high confidence, Wi‑Fi@Work lower; min confidence ~75%).
2. Force Work, then match the Home Power rule; open **Settings → Diagnostics**.
3. Confirm the explanation prefers Home, the rules table shows Match / Rule % / Context %, and the evidence snapshot lists running sources.
4. In Terminal: `log stream --predicate 'subsystem == "com.scottdensmore.ControlPlane"' --level debug` while switching contexts; confirm lines appear (categories Evidence / Rules / Actions / Helper / General).
5. Optional: Advanced pane still shows the in-app log buffer.

### Deferred (out of scope for #32)

- SwiftUI `MenuBarExtra` host — would risk ObjC `CPController` lifecycle / evidence wiring; stay on `NSStatusItem`.
- SF Symbols for the status item — brand glyph already ships as template PNGs in `Images.xcassets`; revisit only if artwork needs redesign.

## Manual Wi‑Fi + Location TCC probe (#84, Tahoe)

| Location for ControlPlane | Connected to Wi‑Fi | Expected |
| :--- | :--- | :--- |
| Authorized | Yes | SSID/BSSID collected; Wi‑Fi rules can match |
| Denied / Restricted | Yes | No crash; empty SSID evidence; log + one-shot notification; Help/prefs mention Location |
| Not Determined | Yes | Wi‑Fi evidence start requests Location; empty until user responds |

Steps: enable Wi‑Fi evidence; toggle Location for ControlPlane in System Settings → Privacy & Security → Location Services; confirm Console/`DSLog` and optional notification when denied.

## Gaps / follow-ups

- Context + rule + mute action end-to-end journey (needs mock evidence seam)
- Confidence threshold behavior under UI test
- Promote `ControlPlaneUITests` from quarantine to blocking CI when stable on `macOS-16` runners

Do not expand host-based app tests until LaunchAction malloc/`libgmalloc` inheritance is kept off the TestAction (`shouldUseLaunchSchemeArgsEnv=NO`).


### Run Shortcut (#34)

1. Confirm `/usr/bin/shortcuts` exists (`which shortcuts`).
2. In Shortcuts, create a shortcut that shows a notification (e.g. **CP Test Notify**).
3. Preferences → Actions → add **Run Shortcut**, parameter `CP Test Notify`, arrival on a test context.
4. Force that context from the status menu; confirm the Shortcut runs and ControlPlane does not error.
5. Clear the parameter / use a blank name and trigger — confirm a clear failure message.
6. Optional: `shortcuts list --show-identifiers` and run by UUID via the same action.
