# Testing ControlPlane

## Current status (macOS-16 / Tahoe)

- **Debug build:** works (`xcodebuild -scheme ControlPlane -configuration Debug`)
- **Unit tests:** `ControlPlaneTests` logic bundle (no app host — avoids dual `NSApplication` crash with this LSUIElement agent)
- **UI tests:** `ControlPlaneUITests` for prefs journeys; status-item clicks are unreliable under XCUITest
- **Smoke script:** `scripts/smoke-build.sh`
- **GitHub Actions:** not used. Verify locally with `./scripts/smoke-build.sh`.
- **Signing / helper daemon:** see [`docs/signing.md`](signing.md) (manual signed smoke; unsigned builds cannot register the daemon)

## Commands

```bash
# Unit tests only
xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane \
  -destination 'platform=macOS' -derivedDataPath /tmp/ControlPlaneDerived \
  CODE_SIGNING_ALLOWED=NO test -only-testing:ControlPlaneTests

# UI tests (prefs journeys; set CPUITestRunning to skip notification auth UI).
# Prefer ad-hoc signing for the UITest runner — CODE_SIGNING_ALLOWED=NO often
# kills ControlPlaneUITests-Runner before it can bootstrap on current macOS.
xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane \
  -destination 'platform=macOS' -derivedDataPath /tmp/ControlPlaneDerived \
  CODE_SIGN_IDENTITY=- test -only-testing:ControlPlaneUITests

# Full local smoke (Debug + Release + unit tests)
./scripts/smoke-build.sh

# Debug + unit tests only (skip Release)
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

## What unit tests cover

| Suite | Behavior |
| :--- | :--- |
| `SharedNumberFormatterTests` | Percent formatter singleton used in confidence UI |
| `PrefsHIGShortTermTests` | Prefs a11y labels, agent menu shortcuts, standard About, Help accuracy (#31) |
| `CPUITestHarnessTests` | Settings UITest harness: OpenPrefsAtStartup → `runPreferences:`, `CPUITestRunning` auth skip + Regular activation policy, AX ids, docs (#202) |
| `CPForceContextUITestHookTests` | Force Context UITest hook: `Debug ForceContextAtStartup` + `UITestForceContext` notification → `forceSwitchToContextNamed:`, gated listener, AX id, docs (#244) |
| `PrefsSettingsStyleShellTests` | Settings-style `NSTabViewController` shell presence + pane/⌘, continuity (#100) |
| `CPMenuBarImageTests` | Menu-bar template prep (#89); Asset Catalog template/brand/AppIcon + button API checks (#32) |
| `CPSystemInfoTests` | `getOSVersion` encoding + hardware model; IOKit display bridge null-ID safety (#88) |
| `CPNotificationsGateTests` | `EnableNotifications` gates `postUserNotification` |
| `CPNotificationsMigrationTests` | `EnableGrowl` migrates to `EnableNotifications` |
| `SparkleVendoredArchitectureTests` | Vendored `Sparkle.framework` is Sparkle 2.x + universal (`x86_64` + `arm64`); `Info.plist` has no `SUPublicDSAKeyFile` |
| `InfoPlistPrivacyTests` | TCC usage strings present (Location mentions Wi‑Fi SSID); ATS no longer allows arbitrary loads |
| `CPLoginItemServiceTests` | SMAppService status → Start at Login checkbox mapping |
| `CPHelperDaemonServiceTests` | SMAppService daemon status → helper checkbox; command path connects only when Enabled (no SMJobBless); legacy bless path list; LaunchDaemon plist layout (no live register) |
| `RetiredSharingActionTests` | FTP/TFTP/Web/Internet Sharing gated; SMB-only file sharing; legacy AFP fails clearly |
| `ActionTypeRegistryTests` | Action type ↔ class map + `actionFromDictionary` |
| `RunShortcutActionTests` | Run Shortcut (#34) type map, applicability gate, empty-name failure |
| `ToggleableActionTests` | Toggleable parameter parsing (`NSNumber` / `"on"` / `"0"`) via MuteAction |
| `ApplicabilityCharacterizationTests` | Retired sharing + Screen Saver Password + Natural Scrolling + Toggle Bluetooth + Display Brightness + TM Destination + Network Location/VPN/Firewall Rule + Notification Center Alerts/DND gated; clear execute failures |
| `OrphanHygieneTests` | #133: IPEvidenceSource removed; FirewallRule/VPN archived tests-only and omitted from shipping registry |
| `PackedIPAddressTests` | IPv4/IPv6 pack validation |
| `IPv4RuleMatchTests` | Subnet rule matching via injected addresses |
| `ContextModelTests` | Context UUID, root flag, dictionary round-trip |
| `CPContextAppIntentTests` | Switch Context menu-name tokens, Help tip, LSUIElement; sandbox assertion flips when enable-sandbox lands ([sandbox-store-spike.md](sandbox-store-spike.md)) |
| `WiFiRuleMatchTests` | SSID matching with injected CoreWLAN state; Location-denied empty collection; Location TCC helper messages (#84) |
| `LightEvidenceSourceTests` | Light gates on `AppleLMUController`; unavailable path does not collect / crash (#122) |
| `USBRuleMatchTests` | Vendor/product matching with injected device list |
| `PowerRuleMatchTests` | Battery vs A/C matching via `setPowerStatusForTesting:` |
| `DisplayCountRuleMatchTests` | Display count (≥2 / external) and arrangement fingerprint via injected `NSScreen`/`CGDisplay` descriptors (#132) |
| `TimeOfDayRuleMatchTests` | Weekday time-window matching with injected clock |
| `ScreenLockRuleMatchTests` | Lock/unlock matching via `setScreenLockedForTesting:` / direct `screenDidLock:` (no live distributed notifies) (#130) |
| `RemoteDesktopRuleMatchTests` | Yes/No matching via `setUserConnectedForTesting:` / injected `ViewerNames` userInfo (no live distributed notifies) (#130) |
| `HelperSigningRequirementTests` | Helper/XPC Info.plists omit leftover SMAuthorizedClients / SMPrivilegedExecutables (listener gate: `CPHelperClientGateTests`) |
| `CPHelperCommandRunnerTests` | Helper argv-array runner: no `system()`/`sprintf` in `CPHelperTool.m`; display-sleep validation; fixed firewall/`tmutil`/SMB/remote-login args (#86); remote-login live CLI is fragile — see #261 / signing.md |
| `HelpScrubTests` | Help book links to this fork; no Growl-as-current guidance (#45); Wi‑Fi Location guidance (#84) |
| `CPConfigTransferTests` | Versioned config export/import round-trip (#35) |
| `CPDiagnosticsSnapshotTests` | Diagnostics snapshot explains mis-switched context / per-rule contribution (#35) |
| `CPMockEvidenceJourneyTests` | Injected evidence → confidence threshold → stubbed Mute / RunShortcut arrival (#135) |
| `DSLoggerTests` | Unified logging subsystem string + categories; ring buffer still captures (#35) |

Manual/script: `./scripts/check-help-scrub.sh` greps Help HTML for `dustinrue/ControlPlane` and Growl recommendation phrases.

## UITest harness

Deterministic Settings and Force Context entry for UITests (#202, #244). **Do not** click menu-bar pixel positions or the status item under XCUITest — that path is flaky for `LSUIElement` agents. Stay on AppKit `NSStatusItem` (no `MenuBarExtra`); see [`menubarextra-spike.md`](menubarextra-spike.md).

| Hook | Role |
| :--- | :--- |
| `CPUITestRunning=1` (launch environment) | Skips notification authorization prompts in `CPNotifications`; sets `NSApplicationActivationPolicyRegular` in `main` so XCUITest can attach to the `LSUIElement` agent; enables the Force Context distributed-notification listener |
| `-Debug OpenPrefsAtStartup YES` (launch argument) | After launch, opens Settings via `PrefsWindowController` `runPreferences:` (same path as the status-menu item) |
| `-Debug ForceContextAtStartup <token>` (launch argument) | After launch, forces a context via `forceSwitchToContextNamed:` (same path as the Force Context menu / Switch Context App Intent). `<token>` is the Force Context menu name (unique name, or `Parent/Child` when names collide). Empty / omitted = off |
| `com.scottdensmore.ControlPlane.UITestForceContext` (distributed notification) | Mid-session Force Context without relaunch. Only observed when `CPUITestRunning=1`. `userInfo[@"name"]` (or `object` string) is the menu token; handler calls `forceSwitchToContextNamed:` |
| `prefs.window` (AX id) | Stable query for the Settings window in `ControlPlaneUITests` |
| `status.menu.forceContext` (AX id) | Force Context submenu parent (VoiceOver / future menu hosting; **not** a substitute for the launch/notification hooks — do not open the status menu via geometry clicks) |

```bash
# Smoke: app launches and Settings appears
xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane \
  -destination 'platform=macOS' -derivedDataPath /tmp/ControlPlaneDerived \
  CODE_SIGN_IDENTITY=- test \
  -only-testing:ControlPlaneUITests/ControlPlaneUITests/testLaunchAndOpenPreferences
