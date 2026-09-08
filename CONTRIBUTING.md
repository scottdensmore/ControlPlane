# Contributing to ControlPlane

Thanks for helping keep this ObjC / XIB fork working on modern macOS. Live work tracking is **GitHub Issues** on [scottdensmore/ControlPlane](https://github.com/scottdensmore/ControlPlane)—do not invent parallel roadmap docs.

Coding agents should follow **[AGENTS.md](AGENTS.md)** as the single source of truth for workflow detail. This file is the human-oriented short version.

## Pick an issue

1. Prefer open issues on the [macOS 26 epic](https://github.com/scottdensmore/ControlPlane/issues/116) (or other open `agent-ready` issues). Optional `macos-16` labels are metadata only—not branch names.
2. Prefer issues also labeled **`agent-ready`**: they should include summary, evidence (paths), tasks, and acceptance criteria so another session can execute without chat history.
3. One thin vertical slice per PR—smallest cohesive fix or feature that can be tested and reviewed alone.

## Branching

Integrate on **`master`**. Do not keep durable per-OS branches.

```text
git checkout master && git pull
git checkout -b issue-<n>-short-slug
# … TDD → UI review if needed → verify → code review …
# PR → squash-merge into master → delete feature branch
```

| Rule | Detail |
| :--- | :--- |
| Base branch | Latest `master` |
| Never commit | Directly to `master` |
| Deployment target | Raise only intentionally (currently **16.0**); do not bump “for fun” |
| Labels | Optional `macos-16` / priority labels for filtering |

## Local setup

See the [README](README.md) for toolchain and Debug build steps. After code changes:

```bash
./scripts/smoke-build.sh
# or CI-shaped:
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

Signed helper bless and notarization are **not** part of CI—see [docs/signing.md](docs/signing.md) and [docs/releasing.md](docs/releasing.md).

## Engineering notes (short)

- **Mixed MRC/ARC:** follow file-level ARC comments; do not flip target-wide ARC outside a scoped issue.
- **No App Sandbox** without an explicit design (Wi‑Fi, Bluetooth, USB/IOKit, helper XPC assume non-sandboxed today).
- Prefer **gating or retiring** dead actions (`isActionApplicableToSystem`) over clever `launchctl` for removed macOS services.
- Helper/XPC changes are high risk—minimize surface; avoid new `system()` / `sprintf` shelling.
- Prefs key renames must update **Base and all** `*.lproj` XIBs. Legacy HTML notes: `LOCALISATION.html`, `HACKING.html`.

## Localization

Shipping locales: `en`, `da-DK`, `de`, `fr`, `it`, `pt-BR`, `pt-PT`. User-visible `NSLocalizedString` keys live in `Resources/<locale>.lproj/Localizable.strings` (UTF-16).

After adding or changing strings:

```bash
genstrings -o Resources/en.lproj -s NSLocalizedString Source/*.m
```

Copy any new keys into every shipping `Localizable.strings` and translate them. Keep `%@` / `%d` placeholders. Do not leave new Focus, Power, Settings, Run Shortcut, or gated-action sentences as English copies in non-English locales. `ControlPlaneTests/LocalizationCatalogTests` checks that catalog.

## Pull requests

- Conventional Commits: `type(scope): imperative summary` (`fix`, `feat`, `refactor`, `chore`, `docs`, `test`, `build`).
- Link the GitHub issue; checklist the acceptance criteria.
- Wait for green CI (Debug build + `ControlPlaneTests`); squash short-lived feature branches when merging onto `master`.
