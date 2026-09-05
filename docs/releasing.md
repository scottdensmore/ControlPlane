# Releasing ControlPlane (macOS-15 sketch)

This is a practical release checklist for the ObjC fork. Signing identities, entitlements, SMJobBless topology, and notarization **facts** live in [signing.md](signing.md)—read that first and do not contradict it here.

CI (`.github/workflows/ci.yml`) only proves unsigned Debug compile + `ControlPlaneTests`. A shippable build is always a **local signed archive**.

## Preconditions

- [ ] On the correct tip (`macOS-15` for Sequoia line work, or `master` after an OS-line merge).
- [ ] Version bump intentional (`MARKETING_VERSION` / related plists)—coordinate with any open versioning issue.
- [ ] `./scripts/smoke-build.sh` green locally (or at least Debug + `ControlPlaneTests`).
- [ ] Team ID `27ZDER873F` Developer ID Application identity available (see [signing.md](signing.md)).
- [ ] Hardened Runtime + entitlements as documented; **no `--deep`** signing (removed; use `CodeSignOnCopy` for Sparkle / XPC / helper).

## Archive and notarize

1. Archive **Release** in Xcode with **Developer ID Application** for team `27ZDER873F`.
2. Notarize and staple (`notarytool` or Xcode Organizer). Staple the `.app` (and any DMG/ZIP you distribute).
3. Confirm Gatekeeper acceptance on a clean Mac:

```bash
spctl --assess --type execute -v /path/to/ControlPlane.app
codesign -dv --verbose=4 /path/to/ControlPlane.app
```

4. Run a **signed** install smoke: launch, trigger a privileged action that still uses the helper, complete bless UI, confirm `/Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool` and `launchctl print system/com.scottdensmore.CPHelperTool` (details in [signing.md](signing.md)).

## Sparkle / appcast

- Vendored `Sparkle.framework` must remain a properly signed **universal** binary (`x86_64` + `arm64`); unit tests cover architecture.
- `Info.plist` still references `SUFeedURL` → `https://www.controlplaneapp.com/appcast.xml`. Updating the feed host, DSA/EdDSA keys, or appcast publishing for this fork is a **separate** change—do not silently point production users at an unpublished feed.
- When you do publish an update: upload the notarized artifact, publish a matching appcast item, and verify Sparkle’s update UI on a machine that already has the previous build.

## What release does *not* include

- Helper bless in CI (`CODE_SIGNING_ALLOWED=NO` cannot bless).
- Migrating SMJobBless → `SMAppService` (later OS line).
- Raising `MACOSX_DEPLOYMENT_TARGET` to 15.x (tracked separately).

## Related docs

- [signing.md](signing.md) — identities, entitlements, bless smoke, notarization notes
- [TESTING.md](TESTING.md) — automated tests and smoke script
- [../README.md](../README.md) — clone → Debug build
