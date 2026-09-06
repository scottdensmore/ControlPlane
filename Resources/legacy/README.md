# Legacy Sparkle 1 DSA material

`dsa_pub.pem` was used with Sparkle 1.x (`SUPublicDSAKeyFile`). ControlPlane now vendors Sparkle 2.x and expects EdDSA (`SUPublicEDKey`) for new releases.

This file is **not** copied into the app bundle. Keep it only if you need to verify historical DSA-signed appcast items; do not re-ship it.
