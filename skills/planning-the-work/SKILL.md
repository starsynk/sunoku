---
name: planning-the-work
description: Use when an approved PRD needs a task backlog or an existing backlog needs re-planning — "break this into tasks", "task breakdown", "plan the build", "re-plan after that PRD change"
---

# Planning the Work

## Overview

Approved PRD in, workable backlog out: milestones, epics, tasks with explicit deps in
`.sunoku/tasks.jsonl`. Read
`${CLAUDE_PLUGIN_ROOT}/skills/planning-the-work/references/methodology.md` first and follow
it — the decomposition rules are not optional.

**Announce at start:** "I'm using the sunoku:planning-the-work skill to break down the PRD."

## The Process

1. Guard: `.sunoku/PRD.md` exists and is not stub-sentineled; otherwise route to
   sunoku:writing-the-prd and stop.
2. Decompose per the methodology (inline — no subagents): milestones → epics → tasks with
   discipline, size, deps.
3. Present the shape for approval BEFORE writing: milestones with their epics, task counts
   per epic, and the ready frontier of M1. One checkpoint.
4. On approval write every row via the script, milestones first, then epics, then tasks (deps
   reference earlier ids):
   `node "${CLAUDE_PLUGIN_ROOT}/scripts/tasks.mjs" --add '<row>'`
5. Spikes: unknown-shaped work gets `"spike": true` AND a decision row
   (`decisions.mjs --add`, `"by":"plan"`) naming what must be answered.
6. Re-plan (after a reshape): patch, don't rebuild — supersede invalidated tasks by flipping
   them (`--set T-nnn status=blocked`) and adding replacement rows; never delete history.

## Red Flags

| Thought | Reality |
|---------|---------|
| "The frontier is right there, I'll build task T-003" | Sunoku never executes. Any executor works tasks; Sunoku records. |
| "The reshape broke the plan, I'll rebuild tasks.jsonl" | Patch, don't rebuild. Supersede rows; never delete history. |
| "I'll write the rows first, then show the shape" | Approval BEFORE writing. One checkpoint. |
| "I'll edit tasks.jsonl directly" | Script-written only (`tasks.mjs`). The guard hook denies hand edits. |

Anyone can flip task status any time (`tasks.mjs --set T-nnn status=done`) — zero ceremony,
no consent gate; the backlog is an open contract worked by whatever executor the user
prefers.

## Integration

- Invoked by: sunoku:starting-a-product (offered once after PRD approval) or the user
  directly.
- After a PRD reshape, sunoku:writing-the-prd names this skill for re-planning — run only on
  request.
