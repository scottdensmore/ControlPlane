# Testing ControlPlane

## Current status (macOS-16 / Tahoe)

- **Debug build:** works (`xcodebuild -scheme ControlPlane -configuration Debug`)
- **Unit tests:** `ControlPlaneTests` logic bundle (no app host — avoids dual `NSApplication` crash with this LSUIElement agent)
- **UI tests:** `ControlPlaneUITests` for prefs journeys; status-item clicks are unreliable under XCUITest
- **Smoke script:** `scripts/smoke-build.sh`
- **CI:** `.github/workflows/ci.yml` runs Debug build + `ControlPlaneTests` on PRs/`macOS-16`/`master` (no helper bless, `CODE_SIGNING_ALLOWED=NO`)
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
| `CPMenuBarImageTests` | Menu-bar template image flag + LSUIElement activation source checks (#89) |
| `CPSystemInfoTests` | `getOSVersion` encoding + hardware model |
| `CPNotificationsGateTests` | `EnableNotifications` gates `postUserNotification` |
| `CPNotificationsMigrationTests` | `EnableGrowl` migrates to `EnableNotifications` |
| `SparkleVendoredArchitectureTests` | Vendored `Sparkle.framework` is universal (`x86_64` + `arm64`) |
| `InfoPlistPrivacyTests` | TCC usage strings present (Location mentions Wi‑Fi SSID); ATS no longer allows arbitrary loads |
| `CPLoginItemServiceTests` | SMAppService status → Start at Login checkbox mapping |
| `RetiredSharingActionTests` | FTP/TFTP/Web/Internet Sharing gated; SMB-only file sharing; legacy AFP fails clearly |
| `ActionTypeRegistryTests` | Action type ↔ class map + `actionFromDictionary` |
| `ToggleableActionTests` | Toggleable parameter parsing (`NSNumber` / `"on"` / `"0"`) via MuteAction |
| `ApplicabilityCharacterizationTests` | Retired sharing + Screen Saver Password + Natural Scrolling + Toggle Bluetooth + TM Destination + Network Location/VPN/Firewall Rule + Notification Center Alerts/DND gated; clear execute failures |
| `PackedIPAddressTests` | IPv4/IPv6 pack validation |
| `IPv4RuleMatchTests` | Subnet rule matching via injected addresses |
| `ContextModelTests` | Context UUID, root flag, dictionary round-trip |
| `WiFiRuleMatchTests` | SSID matching with injected CoreWLAN state; Location-denied empty collection; Location TCC helper messages (#84) |
| `USBRuleMatchTests` | Vendor/product matching with injected device list |
| `PowerRuleMatchTests` | Battery vs A/C matching via `setPowerStatusForTesting:` |
| `TimeOfDayRuleMatchTests` | Weekday time-window matching with injected clock |
| `HelperSigningRequirementTests` | Helper/XPC SMJobBless requirements use team OU (not a personal CN) |
| `HelpScrubTests` | Help book links to this fork; no Growl-as-current guidance (#45); Wi‑Fi Location guidance (#84) |

Manual/script: `./scripts/check-help-scrub.sh` greps Help HTML for `dustinrue/ControlPlane` and Growl recommendation phrases.

## UI test accessibility identifiers

| Identifier | Control |
| :--- | :--- |
| `prefs.window` | Preferences window |
| `prefs.general.useNotifications` | Use Notifications checkbox |
| `prefs.tab.general` | General tab content view |
| `prefs.tab.evidencesources` | Evidence Sources tab content view |

Launch with `CPUITestRunning=1` and `-Debug OpenPrefsAtStartup YES` (see `ControlPlaneUITests.m`).

## Manual status-item smoke (not automatable under XCUITest)

1. Launch ControlPlane; confirm menu bar icon appears.
2. Click status item → **Preferences** opens and is key/front (LSUIElement activation).
3. Click status item → **Active Contexts** submenu lists contexts.
4. Force a context from the menu; confirm menu bar label/icon updates.
5. Enable **Hide from status bar**; confirm icon reappears after relaunch.

### Tahoe / Liquid Glass (#89)

On macOS 26 with the default translucent menu bar:

1. Confirm the status-item icon remains readable (template rendering).
2. Toggle System Settings → Appearance / wallpaper contrast; icon should stay usable.
3. Open **Preferences** and **About** from the status menu; windows must activate and accept input.
4. If context icon colors look washed out on Liquid Glass, track polish under #32 (Asset Catalog / SF Symbols)—do not block #89.

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
