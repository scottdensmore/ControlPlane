# Testing ControlPlane

## Current status (macOS-15)

- **Debug build:** works (`xcodebuild -scheme ControlPlane -configuration Debug`)
- **Unit tests:** `ControlPlaneTests` logic bundle (no app host — avoids dual `NSApplication` crash with this LSUIElement agent)
- **UI tests:** `ControlPlaneUITests` for prefs journeys; status-item clicks are unreliable under XCUITest
- **Smoke script:** `scripts/smoke-build.sh`
- **CI:** `.github/workflows/ci.yml` runs Debug build + `ControlPlaneTests` on PRs/`macOS-15`/`master` (no helper bless, `CODE_SIGNING_ALLOWED=NO`)
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
| `CPSystemInfoTests` | `getOSVersion` encoding + hardware model |
| `CPNotificationsGateTests` | `EnableNotifications` gates `postUserNotification` |
| `CPNotificationsMigrationTests` | `EnableGrowl` migrates to `EnableNotifications` |
| `SparkleVendoredArchitectureTests` | Vendored `Sparkle.framework` is universal (`x86_64` + `arm64`) |
| `InfoPlistPrivacyTests` | TCC usage strings present; ATS no longer allows arbitrary loads |
| `CPLoginItemServiceTests` | SMAppService status → Start at Login checkbox mapping |
| `RetiredSharingActionTests` | FTP/TFTP/Web/Internet Sharing gated; SMB-only file sharing; legacy AFP fails clearly |
| `ActionTypeRegistryTests` | Action type ↔ class map + `actionFromDictionary` |
| `ToggleableActionTests` | Toggleable parameter parsing (`NSNumber` / `"on"` / `"0"`) via MuteAction |
| `ApplicabilityCharacterizationTests` | Retired sharing + Screen Saver Password gated; ScreenSaverPassword wait flags / clear execute failure |
| `PackedIPAddressTests` | IPv4/IPv6 pack validation |
| `IPv4RuleMatchTests` | Subnet rule matching via injected addresses |
| `ContextModelTests` | Context UUID, root flag, dictionary round-trip |
| `WiFiRuleMatchTests` | SSID matching with injected CoreWLAN state |
| `USBRuleMatchTests` | Vendor/product matching with injected device list |
| `PowerRuleMatchTests` | Battery vs A/C matching via `setPowerStatusForTesting:` |
| `TimeOfDayRuleMatchTests` | Weekday time-window matching with injected clock |
| `HelperSigningRequirementTests` | Helper/XPC SMJobBless requirements use team OU (not a personal CN) |
| `HelpScrubTests` | Help book links to this fork; no Growl-as-current guidance (#45) |

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
2. Click status item → **Preferences** opens.
3. Click status item → **Active Contexts** submenu lists contexts.
4. Force a context from the menu; confirm menu bar label/icon updates.
5. Enable **Hide from status bar**; confirm icon reappears after relaunch.

## Gaps / follow-ups

- Context + rule + mute action end-to-end journey (needs mock evidence seam)
- Confidence threshold behavior under UI test
- Promote `ControlPlaneUITests` from quarantine to blocking CI when stable on `macOS-15` runners

Do not expand host-based app tests until LaunchAction malloc/`libgmalloc` inheritance is kept off the TestAction (`shouldUseLaunchSchemeArgsEnv=NO`).
