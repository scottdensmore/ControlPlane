---
name: os-upgrade-branch
description: >-
  Retired redirect. ControlPlane does not use durable macOS-N branches. Use
  when an older prompt mentions macOS-15 or macOS-16 branching; follow AGENTS.md
  and ship from a short-lived feature branch on master.
---

# OS upgrade branch (retired)

ControlPlane integrates on **`master` only**. Do not cut or continue `macOS-<N>` branches.

1. Read `AGENTS.md`.
2. Plan with `plan-spike` if the change is non-trivial.
3. Implement with `tdd-slice` on `issue-<n>-short-slug` from latest `master`.
4. UI review if needed, then `verify-macos-build`, then `code-review`.
5. Ship with `ship-slice`: ready PR, local verify, squash-merge immediately, delete the branch, then continue any remaining slices.

Optional GitHub labels like `macos-16` are metadata. They are not branch names.
