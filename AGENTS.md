# ControlPlane — Agent Instructions (SSOT)

This file is the **single source of truth** for every coding agent (Cursor, Claude Code, and others). Pointer files such as `CLAUDE.md` must only import this document—do not duplicate policy elsewhere.

Live work tracking lives in **GitHub Issues** on `scottdensmore/ControlPlane`. Do not invent parallel roadmap docs.

---

## Project snapshot

ControlPlane is a macOS **menu-bar agent** (`LSUIElement`) that picks a **Context** from evidence sources (Wi‑Fi, Bluetooth, USB, location, …) and runs **Actions**. Stack on this fork:

- Objective-C + XIBs (no SwiftUI app yet). A thin Swift file in the existing app target is allowed only when a slice needs a public API that has no ObjC surface (for example App Intents).
- Xcode project: `ControlPlane.xcodeproj`
- Privileged helper: `CPHelperTool` + `CPXPCService` (SMJobBless / XPC)
- Default (and only durable) branch: `master`
- Target platform: current macOS shipping line (Tahoe / deploy 16.0 today)

Upstream `dustinrue/ControlPlane` may contain a separate Swift rewrite—**do not assume shared code** with this ObjC line.

---

## Branching

Do **not** keep durable per-OS branches (`macOS-15`, `macOS-16`, …). Integrate on `master`.

1. Cut a short-lived feature branch from latest `master`.
2. Ship one thin vertical slice through the lifecycle below.
3. Open a ready-for-review PR into `master`; squash-merge after local verification. GitHub Actions workflows are kept but do not run (manual `workflow_dispatch` only) until Actions minutes are available.
4. Delete the feature branch after merge.

**Rules**

- Prefer the smallest change that restores or improves behavior on current macOS.
- Never commit directly to `master`.
- Raise `MACOSX_DEPLOYMENT_TARGET` only intentionally (documented in the issue/PR)—not “for fun.”
- Issue labels like `macos-16` are optional metadata; they are not branch names.

The generic workflow says “base (`main` / `trunk`)”. On this repo that base is **`master`**.

---

## Autonomous engineering workflow

```text
1 Plan/Spike → 2 Inspect & Branch → 3 Thin Slice → 4 TDD
  → 5 Diff Inspect → 6 UI Review (if user-visible) → 7 Verify
  → 8 Code Review → (loop to 4 on findings) → 9 Commit → 10 PR
  → 11 Squash-merge immediately → next slice until the goal is done
```

Do not collapse planner, implementer, UI reviewer, verifier, and code reviewer into one undifferentiated pass when the change is non-trivial. Each role owns the steps named below and hands off; it does not silently absorb the next gate.

When the user gives a goal, keep going until that goal is done. Do not stop between slices to ask whether to continue. Independent slices run in parallel (separate branches and worktrees). Squash-merge a verified slice as soon as it is ready—do not wait for the user, for assigned reviews, or for GitHub Actions.

### 1. Plan, prototype, and spike

- Before locking a design, spike risky boundaries: TCC, evidence sources, helper/signing, login items, public-vs-private APIs.
- Weigh fit, complexity, and maintenance. Prefer gating or retiring dead actions over clever replacements.
- Turn the validated design into an ordered list of thin vertical slices (GitHub issues).
- Discard spike code. Production work is rebuilt under TDD—do not promote prototype spaghetti.

**Role:** planner · skill `plan-spike`

### 2. Inspect before mutating

- Read `git status`, branch, remotes, and relevant config before editing.
- Preserve unrelated staged, unstaged, and untracked changes.

### 3. Dedicated branch and one thin slice

- Branch from latest `master`. Never commit directly to `master`.
- Take the smallest cohesive, end-to-end outcome that can be tested, reviewed, and shipped alone.
- Avoid a horizontal rewrite in one PR.

### 4. Test-driven implementation

- **Red:** add or update a focused automated test; confirm it fails for the expected reason (not an infra crash).
- **Green:** minimal production change to pass.
- **Refactor:** clean up while staying green.
- If the touched area still has no test, add the thinnest check CI or local can run (XCTest, scripted `xcodebuild`, or a documented manual probe) and note the gap in the PR. Do not skip verification.

### 5. Diff and workspace inspection

- `git status --untracked-files=all`
- Remove scratch, debug noise, and accidental edits.

**Role:** implementer · skill `tdd-slice` (steps 2–5). Stop here unless the user asked this role to own the full ship path.

### 6. UI / UX review *(only if a user-visible surface changed)*

User-visible means XIBs, menus, prefs, status item, About, or Help.

Check macOS HIG, accessibility, standard shortcuts (⌘,), and layout on the current OS. If nothing user-visible changed, skip this gate.

**Role:** ui-reviewer · skill `ui-review`

### 7. Verification

- Debug and Release builds. Treat **new** warnings on touched files as findings.
- Run `ControlPlaneTests` (`xcodebuild test -only-testing:ControlPlaneTests`) or `./scripts/smoke-build.sh`.
- GitHub Actions is **off** (workflow files remain; `workflow_dispatch` only). The local bar is Debug + Release and `ControlPlaneTests`. `ControlPlaneUITests` stay optional. Still run or document the affected prefs/menu/Help journey when the slice is user-visible.
- Smoke the affected evidence, action, prefs, or helper path. See `docs/TESTING.md`.
- **Validate the instrument:** a silent check is not a pass. Confirm it ran against a fresh binary (no stale products, cached success, or a runner that never launched).
- If a fix is required, **re-run this gate from the start** after the fix.

