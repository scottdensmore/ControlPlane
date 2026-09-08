# Signing, notarization, and privileged helper (macOS-16)

ControlPlane’s privileged path:

```text
Action → Action+XPCHelperTool
      → CPXPCService (embedded XPC)
         → SMJobBless → /Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool
         → returns Mach endpoint + AuthorizationExternalForm
      → app talks to CPHelperTool over that endpoint
```

`SMJobBless` is deprecated but still the supported install path in production. The Tahoe-line design spike for migrating to an `SMAppService` LaunchDaemon is in [smappservice-spike.md](smappservice-spike.md) (**GO**). App-side register/unregister lives in `CPHelperDaemonService`; privileged commands still use bless.

## Identities and Team ID

| Setting | Value |
| :--- | :--- |
| Team ID | `27ZDER873F` |
| App / XPC / helper | Same team; Development **or** Developer ID Application |
| CI / smoke | `CODE_SIGNING_ALLOWED=NO` — **cannot** bless unsigned builds |

Designated requirements use **team OU** (`certificate leaf[subject.OU] = "27ZDER873F"`) plus Apple Development **or** Developer ID intermediate OIDs — not a single person’s certificate CN.

| Plist | Key | Client / tool |
| :--- | :--- | :--- |
| `CPHelperTool/HelperTool-Info.plist` | `SMAuthorizedClients` | Must be `com.scottdensmore.CPXPCService` |
| `CPXPCService/Info.plist` | `SMPrivilegedExecutables` | Must be `com.scottdensmore.CPHelperTool` |

Blessing is performed by the **XPC service**, not the main app Info.plist.

## Hardened Runtime and Entitlements

All three binaries (ControlPlane.app, CPXPCService.xpc, com.scottdensmore.CPHelperTool) use hardened runtime with explicit entitlements:

| Target | Entitlements file | Key entitlements |
| :--- | :--- | :--- |
| ControlPlane | `ControlPlane.entitlements` | `com.apple.security.cs.disable-library-validation` (Sparkle) |
| CPXPCService | `CPXPCService/CPXPCService.entitlements` | none (empty hardened-runtime plist) |
| com.scottdensmore.CPHelperTool | `CPHelperTool/CPHelperTool.entitlements` | none (empty hardened-runtime plist) |

**Note:** `com.apple.security.cs.disable-library-validation` is **app-only**, required because Sparkle.framework is a separately-signed universal binary. Do **not** grant it to the privileged helper or XPC service. The app does **not** use `--deep` signing; `CodeSignOnCopy` covers Sparkle.framework, CPXPCService.xpc, and the helper.

**No App Sandbox.** ControlPlane requires non-sandboxed access for Wi-Fi (CoreWLAN), Bluetooth, USB (IOKit), and other evidence sources.

## Local signed build + bless smoke

1. Open `ControlPlane.xcodeproj` in Xcode with access to team `27ZDER873F`.
2. Build **Debug** or **Release** with signing enabled (do not pass `CODE_SIGNING_ALLOWED=NO`).
3. Optional clean slate: `./Utilities/Uninstall.sh`
4. Run the app; trigger a privileged action that still uses the helper (e.g. Display Sleep Time, Time Machine — not gated Firewall / Printer Sharing / sharing actions).
5. Complete the authorization / bless UI.
6. Confirm:
   - `/Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool` exists
   - `launchctl print system/com.scottdensmore.CPHelperTool` shows the job
7. Re-run unsigned CI-shaped smoke: `SKIP_RELEASE=1 ./scripts/smoke-build.sh`

## Notarization (release-shaped)

1. Archive with **Developer ID Application** for team `27ZDER873F`.
2. Notarize and staple the app (standard `notarytool` / Xcode Organizer flow).
3. On a fresh Mac: install, run, bless as above. Requirements must accept Developer ID (OID `1.2.840.113635.100.6.2.6`), not only Apple Development.

**Notarization notes:**

- All binaries use hardened runtime with entitlements (see table above).
- `disable-library-validation` is acceptable for notarization when Sparkle or other separately-signed frameworks are embedded.
- Sparkle.framework must be a properly-signed universal **Sparkle 2.x** binary (arm64 + x86_64) from upstream (currently 2.9.6).
- The app, XPC service, and helper tool are signed individually during the build via `CodeSignOnCopy`; no `--deep` flag is used.

## Uninstall / legacy helpers

- `Utilities/Uninstall.sh` — current `com.scottdensmore.CPHelperTool`
- `Utilities/remove_helper_tool.sh` — also removes legacy `com.dustinrue.*` labels

### SMJobBlessUtil (Python 3)

`Utilities/SMJobBlessUtil.py` is Apple’s classic SMJobBless checker, ported to **Python 3** (`#!/usr/bin/env python3`). It validates the textbook layout: helpers under `Contents/Library/LaunchServices` and app-level `SMPrivilegedExecutables`.

ControlPlane blesses via **CPXPCService**, so this util is **not** the SSOT for our topology. Prefer `HelperSigningRequirementTests` and the checklist above for day-to-day verification. Use the util when debugging a classic SMJobBless app layout or comparing against Apple’s sample:

```bash
python3 Utilities/SMJobBlessUtil.py --help
python3 Utilities/SMJobBlessUtil.py check /path/to/SomeApp.app
```

On this product, `check` against `ControlPlane.app` is expected to report a missing `Contents/Library/LaunchServices` tool directory (XPC-bless, not app-bless).

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

### Helper bless + privileged toggle smoke (manual)

CI cannot bless (`CODE_SIGNING_ALLOWED=NO`). On a signed Debug/Release build:

1. Optional clean slate: `./Utilities/Uninstall.sh`
2. Launch ControlPlane; trigger **Display Sleep Time** or another **active** privileged toggle (not a gated Firewall / Printer Sharing / sharing action).
3. Complete authorization / bless UI.
4. Confirm `/Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool` and `launchctl print system/com.scottdensmore.CPHelperTool`.
5. Confirm the toggle took effect (System Settings → Lock Screen, or `pmset -g`).

### Residual risks

- Helper still runs Apple CLIs as root; a compromised client that passes Authorization still gets those fixed operations.
- `launchctl load`/`unload` for SMB is legacy relative to `bootstrap`/`bootout`; revisit if smbd toggle fails on a future OS.
- `systemsetup -setremotelogin` behavior can change without notice; keep characterization tests and this inventory current per OS line.
- No App Sandbox (by design); see Hardened Runtime section above.

## Explicit non-goals (follow-ups)

- Migrating blessing to `SMAppService` (spike **GO**; see [smappservice-spike.md](smappservice-spike.md) — implement issue, not this doc)
- Broadening helper command surface
- Narrowing Sparkle so the app can drop `disable-library-validation`
- Rewriting the helper in Swift / typed non-CLI system APIs for every toggle

## Automated checks

`HelperSigningRequirementTests` asserts source plists use team OU requirements and do not pin a personal Development CN. They do **not** perform SMJobBless.

`CPHelperCommandRunnerTests` asserts helper sources no longer call `system()`/`sprintf`, validates display-sleep bounds, characterizes fixed argv arrays for active commands, and asserts Firewall/Printer Sharing stay gated with `ENOTSUP` (#124).

## Release checklist

For archive → notarize → Sparkle/appcast → `spctl` verification, see [releasing.md](releasing.md).
