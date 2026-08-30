---
name: verify-macos-build
description: >-
  Run ControlPlane verification gates: Debug/Release builds, tests, and smoke
  checks for the target macOS branch. Use after implementation and after any
  fix from review; re-run fully when code changes.
---

# Verify macOS build skill

## Rule

If verification finds a defect and code changes, **restart this entire skill** after the fix. Do not trust a partial re-run.

## Steps

1. Confirm scheme/config: `ControlPlane` in `ControlPlane.xcodeproj`.
2. Build Debug:

   ```bash
   xcodebuild -project ControlPlane.xcodeproj -scheme ControlPlane -configuration Debug build
   ```

3. Build Release (same scheme, `Release`).
4. Treat **new** compiler warnings on touched files as failures unless pre-existing and noted.
5. Run unit/UI tests if targets exist (`xcodebuild test …`). If none, say so explicitly.
6. Smoke the slice on the target OS (or note manual steps for the human):
   - Launch agent; open Preferences.
   - Exercise affected evidence source / action / notification / login item / helper path.
7. Confirm the probe actually ran (fresh build products; no silent no-op).
8. Report: pass/fail table for build Debug, build Release, tests, smoke.

## Helper / signing

Do not require a full SMJobBless on CI. For local privileged slices, document whether helper was already installed and whether bless was retested.
