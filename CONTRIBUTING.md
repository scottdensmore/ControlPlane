# Contributing to ControlPlane

Thanks for helping keep this ObjC / XIB fork working on modern macOS. Live work tracking is **GitHub Issues** on [scottdensmore/ControlPlane](https://github.com/scottdensmore/ControlPlane)—do not invent parallel roadmap docs.

Coding agents should follow **[AGENTS.md](AGENTS.md)** as the single source of truth for workflow detail. This file is the human-oriented short version.

## Pick an issue

1. Prefer issues labeled for the **current OS line** (`macos-15` on branch `macOS-15`).
2. Prefer issues also labeled **`agent-ready`** when using an agent: they should include summary, evidence (paths), tasks, and acceptance criteria so another session can execute without chat history.
3. Do not pull `macos-16` (or later) scope onto the current branch unless the issue explicitly expands scope.
4. One thin vertical slice per PR—smallest cohesive fix or feature that can be tested and reviewed alone.

## OS-line branching

Upgrade **one major macOS at a time**. Each OS line must fully work before the next cut.

```text
Cut macOS-<N> from master → fix only macos-<N> issues → merge to master when solid → cut macOS-<N+1>
```

| Rule | Detail |
| :--- | :--- |
| Base branch | OS work from latest `macOS-<N>` (currently `macOS-15`); integrate to `master` only when merging an OS line |
| Never commit | Directly to `master` |
| Deployment target | Match the branch’s OS line only when intentionally raising it; do not bump “for fun” (15.x bump is out of scope for drive-by docs/PRs) |
| Labels | Set/respect `macos-15`, `macos-16`, … on issues |

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

## Pull requests

- Conventional Commits: `type(scope): imperative summary` (`fix`, `feat`, `refactor`, `chore`, `docs`, `test`, `build`).
- Link the GitHub issue; checklist the acceptance criteria.
- Wait for green CI (Debug build + `ControlPlaneTests`); squash short-lived feature branches when merging onto `macOS-15` or `master` as appropriate.
