# Releasing ControlPlane (macOS 26 / deploy 16.0)

This is a practical release checklist for the ObjC fork targeting Tahoe / macOS 26 (`MACOSX_DEPLOYMENT_TARGET` **16.0**). Signing identities, entitlements, the `SMAppService` daemon, and notarization **facts** live in [signing.md](signing.md)—read that first and do not contradict it here. Unsigned builds cannot register the daemon.

GitHub Actions (`.github/workflows/ci.yml`) is kept but not triggered on push/PR. Prove unsigned Debug compile + `ControlPlaneTests` locally. A shippable build is always a **local signed archive**.

## Preconditions

- [ ] On the correct tip (`master` for current Tahoe work).
- [ ] Version bump intentional (`MARKETING_VERSION` / related plists)—coordinate with any open versioning issue.
- [ ] `./scripts/smoke-build.sh` green locally (or at least Debug + `ControlPlaneTests`).
- [ ] Team ID `27ZDER873F` Developer ID Application identity available (see [signing.md](signing.md)).
- [ ] Hardened Runtime + entitlements as documented; **no `--deep`** signing (removed; use `CodeSignOnCopy` for Sparkle / XPC / helper).
- [ ] Host toolchain is Xcode 26+ on macOS 26 Tahoe when cutting a release.
- [ ] Maintainer EdDSA key present in Keychain (see [Sparkle / appcast](#sparkle--appcast) below). **Private keys are maintainer secrets**—never commit them or generate them in CI.

## Archive and notarize

1. Archive **Release** in Xcode with **Developer ID Application** for team `27ZDER873F`.
2. Notarize and staple (`notarytool` or Xcode Organizer). Staple the `.app` (and any DMG/ZIP you distribute).
3. Confirm Gatekeeper acceptance on a clean Mac:

```bash
spctl --assess --type execute -v /path/to/ControlPlane.app
codesign -dv --verbose=4 /path/to/ControlPlane.app
```

4. Run a **signed** install smoke: allow the privileged helper in prefs / Login Items, trigger a privileged action, confirm the in-bundle daemon (not a blessed `/Library/PrivilegedHelperTools` copy) via `launchctl print system/com.scottdensmore.CPHelperTool` (details in [signing.md](signing.md)).

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

### Maintainer EdDSA checklist (required before every public update)

**Do not publish an appcast or ship a notarized build that expects Sparkle updates until every box is checked.**

- [ ] On a secure maintainer Mac (not CI), run:

  ```bash
  ./Utilities/SparkleTools/generate_keys --account controlplane-scottdensmore
  ```

  Prefer a dedicated `--account` for this fork so keys are not mixed with unrelated Sparkle apps.

- [ ] Confirm the **private** key remains only in the login Keychain (or an offline export kept outside the repo). Never commit Keychain exports (`generate_keys -x …`) or `SPARKLE_ED_KEY_FILE` contents.

- [ ] Copy the printed **public** key into `Info.plist` as `SUPublicEDKey` (base64 string). Do **not** invent a placeholder key.

  ```bash
  ./Utilities/SparkleTools/generate_keys -p --account controlplane-scottdensmore
  ```

- [ ] Verify the shipping Info.plist contains a non-empty `SUPublicEDKey` and does **not** contain `SUPublicDSAKeyFile`.

- [ ] Sign release archives with the matching private key (`Utilities/sparkle_sign_archive.sh` / `sign_update` / `generate_appcast`).

- [ ] Manual N → N+1 update test (below) passes on a clean Mac.

**Release gate:** If `SUPublicEDKey` is missing, **do not publish** Sparkle updates for this fork. The app may still build and run; signed update verification cannot work without the public key. Unit tests assert either a real key is present or this checklist forbids shipping unsigned updates.

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

- Helper registration in CI (`CODE_SIGNING_ALLOWED=NO` cannot register the daemon).
- Collapsing `CPXPCService` or deleting unused `SMJobBless` in `installHelperToolWithReply:` (not on the command path; see [smappservice-spike.md](smappservice-spike.md)).
- `MACOSX_DEPLOYMENT_TARGET` is **16.0** on current `master` (#82).
- Publishing a production appcast or rotating the public marketing feed host (maintainer ops).

## Related docs

- [signing.md](signing.md) — identities, entitlements, daemon registration, notarization notes
- [TESTING.md](TESTING.md) — automated tests and smoke script
- [../README.md](../README.md) — clone → Debug build
- [../Utilities/SparkleTools/README.md](../Utilities/SparkleTools/README.md) — vendored Sparkle 2 CLI tools
