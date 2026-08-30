# ControlPlane — Agent Instructions (SSOT)

This file is the **single source of truth** for every coding agent (Cursor, Claude Code, and others). Pointer files such as `CLAUDE.md` must only import this document—do not duplicate policy elsewhere.

Live work tracking lives in **GitHub Issues** on `scottdensmore/ControlPlane`. Do not invent parallel roadmap docs.

---

## Project snapshot

ControlPlane is a macOS **menu-bar agent** (`LSUIElement`) that picks a **Context** from evidence sources (Wi‑Fi, Bluetooth, USB, location, …) and runs **Actions**. Stack on this fork:

- Objective-C + XIBs (no SwiftUI app yet)
- Xcode project: `ControlPlane.xcodeproj`
- Privileged helper: `CPHelperTool` + `CPXPCService` (SMJobBless / XPC)
- Default branch: `master`
- Active OS line: branch named `macOS-<N>` (currently `macOS-15`)

Upstream `dustinrue/ControlPlane` may contain a separate Swift rewrite—**do not assume shared code** with this ObjC line.

---

## OS upgrade branching (non-negotiable)

Upgrade **one major macOS at a time**. Each OS line must fully work before the next cut.

1. Cut `macOS-<N>` from latest `master`.
2. Fix only what is required for ControlPlane to work well on that OS (issues labeled `macos-<N>`).
3. Keep `macOS-<N>` as the durable branch for that OS.
4. Merge `macOS-<N>` → `master` when the OS line is solid.
5. Cut `macOS-<N+1>` from updated `master`; repeat.

**Rules**

- Prefer the smallest change that restores or preserves behavior on the **current** OS branch.
- Do not pull forward `macos-<N+1>` (or later) work onto the current branch unless the user explicitly expands scope.
- When filing or picking issues, set/respect labels `macos-15`, `macos-16`, …
- Deployment target should match the branch’s OS line when you intentionally raise it (e.g. `macOS-15` → 15.x); do not raise it “for fun.”

---

## Autonomous engineering workflow

```text
Plan/Spike → Inspect & Branch → Thin Slice → TDD
    → Diff Inspect → [UI Review if UI] → Verify → Code Review
    → (loop on findings) → Commit → PR → Gated squash merge
```

### Phase 0 — Discovery & planning

1. **Spike before locking design.** Throwaway prototypes to test APIs, helper/signing, TCC, and evidence sources. Evaluate tradeoffs (fit, complexity, maintenance).
2. **Slice the work.** Ordered list of thin vertical slices (end-to-end, independently shippable).
3. **Discard spike code.** Production work starts clean; rebuild under TDD—do not promote prototype spaghetti.

Use the **planner** subagent / `os-upgrade-branch` skill when starting an OS line or a large issue.

### Phase 1 — Context & scoping

4. **Inspect before mutating.** Read `git status`, branch, remotes, and relevant config. Preserve unrelated local changes.
5. **Dedicated branch.** From latest appropriate base (`macOS-<N>` for OS work, or `master` only when integrating). Never commit directly to `master`.
6. **One thin vertical slice.** Smallest cohesive outcome (fix, gate, or feature) that can be tested and reviewed alone—not a horizontal rewrite.

### Phase 2 — Test-driven implementation

7. **Red → Green → Refactor.**
   - **Red:** Add/update a focused automated test; confirm it fails for the expected reason.
   - **Green:** Minimal production change to pass.
   - **Refactor:** Clean up while staying green.
8. If the project still lacks tests for the touched area, add the thinnest meaningful check you can run in CI/local (XCTest, scripted `xcodebuild`, or a documented manual probe)—then note the gap in the PR. Do not skip verification.
9. **Diff & workspace inspection.** `git status --untracked-files=all`; remove scratch, debug noise, and accidental edits.

Use the **implementer** subagent / `tdd-slice` skill.

### Phase 3 — Quality gates (specialized roles)

