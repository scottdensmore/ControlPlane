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

## Uninstall / legacy helpers

- `Utilities/Uninstall.sh` — current `com.scottdensmore.CPHelperTool`
- `Utilities/remove_helper_tool.sh` — also removes legacy `com.dustinrue.*` labels

`Utilities/SMJobBlessUtil.py` is Apple’s old Python 2 checker and expects app-level `SMPrivilegedExecutables`; it does **not** match this XPC-bless topology. Do not treat it as the SSOT checker until a Python 3 rewrite exists (#46-adjacent).

## Explicit non-goals (follow-ups)

- Migrating blessing to `SMAppService` (later OS line)
- Replacing remaining helper `system()` / `sprintf` shelling with safer spawn APIs (prefer remove/gate commands first)
- Removing app `--deep` codesign flags (tracked with entitlements work, #48)
- Broadening helper command surface

## Automated checks

`HelperSigningRequirementTests` asserts source plists use team OU requirements and do not pin a personal Development CN. They do **not** perform SMJobBless.
