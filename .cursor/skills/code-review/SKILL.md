---
name: code-review
description: >-
  Expert pre-commit review of a ControlPlane slice. Use at workflow step 8 on
  the branch diff and uncommitted files. Loop findings back through TDD and a
  full verification before a fresh approval.
---

# Expert code review

Workflow **step 8**. Read `AGENTS.md`. Review before commit, not after.

## Scope

- `git diff master...HEAD` plus unstaged and untracked files that belong to the slice.
- Confirm scratch and debug files are gone (`git status --untracked-files=all`).

## Look for

- MRC/ARC mistakes and unbalanced retains on the file’s memory model.
- Main-thread UI and racey evidence collection.
- Helper/XPC privilege, new `system()` / `sprintf`, or a wider attack surface.
- Private APIs left undocumented.
- Prefs keys or user-visible strings missing from Base / shipping `.lproj`.
- Scope past the issue, App Sandbox flipped on, or deployment target bumped without a reason.

## Findings

Classify **Critical**, **Warning**, or **Suggestion**.

Critical and Warning block approval. After a fix: implementer, then a **full** `verify-macos-build`, then a **new** review. Do not reuse this pass.

Do not commit. Prefer file:line notes over rewriting the slice.