10. **UI / UX review** *(only if user-visible surface changed: XIBs, menus, prefs, status item, Help).* Use **ui-reviewer**. Check macOS HIG, accessibility, layout on the target OS.
11. **Verification.** Use **verifier** / `verify-macos-build` skill:
    - Debug and Release builds; treat new warnings as findings.
    - Full test suite when present.
    - Smoke the affected evidence/action/prefs path on the target OS.
    - If a fix is required, **re-run verification from the start** after the fix.
12. **Expert code review.** Use **code-reviewer** on the full branch diff + uncommitted files (memory/MRC-ARC, threading, helper security, API deprecations). Feedback → fix → re-verify → fresh review.

**Validate the instrument:** if a check is “silent,” confirm it actually ran against a fresh binary (no stale build products / masked failures).

### Phase 4 — Integration & delivery

13. **Commit** only after verification + code review approval. Conventional Commits:

    `type(scope): imperative summary`

    Explain *why* in the body when non-obvious. Types: `fix`, `feat`, `refactor`, `chore`, `docs`, `test`, `build`.
14. **Pull request** from the verified tip. Ready-for-review (no draft unless asked). Link the GitHub issue; checklist the acceptance criteria.
15. **Gated merge.** Wait for required reviews; green CI; **squash** short-lived feature branches for linear history onto the OS branch or `master` as appropriate.

---

## Role specialization

Do not collapse architect, implementer, QA, and reviewer into one undifferentiated pass when the change is non-trivial. Prefer:

| Role | Responsibility | Cursor / Claude artifact |
| :--- | :--- | :--- |
| Planner | Spikes, tradeoffs, slice plan | `.cursor/agents/planner.md` (mirrored under `.claude/agents/`) |
| Implementer | TDD for one slice | `.cursor/agents/implementer.md` + skill `tdd-slice` |
| UI reviewer | HIG, a11y, layout | `.cursor/agents/ui-reviewer.md` |
| Verifier | Builds, tests, smoke | `.cursor/agents/verifier.md` + skill `verify-macos-build` |
| Code reviewer | Static audit before commit | `.cursor/agents/code-reviewer.md` |

Skills (progressive detail): `.cursor/skills/*/SKILL.md` (mirrored under `.claude/skills/`).

---

## Engineering constraints for this codebase

- **Do not enable App Sandbox** without an explicit design (Wi‑Fi, BT, USB/IOKit, helper XPC assume a non-sandboxed utility today).
- Prefer **gating or retiring** dead actions (`isActionApplicableToSystem`) over clever `launchctl` for removed macOS services.
- Helper/XPC changes are high risk—minimize surface; avoid new `system()`/`sprintf` shelling.
- Prefs key renames must update **Base and all** `*.lproj` XIBs.
- Mixed MRC/ARC exists; follow file-level ARC comments; do not casually flip target-wide ARC outside an issue scoped for it.
- Private frameworks (e.g. Apple80211) and private Bluetooth power APIs are liabilities—remove or document risk when touching those areas.

---

## Concurrency & worktrees

- Isolate ports, login items, blessed helpers, and other machine singletons across parallel agents.
- Do not mutate sources in a worktree while verifier/reviewer agents are running against it.

---

## Quick checklist

| Stage | Pass when |
| :--- | :--- |
| Discovery | Spike done, tradeoffs clear, slices ordered |
| Setup | Inspected tree; feature branch from correct base |
| Scope | One thin vertical slice selected |
| Build | Red→green→refactor; diff cleaned |
| UI review | If UI touched: HIG/a11y OK on target OS |
| Verify | Debug+Release clean enough; tests/smoke green |
| Code review | Findings resolved; re-verified |
| Ship | Conventional commit; PR + issue link; squash when merging |

---

## Issue hygiene

- Prefer existing issues labeled for the **current** OS branch (`macos-15`, …).
- New issues need: summary, evidence (paths), tasks, acceptance criteria, target `macos-<N>` label, and enough detail for another agent to execute without chat history.
- Epic: track OS-line progress in the branch-strategy epic; keep wave language out—use macOS labels.
