#!/bin/sh
# Remove ControlPlane's privileged helper (SMJobBless install).
# Run from a Terminal with admin rights; useful when testing bless from scratch.

set -e

HELPER_LABEL="com.scottdensmore.CPHelperTool"

if [ "$(id -u)" -ne 0 ]; then
  echo "Re-running with sudo…"
  exec sudo "$0" "$@"
fi

# Prefer bootout (launchctl unload is legacy on modern macOS).
launchctl bootout "system/${HELPER_LABEL}" 2>/dev/null || true
rm -f "/Library/LaunchDaemons/${HELPER_LABEL}.plist"
rm -f "/Library/PrivilegedHelperTools/${HELPER_LABEL}"

# Optional: clear user prefs/caches used while debugging install.
# rm -f "${HOME}/Library/Preferences/com.scottdensmore.ControlPlane.plist"
# rm -rf "${HOME}/Library/Caches/com.scottdensmore.ControlPlane"

# Authorization rights registered for helper commands (ignore missing).
for right in \
  enableTimeMachine disableTimeMachine startBackupTimeMachine stopBackupTimeMachine \
  enableInternetSharing disableInternetSharing \
  enableFirewall disableFirewall \
  setDisplaySleepTime \
  enablePrinterSharing disablePrinterSharing \
  enableTFTPCommand disableTFTPCommand \
  enableFTPCommand disableFTPCommand \
  enableAFPFileSharing disableAFPFileSharing \
  enableSMBFileSharing disableSMBFileSharing \
  enableWebSharing disableWebSharing \
  enableRemoteLogin disableRemoteLogin
do
  security -q authorizationdb remove "com.scottdensmore.CPHelperTool.${right}" 2>/dev/null || true
done

echo "Removed ${HELPER_LABEL} (if it was installed)."