```

Post Force Context from a UITest (after a named context exists):

```objc
[[NSDistributedNotificationCenter defaultCenter]
    postNotificationName:@"com.scottdensmore.ControlPlane.UITestForceContext"
                  object:nil
                userInfo:@{ @"name": @"Home" }
      deliverImmediately:YES];
```

Unit contracts: `ControlPlaneTests/CPUITestHarnessTests` (#202), `ControlPlaneTests/CPForceContextUITestHookTests` (#244).

The shared scheme’s **Test** action uses PosixSpawn (no LLDB attach). That avoids “does not have a process ID” failures when launching the agent under `xcodebuild test`. `ControlPlaneUITests` also retries cold attach once or twice — the first launch after a clean DerivedData build can still race.

**#244 closed:** the Force Context automation hook above is available for journeys. Full Force Context UITest (seed context → force → assert active UI) remains [#206](https://github.com/scottdensmore/ControlPlane/issues/206).

## UI test accessibility identifiers

| Identifier | Control |
| :--- | :--- |
| `prefs.window` | Preferences / Settings window |
| `prefs.settingsShell` | Settings-style prefs shell (`NSTabViewController` host view) |
| `prefs.general.useNotifications` | Use Notifications checkbox |
| `prefs.general.startAtLogin` | Start ControlPlane at login checkbox |
| `prefs.tab.general` | General tab content view |
| `prefs.tab.evidencesources` | Evidence Sources tab content view |
| `prefs.toolbar.*` | Preference toolbar items (e.g. `prefs.toolbar.general`, `prefs.toolbar.evidencesources`) |
| `status.menu.forceContext` | Force Context submenu parent in the status menu |

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

## Light / AppleLMUController (#122)

Ambient light evidence depends on undocumented `AppleLMUController`. On machines without that IOKit service (common on Apple silicon), `LightEvidenceSource` is not registered (`isEvidenceSourceApplicableToSystem` → NO). Unit tests cover the IOKit probe and the unavailable `doUpdate` path (`initForUnavailableLMUTesting`). Manual: Preferences → Evidence Sources should omit Light when LMU is absent; Help → Evidence Sources documents the limitation.

## Toggle Remote Login / `systemsetup` fragility (#261)

Toggle Remote Login is still **applicable** and runs through the privileged helper via fixed argv:

`/usr/sbin/systemsetup -setremotelogin on|off` (see `CPHelperCommandRunner` / `docs/signing.md`).

There is no public Remote Login API. Apple’s CLI is fragile on current macOS:

- Man page: `-setremotelogin` requires Full Disk Access; use `-f` to suppress the disable prompt — the helper does **not** pass `-f`.
- CI only characterizes argv (`CPHelperCommandRunnerTests`); it does **not** spawn `systemsetup` or flip SSH.
- Do not invent CI signing to “prove” the toggle.

### Manual probe (signed Debug/Release, helper Enabled)

1. Enable **Allow privileged helper** and approve Login Items (see `docs/signing.md`).
2. Add a **Toggle Remote Login** action; force a context that runs it on/off.
3. Confirm System Settings → General → Sharing → Remote Login matches the intended state (or `systemsetup -getremotelogin` in Terminal).
4. If the action fails or hangs on **off**, check Console / `log stream` for subsystem `com.scottdensmore.ControlPlane` category `Helper`, and fall back to System Settings. Prefer not treating live SSH flips as automated coverage.

Help: Actions → Toggle Remote Login (links Diagnostics).

## Screen Lock + Remote Desktop fragility (#130)

Both sources listen for **undocumented** distributed notifications. CI and `ControlPlaneTests` **must not** post or wait on live notifies; match logic is covered by injectable stubs (`ScreenLockRuleMatchTests`, `RemoteDesktopRuleMatchTests`).

| Source | Notification(s) | Default until first notify | Fallback |
| :--- | :--- | :--- | :--- |
| Screen Lock | `com.apple.screenIsLocked` / `com.apple.screenIsUnlocked` | Unlocked | `DSLog` on start; warning if none arrive ~90s after start |
| Remote Desktop | `com.apple.remotedesktop.viewerNames` (`ViewerNames`) | No viewer connected | Same pattern |

### Manual probe (Tahoe)

1. Enable **Screen Lock** evidence; lock and unlock the Mac; confirm lock/unlock rules flip and Console shows lock-related ControlPlane lines.
2. Enable **Remote Desktop**; start/stop Screen Sharing from another Mac (or stop sharing); confirm Yes/No rules flip when `ViewerNames` updates.
3. If an OS update stops posting these names, expect the ~90s “has not received …” warning and switch rules to other evidence.

## Focus Status (#128)

Public `INFocusStatusCenter` exposes only whether Focus is **on or off** (`isFocused`). Named modes (Work, Sleep, …) are not readable — use Set Focus / Run Shortcut. There is no public Focus-change notification; ControlPlane refreshes on wake and polls every 30s as a fallback. If Focus Status is denied in System Settings → Privacy & Security → Focus, rules treat Focus as off. Unit: `testFocusPollIntervalIsFallbackNotAggressive`.

## Mock-evidence E2E (#135)

CI covers the single-context path without live hardware, CoreAudio, or the Shortcuts CLI. `CPEvidenceSwitchJourney` is the seam; `CPController` uses the same guess / leading-context helpers when it updates for real.

Injection (either form):

1. **Evidence-source testing setter** — create a source with `initForMatchingTests`, call the existing setter (for example `-[PowerEvidenceSource setPowerStatusForTesting:]`), then set `evidenceMatcher` to `doesRuleMatch:`.
2. **Direct observation** — `injectEvidenceWithType:parameter:` (for example type `Power`, parameter `Battery`). A rule of that type matches only when its parameter equals the injected value. Unknown types stay unmatched (negate does not flip unknown).

`evaluate` then:

- collects matching rules (same negate rule as `CPController`)
- computes confidence with the production unconfidence formula (`1 - Π(1 - rule.confidence)`, slight depth decay)
- switches only if the leading context is at least `minimumConfidenceRequired` (default 0.75) and is not already active
- runs enabled **Arrival** / **Both** actions through `actionExecutor`

Stub Mute or RunShortcut in the executor (record type / parameter and return YES). Do not call `-[Action execute:]` — that would mute the Mac or launch `/usr/bin/shortcuts`.

```objc
PowerEvidenceSource *power = [[PowerEvidenceSource alloc] initForMatchingTests];
[power setPowerStatusForTesting:@"Battery"];
journey.evidenceMatcher = ^BOOL(NSDictionary *rule) {
    return [power doesRuleMatch:rule];
};
journey.actionExecutor = ^BOOL(NSDictionary *action, NSString **error) {
    // action[@"type"] is @"Mute" or @"RunShortcut"
    return YES;
};
[journey evaluate];
```

Unit: `CPMockEvidenceJourneyTests` (part of `ControlPlaneTests`, so it runs in CI).

## Gaps / follow-ups

- Confidence threshold behavior under UI test (logic is covered by `CPMockEvidenceJourneyTests`; prefs slider is not)
- Promote `ControlPlaneUITests` from quarantine to blocking CI when stable on `macOS-16` runners

Do not expand host-based app tests until LaunchAction malloc/`libgmalloc` inheritance is kept off the TestAction (`shouldUseLaunchSchemeArgsEnv=NO`).


### Run Shortcut (#34)

1. Confirm `/usr/bin/shortcuts` exists (`which shortcuts`).
2. In Shortcuts, create a shortcut that shows a notification (e.g. **CP Test Notify**).
3. Preferences → Actions → add **Run Shortcut**, parameter `CP Test Notify`, arrival on a test context.
4. Force that context from the status menu; confirm the Shortcut runs and ControlPlane does not error.
5. Clear the parameter / use a blank name and trigger — confirm a clear failure message.
6. Optional: `shortcuts list --show-identifiers` and run by UUID via the same action.
