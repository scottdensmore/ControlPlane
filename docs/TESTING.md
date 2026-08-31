# Testing ControlPlane

## Current status (macOS-15)

- **Debug build:** works (`xcodebuild -scheme ControlPlane -configuration Debug`)
- **Unit tests:** `ControlPlaneTests` logic bundle (no app host — avoids dual `NSApplication` crash with this LSUIElement agent)
- **UI tests:** `ControlPlaneUITests` target exists for prefs journeys; status-item clicks are unreliable under XCUITest
- **Smoke script:** `scripts/smoke-build.sh`
- **CI:** `.github/workflows/ci.yml` runs Debug build + `ControlPlaneTests` on PRs/`macOS-15`/`master` (no helper bless, `CODE_SIGNING_ALLOWED=NO`)

## Commands

```bash
# Unit tests only
xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane \
  -destination 'platform=macOS' -derivedDataPath /tmp/ControlPlaneDerived \
  CODE_SIGNING_ALLOWED=NO test -only-testing:ControlPlaneTests

# Full local smoke (Debug + Release + unit tests)
./scripts/smoke-build.sh

# CI-shaped smoke (skip Release)
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

## What day-1 unit tests cover

| Suite | Behavior |
| :--- | :--- |
| `SharedNumberFormatterTests` | Percent formatter singleton used in confidence UI |
| `CPSystemInfoTests` | `getOSVersion` encoding + hardware model |
| `CPNotificationsGateTests` | `EnableNotifications` gates `postUserNotification` |
| `CPNotificationsMigrationTests` | `EnableGrowl` migrates to `EnableNotifications` |
| `SparkleVendoredArchitectureTests` | Vendored `Sparkle.framework` is universal (`x86_64` + `arm64`) |

Additional test **sources** live under `ControlPlaneTests/` (Action registry, IPv4 match, Context model, applicability characterization, Packed IP). Wire them into the target as mock seams / stubs land — tracked by `macos-15` testing issues.

## User journeys to automate next

1. Launch → Preferences open (`Debug OpenPrefsAtStartup`)
2. Toggle Enable Notifications and assert defaults
3. Enable an evidence source row
4. Create a context + rule + mute action (end-to-end) with mocked evidence
5. Context switch confidence threshold behavior

## Gaps / follow-ups

See GitHub issues labeled `macos-15` + `testing` (or search “XCTest”). Do not expand host-based app tests until LaunchAction malloc/`libgmalloc` inheritance is kept off the TestAction (`shouldUseLaunchSchemeArgsEnv=NO`).
