#!/usr/bin/env bash
# Help-book scrub checks for macOS-15 (#45).
# Fails if Help still recommends Growl or points at upstream dustinrue links.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HELP="$ROOT/Resources/ControlPlane Help"

fail=0

if ! grep -R -n -F 'scottdensmore/ControlPlane' "$HELP" >/dev/null; then
  echo "ERROR: expected fork GitHub link scottdensmore/ControlPlane in Help" >&2
  fail=1
fi

if grep -R -n -F 'dustinrue/ControlPlane' "$HELP"; then
  echo "ERROR: Help still links to dustinrue/ControlPlane" >&2
  fail=1
fi

# Growl must not appear as current guidance (e.g. "Use Growl" / "Enable Growl").
# Mentions that say Growl is no longer used are allowed.
if grep -R -n -E 'Use Growl|Enable Growl|via Growl|with Growl|Growl will be used' "$HELP"; then
  echo "ERROR: Help still presents Growl as current guidance" >&2
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "Help scrub OK (#45)"
