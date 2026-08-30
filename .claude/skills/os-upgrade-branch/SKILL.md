---
name: os-upgrade-branch
description: >-
  Cut or continue a one-OS-at-a-time ControlPlane upgrade branch (macOS-N).
  Use when starting an OS upgrade, merging an OS line to master, filing/picking
  macos-N issues, or when the user mentions macOS-15/macOS-16 branching strategy.
---

# OS upgrade branch skill

## Goal

Deliver a ControlPlane line that **fully works on one major macOS**, keep that branch, merge to `master`, then cut the next OS branch. Never leapfrog OS versions in one PR.

## Steps

1. Confirm current branch and remotes (`git branch -vv`, `git status`).
2. Identify target label: `macos-<N>` matching branch `macOS-<N>`.
3. List open issues: `gh issue list --repo scottdensmore/ControlPlane --label macos-<N> --state open`.
4. If cutting a new OS branch:
   - Update local `master` from `origin`.
   - `git checkout -b macOS-<N> master` (or from the agreed base).
   - Push `-u` only when the user wants remote tracking.
5. Plan **thin slices** from those issues only (see `AGENTS.md` Phase 0–1). Defer `macos-<N+1>` issues.
6. For each slice, follow `tdd-slice` → `verify-macos-build` → code review → commit/PR into `macOS-<N>`.
7. When the OS line is solid: PR `macOS-<N>` → `master` (squash or merge per `AGENTS.md`), then cut `macOS-<N+1>` from updated `master`.

## Out of scope

- Rewrites unrelated to making this OS work (Sparkle major bumps, full ARC, SwiftUI Settings) unless labeled for this OS.
- Enabling App Sandbox without an explicit issue/design.
