# ControlPlane

ControlPlane is a macOS **menu-bar agent** (`LSUIElement`) that picks a **Context** from evidence sources (Wi‑Fi, Bluetooth, USB, location, and more) and runs **Actions**.

This repository is the **[scottdensmore/ControlPlane](https://github.com/scottdensmore/ControlPlane)** fork of the classic Objective‑C / XIB app. Active development for Sequoia lives on the `macOS-15` branch. Upstream [`dustinrue/ControlPlane`](https://github.com/dustinrue/ControlPlane) may contain a separate Swift rewrite—do not assume shared code with this ObjC line.

## Requirements (macOS-15 line)

| Item | Value |
| :--- | :--- |
| Host OS | macOS 15 Sequoia (recommended for day-to-day work on this branch) |
| Xcode | 16 or newer |
| Deployment target | **14.5** (raising to 15.x is tracked separately; do not bump casually) |
| Project | `ControlPlane.xcodeproj` |
| Scheme | `ControlPlane` |

Targets of note: the main app, embedded `CPXPCService`, and privileged helper `CPHelperTool` (blessed via SMJobBless). Unsigned CI/local smoke builds **cannot** install the helper—see [docs/signing.md](docs/signing.md).

## Clone and Debug build

```bash
git clone https://github.com/scottdensmore/ControlPlane.git
cd ControlPlane
git checkout macOS-15
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

GitHub Actions workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on pushes and PRs targeting `macOS-15` and `master`:

- Debug `xcodebuild` of the app (`CODE_SIGNING_ALLOWED=NO`)
- `ControlPlaneTests` only (no helper bless)
- Basic Info.plist / architecture smoke

UI tests run in a separate quarantine workflow and are non-blocking. Details: [docs/TESTING.md](docs/TESTING.md).

## Docs map

| Doc | Purpose |
| :--- | :--- |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Issues, OS-line branching, localization, ARC |
| [AGENTS.md](AGENTS.md) | Full agent workflow (SSOT for coding agents) |
| [docs/TESTING.md](docs/TESTING.md) | Unit vs UI tests, smoke commands |
| [docs/signing.md](docs/signing.md) | Identities, entitlements, helper bless, notarization notes |
| [docs/releasing.md](docs/releasing.md) | Release checklist (archive, notarize, Sparkle, verify) |

## License / history

ControlPlane is free, open source software derived from MarcoPolo. Product history and older marketing pages may still point at controlplaneapp.com; **source of truth for this fork is GitHub**.
