---
name: tdd-slice
description: >-
  Implement one thin ControlPlane vertical slice with red-green-refactor.
  Use when coding a single GitHub issue/slice on an OS branch, after planning,
  before verification and commit.
---

# TDD slice skill

## Preconditions

- Feature branch exists (not `master`).
- Slice and acceptance criteria are clear (usually one `macos-<N>` issue).
- Unrelated dirty files are preserved or untouched.

## Loop

1. **Red** — Add or update the smallest automated test that encodes the slice. Run it; confirm failure for the **expected** reason (not infra crash).
2. **Green** — Minimal production change in ObjC/XIB/helper as needed.
3. **Refactor** — Clean naming/structure; keep tests green.
4. **Inspect** — `git status --untracked-files=all`; delete scratch/debug artifacts.
5. Hand off to verification (`verify-macos-build` / verifier agent). Do not commit yet.

## If tests are missing

- Prefer XCTest target addition when feasible for the slice.
- Otherwise add a runnable check (script or documented `xcodebuild` + manual smoke) and state the gap in the PR.
- Still perform red-style confirmation: break the behavior once and show the check catches it when practical.

## Constraints

- One slice per PR when possible.
- Gate obsolete actions; do not expand helper `system()` usage.
- Update all relevant `.lproj` XIBs if prefs bindings/strings change.
