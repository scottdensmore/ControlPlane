---
name: tdd-slice
description: >-
  Inspect, branch, and implement one ControlPlane vertical slice with
  red-green-refactor. Use for workflow steps 2–5 after planning, before UI
  review, verification, and commit.
---

# Thin-slice TDD

Workflow **steps 2–5**. Read `AGENTS.md`.

## Preconditions

- Latest `master` is the base. This work is not on `master`.
- One slice and its acceptance criteria are clear (usually one GitHub issue).
- Unrelated dirty files are preserved.

## Loop

1. **Inspect** — `git status`, branch, remotes. Do not clobber unrelated work.
2. **Branch** — from latest `master`: `issue-<n>-short-slug`.
3. **Red** — Add or update the smallest automated test that encodes the slice. Run it. Confirm failure for the **expected** reason, not an infra crash.
4. **Green** — Minimal ObjC, XIB, or helper change to pass.
5. **Refactor** — Clean naming and structure. Stay green.
6. **Diff inspect** — `git status --untracked-files=all`. Delete scratch and debug artifacts.

Hand off to `ui-review` if a user-visible surface changed, then `verify-macos-build`. Do not commit yet.

## If tests are missing

- Prefer an XCTest in `ControlPlaneTests` when the slice can be checked without launching the menu-bar app.
- Otherwise add a runnable check (script or documented `xcodebuild`) and state the gap in the PR.
- When practical, break the behavior once and show the check catches it.

## Constraints

- One slice per PR.
- Gate obsolete actions. Do not expand helper `system()` usage.
- Do not enable App Sandbox.
- Prefs key renames update Base and all `*.lproj` XIBs.
- New `NSLocalizedString` keys go in every shipping locale.
