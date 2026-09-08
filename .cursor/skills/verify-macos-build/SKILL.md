---
name: verify-macos-build
description: >-
  Run the ControlPlane verification gate: Debug and Release builds,
  ControlPlaneTests, and slice smoke. Use at workflow step 7 after
  implementation and after any later fix. Restart the whole gate when code
  changes.
---

# Verify macOS build

Workflow **step 7**. Read `AGENTS.md` and `docs/TESTING.md`.

If this gate finds a defect and code changes, **restart this entire skill**. A partial re-run is not a pass.

## Validate the instrument

A quiet log is not success. Confirm the command ran, the test bundle launched, and products came from this tree (fresh `-derivedDataPath` or a clean build). If a probe should fail and does not, treat that as a finding.

## Steps

1. Scheme `ControlPlane` in `ControlPlane.xcodeproj`.
2. Debug build:

   ```bash
   xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane \
     -configuration Debug -destination 'platform=macOS' \
     CODE_SIGNING_ALLOWED=NO build
   ```

3. Release build, same scheme.
4. New compiler warnings on touched files are findings unless they are pre-existing and noted.
5. Unit tests:

   ```bash
   xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane \
     -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO \
     test -only-testing:ControlPlaneTests
   ```

   Or `./scripts/smoke-build.sh` (Debug + Release + unit tests). `SKIP_RELEASE=1` is CI-shaped only; this gate still wants Release unless the host cannot run it, in which case say so.

6. UI journeys: `ControlPlaneUITests` are quarantined and **non-blocking** on CI. When the slice touches prefs, menus, or Help, run them or write the manual smoke. Do not fail this gate on a known quarantine failure unless this slice introduced it.
7. Smoke the affected evidence, action, prefs, or helper path, or list the exact manual steps.
8. Helper bless and notarization are not part of this gate. For a privileged slice, note whether a signed helper was already installed and whether bless was retested. See `docs/signing.md`.

## Report

Pass/fail for Debug, Release, `ControlPlaneTests`, smoke, and the instrument check.
