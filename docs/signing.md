# Signing, notarization, and privileged helper (macOS-16)

ControlPlane’s privileged path:

```text
Action → CPHelperDaemonService status
      → if not Enabled: open System Settings → Login Items (no SMJobBless, no auto-register)
      → if Enabled: Action+XPCHelperTool
         → CPXPCService (embedded XPC; existing protocol + authorization)
            → Mach service com.scottdensmore.CPHelperTool
               (in-bundle Contents/Library/LaunchServices/com.scottdensmore.CPHelperTool)
      → app talks to CPHelperTool over that endpoint
```

The helper is an `SMAppService` LaunchDaemon (`CPHelperDaemonService`, plist `com.scottdensmore.CPHelperTool.plist` with `BundleProgram` and `AssociatedBundleIdentifiers`). The prefs checkbox registers and unregisters it; approval is Login Items (`RequiresApproval`). Privileged commands connect only when status is `Enabled`. `CPXPCService` remains the XPC broker and does not call `SMJobBless` — do not collapse it. The Tahoe-line design spike is [smappservice-spike.md](smappservice-spike.md) (**GO**).

## Identities and Team ID

| Setting | Value |
| :--- | :--- |
| Team ID | `27ZDER873F` |
| App / XPC / helper | Same team; Development **or** Developer ID Application |
| CI / smoke | `CODE_SIGNING_ALLOWED=NO` — **cannot** register or enable the daemon |

Designated requirements use **team OU** (`certificate leaf[subject.OU] = "27ZDER873F"`) plus Apple Development **or** Developer ID intermediate OIDs — not a single person’s certificate CN.

`CPHelperClientGate` is the client gate. The listener requirement admits `com.scottdensmore.CPXPCService` or `com.scottdensmore.ControlPlane`, team OU `27ZDER873F`, and either Apple Development or Developer ID intermediate. `SMAuthorizedClients` and `SMPrivilegedExecutables` are not present; they were the leftover SMJobBless plist contract.

## Hardened Runtime and Entitlements

All three binaries (ControlPlane.app, CPXPCService.xpc, com.scottdensmore.CPHelperTool) use hardened runtime with explicit entitlements:

| Target | Entitlements file | Key entitlements |
| :--- | :--- | :--- |
| ControlPlane | `ControlPlane.entitlements` | `com.apple.security.cs.disable-library-validation` (Sparkle) |
| CPXPCService | `CPXPCService/CPXPCService.entitlements` | none (empty hardened-runtime plist) |
| com.scottdensmore.CPHelperTool | `CPHelperTool/CPHelperTool.entitlements` | none (empty hardened-runtime plist) |

**Note:** `com.apple.security.cs.disable-library-validation` is **app-only**, required because Sparkle.framework is a separately-signed universal binary. Do **not** grant it to the privileged helper or XPC service. The app does **not** use `--deep` signing; `CodeSignOnCopy` covers Sparkle.framework, CPXPCService.xpc, and the helper.

**No App Sandbox.** ControlPlane requires non-sandboxed access for Wi-Fi (CoreWLAN), Bluetooth, USB (IOKit), and other evidence sources.

## Local signed build + helper smoke

1. Open `ControlPlane.xcodeproj` in Xcode with access to team `27ZDER873F`.
2. Build **Debug** or **Release** with signing enabled (do not pass `CODE_SIGNING_ALLOWED=NO`).
3. On upgrade from a blessed build, run `./Utilities/Uninstall.sh` first. It boots out `system/com.scottdensmore.CPHelperTool` and removes `/Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool` plus `/Library/LaunchDaemons/com.scottdensmore.CPHelperTool.plist` so two listeners never share the Mach name. It does not `launchctl disable` that label (disable persists across a later register). Use the prefs checkbox to unregister the SMAppService daemon.
4. Run the app. In Preferences, turn on **Allow privileged helper**. Approve it in System Settings → General → Login Items & Extensions. Do not expect a privileged action to register the daemon by itself.
5. Trigger a privileged action that still uses the helper (e.g. Display Sleep Time, Time Machine — not gated Firewall / Printer Sharing / sharing actions).
6. Confirm:
   - status is Enabled before the action connects
   - `/Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool` is **absent**
   - `launchctl print system/com.scottdensmore.CPHelperTool` shows the in-bundle daemon, not a blessed copy
7. Re-run unsigned CI-shaped smoke: `SKIP_RELEASE=1 ./scripts/smoke-build.sh`

## Notarization (release-shaped)

1. Archive with **Developer ID Application** for team `27ZDER873F`.
2. Notarize and staple the app (standard `notarytool` / Xcode Organizer flow).
3. On a fresh Mac: install, run, allow the helper in Login Items as above. Requirements must accept Developer ID (OID `1.2.840.113635.100.6.2.6`), not only Apple Development.

**Notarization notes:**

- All binaries use hardened runtime with entitlements (see table above).
- `disable-library-validation` is acceptable for notarization when Sparkle or other separately-signed frameworks are embedded.
- Sparkle.framework must be a properly-signed universal **Sparkle 2.x** binary (arm64 + x86_64) from upstream (currently 2.9.6).
- The app, XPC service, and helper tool are signed individually during the build via `CodeSignOnCopy`; no `--deep` flag is used.

## Uninstall / legacy helpers

- `Utilities/Uninstall.sh` — boots out `com.scottdensmore.CPHelperTool` and removes the blessed copies that share that Mach name. Does not `launchctl disable` (use the prefs checkbox to unregister).
- `Utilities/remove_helper_tool.sh` — same current-label cleanup, plus legacy `com.dustinrue.*` labels

