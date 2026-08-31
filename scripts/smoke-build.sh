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

SPARKLE_DEBUG="$APP_DEBUG/Contents/Frameworks/Sparkle.framework/Versions/Current/Sparkle"
if [[ -f "$SPARKLE_DEBUG" ]]; then
  echo "==> Sparkle archs (Debug bundle)"
  lipo -archs "$SPARKLE_DEBUG"
fi

if [[ "$SKIP_RELEASE" != "1" ]]; then
  APP_RELEASE=$(find "$DERIVED/Build/Products/Release" -name 'ControlPlane.app' -maxdepth 2 | head -1)
  echo "==> Archs (Release)"
  lipo -archs "$APP_RELEASE/Contents/MacOS/ControlPlane" || true
  SPARKLE_RELEASE="$APP_RELEASE/Contents/Frameworks/Sparkle.framework/Versions/Current/Sparkle"
  if [[ -f "$SPARKLE_RELEASE" ]]; then
    echo "==> Sparkle archs (Release bundle)"
    lipo -archs "$SPARKLE_RELEASE"
  fi
fi

echo "==> Info.plist smoke (Debug)"
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_DEBUG/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$APP_DEBUG/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :NSBluetoothAlwaysUsageDescription' "$APP_DEBUG/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :NSLocationWhenInUseUsageDescription' "$APP_DEBUG/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :NSLocalNetworkUsageDescription' "$APP_DEBUG/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :NSAppleEventsUsageDescription' "$APP_DEBUG/Contents/Info.plist"
# ATS must not allow unrestricted arbitrary loads
if /usr/libexec/PlistBuddy -c 'Print :NSAppTransportSecurity:NSAllowsArbitraryLoads' "$APP_DEBUG/Contents/Info.plist" 2>/dev/null; then
  echo "ERROR: NSAllowsArbitraryLoads still present" >&2
  exit 1
fi
echo "ATS: NSAllowsArbitraryLoads absent (ok)"

echo "==> Unit tests (ControlPlaneTests)"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "$DERIVED" \
  "${SIGN_ARGS[@]}" \
  test -only-testing:ControlPlaneTests

echo "SMOKE OK"
