# Sparkle 2 tools (vendored)

Binaries from [Sparkle 2.9.6](https://github.com/sparkle-project/Sparkle/releases/tag/2.9.6).

| Tool | Purpose |
| --- | --- |
| `generate_keys` | Create/look up EdDSA keys in the login Keychain (maintainer machine only) |
| `sign_update` | EdDSA-sign a zip/dmg and print `sparkle:edSignature` + length |
| `generate_appcast` | Build/update `appcast.xml` from a directory of archives |
| `BinaryDelta` | Optional delta updates |

Do **not** commit private keys. See `docs/releasing.md`.
