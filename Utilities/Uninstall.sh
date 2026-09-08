#!/bin/sh
# Remove ControlPlane's privileged helper.
# Boots out the system job and deletes leftover SMJobBless copies so two listeners
# never share Mach name com.scottdensmore.CPHelperTool. Does not disable the
# launchd job — that flag persists and is not cleared by a later register.
# Run from a Terminal with admin rights. Do not invoke this from unit tests.

set -e

HELPER_LABEL="com.scottdensmore.CPHelperTool"

# Blessed SMJobBless copies. Must match +[CPHelperDaemonService legacyBlessedInstallPaths].
legacy_blessed_install_paths() {
  printf '%s\n' \
    "/Library/PrivilegedHelperTools/com.scottdensmore.CPHelperTool" \
    "/Library/LaunchDaemons/com.scottdensmore.CPHelperTool.plist"
}

# Boot out the system job that shares the Mach name. Do not disable the job:
# that flag persists and is not cleared by a later SMAppService register.
# Target matches +[CPHelperDaemonService legacyBlessedLaunchdBootoutTarget].
unregister_helper_daemon() {
  launchctl bootout "system/com.scottdensmore.CPHelperTool" 2>/dev/null || true
}

if [ "$(id -u)" -ne 0 ]; then
  echo "Re-running with sudo…"
  exec sudo "$0" "$@"
fi

unregister_helper_daemon

legacy_blessed_install_paths | while IFS= read -r path; do
  [ -n "$path" ] || continue
  rm -f "$path"
done

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

echo "Booted out ${HELPER_LABEL} and removed legacy blessed copies (if present)."
