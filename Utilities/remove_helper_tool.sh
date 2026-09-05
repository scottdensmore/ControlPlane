#!/bin/bash
# Remove ControlPlane privileged helpers (current + legacy dustinrue labels).
# Prefer Utilities/Uninstall.sh for the scottdensmore helper. Must run as root.

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Re-running with sudo…"
  exec sudo "$0" "$@"
fi

remove_helper() {
  local label="$1"
  launchctl bootout "system/${label}" 2>/dev/null || true
  launchctl unload -F "/Library/LaunchDaemons/${label}.plist" 2>/dev/null || true
  rm -f "/Library/LaunchDaemons/${label}.plist"
  rm -f "/Library/PrivilegedHelperTools/${label}"
}

# Current fork
remove_helper "com.scottdensmore.CPHelperTool"

# Legacy upstream / older forks
remove_helper "com.dustinrue.CPHelperTool"
remove_helper "com.dustinrue.ControlPlane"

echo "Helper uninstall pass complete."
