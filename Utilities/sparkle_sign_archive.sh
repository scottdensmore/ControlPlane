#! /bin/sh
# sparkle_sign_archive.sh — Sparkle 2 EdDSA signing helper for release archives.
#
# Usage (from repo root, after building a notarized zip/dmg):
#   ./Utilities/sparkle_sign_archive.sh path/to/ControlPlane-N.dmg
#
# Requires a maintainer EdDSA private key in the login Keychain
# (created once via ./Utilities/SparkleTools/generate_keys). See docs/releasing.md.
#
# Prints sparkle:edSignature and length suitable for an appcast enclosure.
# Does not upload artifacts or rewrite Info.plist.

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIGN_UPDATE="$ROOT/Utilities/SparkleTools/sign_update"

if [ ! -x "$SIGN_UPDATE" ]; then
	echo "error: missing $SIGN_UPDATE — vendor Sparkle 2 tools" >&2
	exit 1
fi

if [ -z "$1" ] || [ ! -f "$1" ]; then
	echo "usage: $0 <update-archive.zip|dmg>" >&2
	exit 1
fi

ARCHIVE="$1"

# Prefer Keychain-backed signing (Sparkle 2 default). Optional override:
#   SPARKLE_ED_KEY_FILE=/path/to/eddsa_private.key
if [ -n "${SPARKLE_ED_KEY_FILE:-}" ]; then
	if [ ! -f "$SPARKLE_ED_KEY_FILE" ]; then
		echo "error: SPARKLE_ED_KEY_FILE not found: $SPARKLE_ED_KEY_FILE" >&2
		exit 1
	fi
	exec "$SIGN_UPDATE" --ed-key-file "$SPARKLE_ED_KEY_FILE" "$ARCHIVE"
fi

exec "$SIGN_UPDATE" "$ARCHIVE"
