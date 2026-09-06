---
name: os-upgrade-branch
description: >-
  DEPRECATED. ControlPlane no longer keeps durable macOS-N branches. Prefer
  feature branches from master. Kept so older prompts that mention macOS-15 /
  macOS-16 branching still resolve to current policy.
---

# OS upgrade branch skill (retired)

## Current policy

ControlPlane integrates on **`master` only**. Do not cut or continue `macOS-<N>` durable branches.

1. `git fetch origin && git checkout master && git pull`
2. `git checkout -b issue-<n>-short-slug`
3. Implement via `tdd-slice` → `verify-macos-build` → code review
4. PR → squash-merge into `master`; delete the feature branch

Optional GitHub labels like `macos-16` are metadata for filtering issues—not branch names.

See root `AGENTS.md` § Branching.