**Role:** verifier · skill `verify-macos-build`

### 8. Expert code review

Review the branch diff and uncommitted files: MRC/ARC, threading, helper/XPC privilege, private API use, prefs-key drift across `.lproj`, scope creep.

Findings that change code go back to step 4, then a full step 7, then a **fresh** review. Do not approve a stale pass.

**Role:** code-reviewer · skill `code-review`

### 9. Commit

Commit only after verification and code review approval.

`type(scope): imperative summary`

Explain *why* in the body when non-obvious. Types: `fix`, `feat`, `refactor`, `chore`, `docs`, `test`, `build`.

### 10. Pull request

Open a ready-for-review PR from the verified tip (no draft unless asked). Link the GitHub issue and checklist the acceptance criteria.

### 11. Squash-merge without stopping

After local verification (and code review on a non-trivial slice), **squash-merge immediately**. Do not pause for the user, for GitHub Actions, or for an assigned reviewer unless the user explicitly said to wait.

GitHub Actions workflows are kept but do not run (`workflow_dispatch` only) until Actions minutes are available. Delete the feature branch after merge. A local “cannot delete branch; used by worktree” error is not a failed merge—confirm `state: MERGED` and update local `master`.

Then pick up the next independent slice. Do not end the turn while the stated goal still has shippable work.

**Role:** parent agent after the gates, or whoever the user asked to ship · skill `ship-slice`

---

## Roles

| Role | Owns | Artifact |
| :--- | :--- | :--- |
| Planner | Step 1 | `.cursor/agents/planner.md` · skill `plan-spike` |
| Implementer | Steps 2–5 | `.cursor/agents/implementer.md` · skill `tdd-slice` |
| UI reviewer | Step 6 | `.cursor/agents/ui-reviewer.md` · skill `ui-review` |
| Verifier | Step 7 | `.cursor/agents/verifier.md` · skill `verify-macos-build` |
| Code reviewer | Step 8 | `.cursor/agents/code-reviewer.md` · skill `code-review` |
| Ship | Steps 9–11 | skill `ship-slice` (after the gates, not inside implementer by default) |

Cursor copies under `.cursor/` are canonical. Keep `.claude/agents/` and `.claude/skills/` identical.

The retired `os-upgrade-branch` skill only redirects old “macOS-N branch” prompts to this file.

---

## Engineering constraints

- **Do not enable App Sandbox** without an explicit design (Wi‑Fi, Bluetooth, USB/IOKit, helper XPC assume a non-sandboxed utility today).
- Prefer **gating or retiring** dead actions (`isActionApplicableToSystem`) over clever `launchctl` for removed macOS services.
- Helper/XPC changes are high risk—minimize surface; avoid new `system()` / `sprintf` shelling.
- Prefs key renames must update **Base and all** `*.lproj` XIBs. New user-visible `NSLocalizedString` keys must land in every shipping locale (`en`, `da-DK`, `de`, `fr`, `it`, `pt-BR`, `pt-PT`).
- Mixed MRC/ARC exists; follow file-level ARC comments; do not casually flip target-wide ARC outside an issue scoped for it.
- Private frameworks (for example Apple80211) and private Bluetooth power APIs are liabilities—remove or document risk when touching those areas.

---

## Parallel work

Independent slices run at the same time. Do not serialize work that does not share files.

- One short-lived branch and worktree per slice, each cut from latest `master`.
- Isolate ports, login items, blessed helpers, and other machine singletons.
- Do not mutate sources in a worktree while a verifier or reviewer is running against that same tree.
- After a squash-merge, rebase or recreate the other in-flight branches onto the new `master` before they ship. Do not block the next slice on that rebase.

---

## Checklist

| Step | Pass when |
| :--- | :--- |
| 1. Discovery | Spike done (or explicitly unnecessary); tradeoffs clear; slices ordered; spike code discarded |
| 2. Setup | Tree inspected; unrelated dirty files preserved; feature branch from latest `master` |
| 3. Scope | One thin vertical slice selected |
| 4. Build | Red → green → refactor |
| 5. Diff | `git status --untracked-files=all` clean of scratch |
| 6. UI review | Skipped, or HIG/a11y OK on current macOS |
| 7. Verify | Debug + Release clean enough; `ControlPlaneTests` green; instrument confirmed; smoke noted |
| 8. Code review | Findings resolved; re-verified; fresh approval |
| 9–11. Ship | Conventional commit; ready PR + issue link; local verify passed; squash-merge immediately; start the next slice |

---

## Issue hygiene

- Prefer existing open issues. Optional `macos-<N>` labels are metadata only.
- New issues need: summary, evidence (paths), tasks, acceptance criteria, and enough detail for another agent to execute without chat history.
- Prefer epics for multi-slice themes. Keep feature branches short-lived.
