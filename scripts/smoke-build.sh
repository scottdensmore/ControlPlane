#!/usr/bin/env bash
# Smoke build + unit tests for ControlPlane (macOS-15 line).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ControlPlaneSmokeDerived}"
PROJECT="$ROOT/ControlPlane.xcodeproj"
SCHEME="ControlPlane"

rm -rf "$DERIVED"

echo "==> Debug build"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "$DERIVED" build

echo "==> Release build"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -destination 'platform=macOS' -derivedDataPath "$DERIVED" build

APP_DEBUG=$(find "$DERIVED/Build/Products/Debug" -name 'ControlPlane.app' -maxdepth 2 | head -1)
APP_RELEASE=$(find "$DERIVED/Build/Products/Release" -name 'ControlPlane.app' -maxdepth 2 | head -1)

echo "==> Archs (Debug)"
lipo -archs "$APP_DEBUG/Contents/MacOS/ControlPlane"

echo "==> Archs (Release) — may be x86_64-only until issue #38"
lipo -archs "$APP_RELEASE/Contents/MacOS/ControlPlane" || true

echo "==> Info.plist smoke (Debug)"
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_DEBUG/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$APP_DEBUG/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :NSBluetoothAlwaysUsageDescription' "$APP_DEBUG/Contents/Info.plist"

echo "==> Unit tests (ControlPlaneTests)"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "$DERIVED" \
  test -only-testing:ControlPlaneTests

echo "SMOKE OK"
