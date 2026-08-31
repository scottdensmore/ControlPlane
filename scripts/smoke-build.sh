#!/usr/bin/env bash
# Smoke build + unit tests for ControlPlane (macOS-15 line).
#
# CI (GitHub Actions) runs Debug build + ControlPlaneTests only — see
# .github/workflows/ci.yml. This script additionally builds Release locally.
#
# Signing/helper: no SMJobBless required. Pass CODE_SIGNING_ALLOWED=NO for
# unsigned CI/local smoke (default below). Do not expect privileged helper
# install in this script.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ControlPlaneSmokeDerived}"
PROJECT="$ROOT/ControlPlane.xcodeproj"
SCHEME="ControlPlane"
SIGN_ARGS=(CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=-)
SKIP_RELEASE="${SKIP_RELEASE:-0}"

rm -rf "$DERIVED"

echo "==> Debug build"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "$DERIVED" \
  "${SIGN_ARGS[@]}" build

if [[ "$SKIP_RELEASE" != "1" ]]; then
  echo "==> Release build"
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
    -destination 'platform=macOS' -derivedDataPath "$DERIVED" \
    "${SIGN_ARGS[@]}" build
fi

APP_DEBUG=$(find "$DERIVED/Build/Products/Debug" -name 'ControlPlane.app' -maxdepth 2 | head -1)
test -n "$APP_DEBUG"

echo "==> Archs (Debug)"
lipo -archs "$APP_DEBUG/Contents/MacOS/ControlPlane"

if [[ "$SKIP_RELEASE" != "1" ]]; then
  APP_RELEASE=$(find "$DERIVED/Build/Products/Release" -name 'ControlPlane.app' -maxdepth 2 | head -1)
  echo "==> Archs (Release) — may be x86_64-only until issue #38"
  lipo -archs "$APP_RELEASE/Contents/MacOS/ControlPlane" || true
fi

echo "==> Info.plist smoke (Debug)"
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_DEBUG/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$APP_DEBUG/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :NSBluetoothAlwaysUsageDescription' "$APP_DEBUG/Contents/Info.plist"

echo "==> Unit tests (ControlPlaneTests)"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "$DERIVED" \
  "${SIGN_ARGS[@]}" \
  test -only-testing:ControlPlaneTests

echo "SMOKE OK"
