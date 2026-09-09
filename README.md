# ControlPlane

ControlPlane is a macOS **menu-bar agent** (`LSUIElement`) that picks a **Context** from evidence sources (Wi‑Fi, Bluetooth, USB, location, Focus, power, and more) and runs **Actions** (including **Run Shortcut** / **Set Focus** via Shortcuts). Shortcuts and Spotlight can force a named context with the **Switch Context** App Intent.

This repository is the **[scottdensmore/ControlPlane](https://github.com/scottdensmore/ControlPlane)** fork of the classic Objective‑C / XIB app. Development integrates on **`master`** (short-lived feature branches). Upstream [`dustinrue/ControlPlane`](https://github.com/dustinrue/ControlPlane) may contain a separate Swift rewrite—do not assume shared code with this ObjC line.

## Requirements

| Item | Value |
| :--- | :--- |
| Host OS | macOS 26 Tahoe (recommended for day-to-day work) |
| Xcode | **26+** (CI uses the default Xcode on `macos-26` runners) |
| Deployment target | **16.0** |
| Project | `ControlPlane.xcodeproj` |
| Scheme | `ControlPlane` |

Targets of note: the main app, embedded `CPXPCService` (XPC broker), and privileged helper `CPHelperTool` (an `SMAppService` LaunchDaemon registered from General settings). Unsigned CI/local smoke builds **cannot register the daemon**—see [docs/signing.md](docs/signing.md).

## Clone and Debug build

```bash
git clone https://github.com/scottdensmore/ControlPlane.git
cd ControlPlane
git checkout master
open ControlPlane.xcodeproj
```

In Xcode: select the **ControlPlane** scheme → **My Mac** → **Product → Build** (Debug).

Or from the command line (unsigned, CI-shaped):

```bash
xcodebuild \
  -project ControlPlane.xcodeproj \
  -scheme ControlPlane \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=- \
  build
```

Full local smoke (Debug + Release + unit tests):

```bash
./scripts/smoke-build.sh
# CI-shaped (skip Release):
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

## Continuous integration

GitHub Actions workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml) is **not running** on pushes or PRs (manual `workflow_dispatch` only) to save Actions minutes. Verify locally. When re-enabled it covers:

- Debug `xcodebuild` of the app (`CODE_SIGNING_ALLOWED=NO`)
- `ControlPlaneTests` only (unsigned builds cannot register the daemon)
- Basic Info.plist / architecture smoke

### Runner matrix

| GitHub `runs-on` | Host OS | Notes |
| :--- | :--- | :--- |
| `macos-26` | macOS 26 Tahoe | **Current CI image** (Xcode 26.x default) |
| `macos-15` | macOS 15 Sequoia | Available if a Tahoe runner is unavailable |

There is no `macos-16` label; GitHub names Tahoe images `macos-26` (marketing version). UI tests run in a separate quarantine workflow and are non-blocking. Details: [docs/TESTING.md](docs/TESTING.md).

## Docs map

| Doc | Purpose |
| :--- | :--- |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Issues, branching, localization, ARC |
| [AGENTS.md](AGENTS.md) | Full agent workflow (SSOT for coding agents) |
| [docs/TESTING.md](docs/TESTING.md) | Unit vs UI tests, smoke commands |
| [docs/signing.md](docs/signing.md) | Identities, entitlements, SMAppService daemon registration, notarization notes |
| [docs/releasing.md](docs/releasing.md) | Release checklist (archive, notarize, Sparkle, verify) |

## License / history

ControlPlane is free, open source software derived from MarcoPolo. Product history and older marketing pages may still point at controlplaneapp.com; **source of truth for this fork is GitHub**.
