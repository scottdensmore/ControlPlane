# Contributing to ControlPlane

Thanks for helping keep this ObjC / XIB fork working on modern macOS. Live work tracking is **GitHub Issues** on [scottdensmore/ControlPlane](https://github.com/scottdensmore/ControlPlane)—do not invent parallel roadmap docs.

This file is the instruction SSOT for humans and coding agents. Do not create `AGENTS.md`, `agent.md`, or parallel roadmap docs. Pointer files (`CLAUDE.md`, `.cursorrules`, etc.) only point here.

**GitHub:** do not add GitHub Actions workflows. Actions is disabled. Land work with short-lived feature branches and squash-merged PRs onto `main` (linear history; direct pushes are blocked). Verify locally with `./scripts/smoke-build.sh`.

**Sandbox / App Store / widgets / iCloud:** follow [docs/sandbox-store-spike.md](docs/sandbox-store-spike.md). Do not treat “no App Sandbox” as a standing ban. Current `main` remains unsandboxed until the enable-sandbox issue lands. Mac App Store flavor: no Sparkle, no privileged helper.

**Helper / XPC:** the privileged helper is an `SMAppService` LaunchDaemon. Embedded `CPXPCService` is the XPC broker and does not call `SMJobBless`. See [docs/signing.md](docs/signing.md).

Award-track UI coexistence (AppKit host + SwiftUI views, Swift 6): parent epic [#190](https://github.com/scottdensmore/ControlPlane/issues/190) and [docs/swiftui-coexistence-spike.md](docs/swiftui-coexistence-spike.md).

## Pick an issue

1. Prefer open issues on the [award epic](https://github.com/scottdensmore/ControlPlane/issues/190) (or other open `agent-ready` issues). Optional `macos-16` labels are metadata only—not branch names.
2. Prefer issues also labeled **`agent-ready`**: they should include summary, evidence (paths), tasks, and acceptance criteria so another session can execute without chat history.
3. One thin vertical slice per PR—smallest cohesive fix or feature that can be tested and reviewed alone.
4. Prefer epics for multi-slice themes. Keep feature branches short-lived.

## Branching

Integrate on **`main`**. Do not keep durable per-OS branches.

```text
git checkout main && git pull
git checkout -b issue-<n>-short-slug
# … TDD → UI review if needed → verify → code review …
# PR → squash-merge into main → delete feature branch
```

| Rule | Detail |
| :--- | :--- |
| Base branch | Latest `main` |
| Never commit | Directly to `main` (GitHub blocks it; squash-merge PRs only) |
| Deployment target | Raise only intentionally (currently **16.0**); do not bump “for fun” |
| Labels | Optional `macos-16` / priority labels for filtering |

## Local setup

See the [README](README.md) for toolchain and Debug build steps. After code changes:

```bash
./scripts/smoke-build.sh
# Debug + ControlPlaneTests only:
SKIP_RELEASE=1 ./scripts/smoke-build.sh
```

Signed helper bless and notarization are local/manual—see [docs/signing.md](docs/signing.md) and [docs/releasing.md](docs/releasing.md).

## Engineering notes (short)

- **Mixed MRC/ARC:** follow file-level ARC comments; do not flip target-wide ARC outside a scoped issue.
- **App Sandbox** is an approved direction ([docs/sandbox-store-spike.md](docs/sandbox-store-spike.md)). Current `main` stays unsandboxed until the enable-sandbox slice. Do not add MAS-illegal IOKit exceptions; gate USB if `device.usb` is not enough.
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
- GitHub requires a squash-merge PR onto `main` (linear history). Direct pushes, merge commits, and rebase merges are blocked. Run `./scripts/smoke-build.sh` (or Debug + `ControlPlaneTests`) locally. GitHub Actions is not used.
