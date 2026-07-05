---
name: plan
description: Break the approved PRD into a parallel-ready task backlog (milestones, epics, tasks with explicit deps) written to .sunoku/tasks.jsonl. Use for "break this into tasks", "task breakdown", "plan the build", "re-plan after that PRD change".
---

## Mission

Approved PRD in, workable backlog out. Read
`${CLAUDE_PLUGIN_ROOT}/skills/plan/references/methodology.md` first and follow it — the
decomposition rules are not optional.

## Flow

1. Guard: `.sunoku/PRD.md` exists and is not stub-sentineled; otherwise route to `sunoku:prd`
   and stop.
2. Decompose per the methodology (inline — no agents): milestones → epics → tasks with
   discipline, size, deps.
3. Present the shape for approval BEFORE writing: milestones with their epics, task counts per
   epic, and the ready frontier of M1. One checkpoint.
4. On approval write every row via the script, milestones first, then epics, then tasks (deps
   reference earlier ids):
   `node "${CLAUDE_PLUGIN_ROOT}/scripts/tasks.mjs" --add '<row>'`
5. Spikes: unknown-shaped work gets `"spike": true` AND a decision row
   (`decisions.mjs --add`, `"by":"plan"`) naming what must be answered.
6. Re-plan (after a reshape): patch, don't rebuild — supersede invalidated tasks by flipping
   them (`--set T-nnn status=blocked`) and adding replacement rows; never delete history.

Anyone can flip task status any time (`tasks.mjs --set T-nnn status=done`) — zero ceremony, no
consent gate; the backlog is an open contract worked by whatever executor the user prefers.
Sunoku records; it never executes.
