# Signing, notarization, and privileged helper (macOS-15)

ControlPlane’s privileged path:

```text
Action → Action+XPCHelperTool
      → CPXPCService (embedded XPC)
         → SMJobBless → /Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool
         → returns Mach endpoint + AuthorizationExternalForm
      → app talks to CPHelperTool over that endpoint
```

`SMJobBless` is deprecated but still the supported path on this branch. A future OS line may migrate to `SMAppService` daemon registration; that is **not** done here (spike decision: stay on SMJobBless for macOS-15).

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
4. Run the app; trigger a privileged action that still uses the helper (e.g. Display Sleep Time, Firewall, Time Machine — not gated sharing actions).
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
- Sparkle.framework must be a properly-signed universal binary (arm64 + x86_64) from upstream.
- The app, XPC service, and helper tool are signed individually during the build via `CodeSignOnCopy`; no `--deep` flag is used.

## Uninstall / legacy helpers

- `Utilities/Uninstall.sh` — current `com.scottdensmore.CPHelperTool`
- `Utilities/remove_helper_tool.sh` — also removes legacy `com.dustinrue.*` labels

`Utilities/SMJobBlessUtil.py` is Apple’s old Python 2 checker and expects app-level `SMPrivilegedExecutables`; it does **not** match this XPC-bless topology. Do not treat it as the SSOT checker until a Python 3 rewrite exists (#46-adjacent).

## Explicit non-goals (follow-ups)

- Migrating blessing to `SMAppService` (later OS line)
- Replacing remaining helper `system()` / `sprintf` shelling with safer spawn APIs (prefer remove/gate commands first)
- Broadening helper command surface
- Narrowing Sparkle so the app can drop `disable-library-validation`

## Automated checks

`HelperSigningRequirementTests` asserts source plists use team OU requirements and do not pin a personal Development CN. They do **not** perform SMJobBless.

## Release checklist

For archive → notarize → Sparkle/appcast → `spctl` verification, see [releasing.md](releasing.md).
