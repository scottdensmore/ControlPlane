# Releasing ControlPlane (macOS-16 sketch)

This is a practical release checklist for the ObjC fork on the Tahoe / `macOS-16` line. Signing identities, entitlements, SMJobBless topology, and notarization **facts** live in [signing.md](signing.md)—read that first and do not contradict it here.

CI (`.github/workflows/ci.yml`) only proves unsigned Debug compile + `ControlPlaneTests` on `macos-26` runners. A shippable build is always a **local signed archive**.

## Preconditions

- [ ] On the correct tip (`macOS-16` for Tahoe line work, `macOS-15` for Sequoia maintenance, or `master` after an OS-line merge).
- [ ] Version bump intentional (`MARKETING_VERSION` / related plists)—coordinate with any open versioning issue.
- [ ] `./scripts/smoke-build.sh` green locally (or at least Debug + `ControlPlaneTests`).
- [ ] Team ID `27ZDER873F` Developer ID Application identity available (see [signing.md](signing.md)).
- [ ] Hardened Runtime + entitlements as documented; **no `--deep`** signing (removed; use `CodeSignOnCopy` for Sparkle / XPC / helper).
- [ ] Host toolchain is Xcode 26+ on macOS 26 Tahoe when cutting a `macOS-16` release.
- [ ] Maintainer EdDSA key present in Keychain (see [Sparkle / appcast](#sparkle--appcast) below). **Private keys are maintainer secrets**—never commit them or generate them in CI.

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

Vendored **Sparkle 2.9.6** (`Frameworks/Sparkle.framework`, universal `x86_64` + `arm64`). Unit tests assert architecture and that the framework reports a 2.x short version. Tools live in `Utilities/SparkleTools/` (`generate_keys`, `sign_update`, `generate_appcast`, `BinaryDelta`).

`Info.plist` keeps `SUFeedURL` → `https://www.controlplaneapp.com/appcast.xml`. Updating the feed host for this fork is a **separate** change—do not silently point production users at an unpublished feed.

### EdDSA keys (maintainer secret)

Sparkle 2 uses EdDSA (`ed25519`), not DSA.

1. On a secure maintainer Mac (once per organization):

   ```bash
   ./Utilities/SparkleTools/generate_keys
   ```

   This stores the **private** key in the login Keychain and prints the **public** key.

2. Add the public key to `Info.plist`:

   ```xml
   <key>SUPublicEDKey</key>
   <string>PASTE_BASE64_PUBLIC_KEY_HERE</string>
   ```

3. Confirm `SUPublicDSAKeyFile` is absent (DSA is not used for new releases). Legacy `Resources/legacy/dsa_pub.pem` is not shipped in the bundle.

4. Never commit Keychain exports (`generate_keys -x …`) or `SPARKLE_ED_KEY_FILE` contents. If automation needs a key file, keep it outside the repo and pass `SPARKLE_ED_KEY_FILE` only on the signing machine.

Until `SUPublicEDKey` is set, the app still **links and runs** Sparkle 2, but signed update installs cannot be verified—finish key setup before publishing an appcast.

### Sign an update archive

After notarizing a `.dmg` or `.zip`:

```bash
./Utilities/sparkle_sign_archive.sh /path/to/ControlPlane-N.dmg
```

Use the printed `sparkle:edSignature` (and length) on the appcast enclosure, or generate the whole feed:

```bash
mkdir -p /tmp/cp-appcast && cp /path/to/ControlPlane-N.dmg /tmp/cp-appcast/
./Utilities/SparkleTools/generate_appcast /tmp/cp-appcast
```

Legacy `Utilities/make_*_image.sh` scripts no longer call the old Ruby DSA signer; they point at this helper for release signing.

### Manual test: update N → N+1

1. Build and notarize version **N** with `SUPublicEDKey` set; install it on a test Mac (do not overwrite yet).
2. Build notarize version **N+1**; sign the archive with `sparkle_sign_archive.sh` / `generate_appcast`.
3. Host a **test** appcast (local HTTP is fine) whose enclosure points at the N+1 archive and includes `sparkle:edSignature`. Point the installed N build at that feed (temporary `defaults write` on `SUFeedURL`, or a Debug build with a localhost feed as in `make_debug_image.sh`).
4. Launch N → **Check For Updates…** → accept N+1 → relaunch.
5. Confirm the running app reports N+1 (`CFBundleShortVersionString` / About) and Gatekeeper still accepts the replaced bundle (`spctl --assess`).

## What release does *not* include

- Helper bless in CI (`CODE_SIGNING_ALLOWED=NO` cannot bless).
- Migrating SMJobBless → `SMAppService` (later OS line).
- Raising `MACOSX_DEPLOYMENT_TARGET` to **16.0** — deferred to #82; this branch remains at **15.0**.
- Publishing a production appcast or rotating the public marketing feed host (maintainer ops).

## Related docs

- [signing.md](signing.md) — identities, entitlements, bless smoke, notarization notes
- [TESTING.md](TESTING.md) — automated tests and smoke script
- [../README.md](../README.md) — clone → Debug build
- [../Utilities/SparkleTools/README.md](../Utilities/SparkleTools/README.md) — vendored Sparkle 2 CLI tools
