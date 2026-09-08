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

# Current fork: SMAppService daemon plus leftover SMJobBless copies that share the Mach name.
# Boot out only. Do not launchctl disable; that persists across a later register.
unregister_helper_daemon() {
  launchctl bootout "system/com.scottdensmore.CPHelperTool" 2>/dev/null || true
}
legacy_blessed_install_paths() {
  printf '%s\n' \
    "/Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool" \
    "/Library/LaunchDaemons/com.scottdensmore.CPHelperTool.plist"
}
unregister_helper_daemon
legacy_blessed_install_paths | while IFS= read -r path; do
  [ -n "$path" ] || continue
  rm -f "$path"
done
remove_helper "com.scottdensmore.CPHelperTool"

# Legacy upstream / older forks
remove_helper "com.dustinrue.CPHelperTool"
remove_helper "com.dustinrue.ControlPlane"

echo "Helper uninstall pass complete."
