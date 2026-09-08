---
name: plan-spike
description: >-
  Plan and spike one ControlPlane issue before production code. Use at workflow
  step 1 for an epic, risky API, or multi-slice change. Discard prototypes;
  emit an ordered thin-slice plan.
---

# Plan and spike

Workflow **step 1**. Read `AGENTS.md`. Do not ship production code.

## Do

1. Inspect the relevant sources and the GitHub issue. Do not edit production paths.
2. Spike only when a boundary is uncertain (TCC, helper/XPC, evidence APIs, login items, public vs private). Keep the spike throwaway.
3. Weigh fit, complexity, and maintenance. Prefer gating or retiring a dead action over a clever replacement.
4. Write an ordered slice list. Each slice is independently shippable and includes:
   - Goal and issue link (or draft issue body: summary, evidence paths, tasks, acceptance criteria)
   - Files likely touched
   - How red will be proven
   - Out of scope
5. Discard or archive the spike. Tell the implementer to rebuild under `tdd-slice`.

## Do not

- Cut a production branch and start implementing in this skill.
- Expand the epic into a rewrite.
- Invent a parallel roadmap doc. Issues are the live tracker.