On upgrade from an SMJobBless build, run `Uninstall.sh` before enabling the in-bundle daemon. The path list is `+[CPHelperDaemonService legacyBlessedInstallPaths]` (`/Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool` and `/Library/LaunchDaemons/com.scottdensmore.CPHelperTool.plist`). Tests assert that list; they do not run a live root uninstall.

### SMJobBlessUtil (Python 3)

`Utilities/SMJobBlessUtil.py` is Apple’s classic SMJobBless checker, ported to **Python 3** (`#!/usr/bin/env python3`). It validates the textbook layout: helpers under `Contents/Library/LaunchServices` and **app-level** `SMPrivilegedExecutables`.

That util is **not** the SSOT for this product. The helper binary is copied into `Contents/Library/LaunchServices` for the `SMAppService` `BundleProgram` (shipped in #165). A missing `Contents/Library/LaunchServices` directory is **not** the expected `check` result anymore. `check` against `ControlPlane.app` can still fail because the app Info.plist does not carry `SMPrivilegedExecutables` — registration is `SMAppService`, and the listener gate is `CPHelperClientGate`. Prefer `CPHelperDaemonServiceTests` and the checklist above. Use the util only when comparing against Apple’s classic SMJobBless sample:

```bash
python3 Utilities/SMJobBlessUtil.py --help
python3 Utilities/SMJobBlessUtil.py check /path/to/SomeApp.app
```

## CPHelperTool command inventory (#86)

Privileged commands no longer use `system()` / `sprintf` shelling. Survivors run via `CPHelperCommandRunner` (`posix_spawn` argv arrays). Dead sharing CLIs remain gated with `ENOTSUP` in the helper and `isActionApplicableToSystem` in the app.

| Helper method | Tool / API | Args (fixed unless noted) | Status on Tahoe |
| :--- | :--- | :--- | :--- |
| `enable`/`disableTimeMachine…` | `/usr/bin/tmutil` | `enable` / `disable` | Active |
| `start`/`stopBackupTimeMachine…` | `/usr/bin/tmutil` | `startbackup` / `stopbackup` | Active |
| `setDisplaySleepTime:…` | `/usr/bin/pmset` | `-a displaysleep <minutes>` | Active; minutes validated `0…1440` before spawn |
| `enable`/`disableSMBFileSharing…` | `/bin/launchctl` + `/usr/libexec/smb-sync-preferences` | `load\|unload -F` fixed `com.apple.smbd.plist` path | Active; pre-10.9 defaults path removed |
| `enable`/`disableRemoteLogin…` | `/usr/sbin/systemsetup` | `-setremotelogin on\|off` | Active (replaced `launchctl load` of `ssh.plist`) |
| Firewall / Printer Sharing / Internet Sharing / AFP / FTP / TFTP / Web Sharing | — | — | Gated (`ENOTSUP`); app actions not applicable (#124) |

**User-controlled input:** only display-sleep minutes (integer). It is range-checked and passed as its own argv element — never concatenated into a shell string.

### Helper daemon + privileged toggle smoke (manual)

CI cannot register the daemon (`CODE_SIGNING_ALLOWED=NO`). On a signed Debug/Release build:

1. Upgrade from a blessed build: `./Utilities/Uninstall.sh` (bootout + remove the two legacy paths; no `launchctl disable`). Confirm `/Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool` is gone.
2. Launch ControlPlane; turn on **Allow privileged helper** and approve it in Login Items. A privileged action must not register or bless on its own.
3. Trigger **Display Sleep Time** or another **active** privileged toggle (not a gated Firewall / Printer Sharing / sharing action).
4. If the daemon is not Enabled, the action opens Login Items and does not connect.
5. When Enabled, confirm `launchctl print system/com.scottdensmore.CPHelperTool` and that the toggle took effect (System Settings → Lock Screen, or `pmset -g`).

### Residual risks

- Helper still runs Apple CLIs as root; a compromised client that passes Authorization still gets those fixed operations.
- `launchctl load`/`unload` for SMB is legacy relative to `bootstrap`/`bootout`; revisit if smbd toggle fails on a future OS.
- `systemsetup -setremotelogin` behavior can change without notice; keep characterization tests and this inventory current per OS line.
- No App Sandbox (by design); see Hardened Runtime section above.

## Explicit non-goals (follow-ups)

- Collapsing `CPXPCService` (it still brokers XPC and does not call `SMJobBless`)
- Broadening helper command surface
- Narrowing Sparkle so the app can drop `disable-library-validation`
- Rewriting the helper in Swift / typed non-CLI system APIs for every toggle

## Automated checks

`HelperSigningRequirementTests` asserts helper and XPC Info.plists omit leftover `SMAuthorizedClients` / `SMPrivilegedExecutables`. `CPHelperClientGateTests` asserts the listener requirement (both identifiers, team OU, both intermediates, set before resume). They do **not** register the daemon.

`CPHelperDaemonServiceTests` asserts privileged commands connect only when status is Enabled, the command path does not call `SMJobBless`, and legacy cleanup names the blessed helper and launchd job. They do **not** register or uninstall live.

`CPHelperCommandRunnerTests` asserts helper sources no longer call `system()`/`sprintf`, validates display-sleep bounds, characterizes fixed argv arrays for active commands, and asserts Firewall/Printer Sharing stay gated with `ENOTSUP` (#124).

## Release checklist

For archive → notarize → Sparkle/appcast → `spctl` verification, see [releasing.md](releasing.md).
