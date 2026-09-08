---
name: ship-slice
description: >-
  Commit, open a ready pull request, and squash-merge a verified ControlPlane
  slice. Use at workflow steps 9–11 only after UI review (if needed),
  verification, and code review have passed.
---

# Ship the slice

Workflow **steps 9–11**. Read `AGENTS.md`. Do not start here.

## Preconditions

- Feature branch, not `master`.
- Step 6 done or explicitly skipped (no user-visible change).
- `verify-macos-build` passed on the current tree, after the last code change.
- Code review approved **after** that verification. A review of an older diff does not count.

## 9. Commit

Conventional Commits:

```text
type(scope): imperative summary
```

Types: `fix`, `feat`, `refactor`, `chore`, `docs`, `test`, `build`. Explain *why* in the body when it is not obvious. Do not commit secrets. Do not skip hooks.

## 10. Pull request

Push the branch and open a **ready** PR into `master` (draft only if the user asked). Link the issue. Checklist the acceptance criteria and how verification was run.

## 11. Squash-merge without stopping

- Squash-merge onto `master` as soon as the preconditions above are met. Do not wait for the user, assigned reviews, or GitHub Actions.
- GitHub Actions workflows are `workflow_dispatch` only until minutes are available. Local `verify-macos-build` is the gate.
- Delete the feature branch after merge.
- A local “cannot delete branch; used by worktree” error is not a failed merge. Confirm `state: MERGED` and update local `master`.
- If the user’s goal has more independent slices, start them. Do not stop to ask.

Do not force-push `master`.
