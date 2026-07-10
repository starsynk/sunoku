---
name: checking-status
description: Use when the user asks for project status, "what's next", "where are we", or wants tracking muted/unmuted. Content questions ("why did we drop X?") belong to sunoku:querying-the-record, not here
---

# Checking Status

## Overview

Read-mostly dashboard: run the report script, narrate it, suggest exactly one next action.
The only writes this skill ever makes are the mute/unmute flag flips.

**Announce at start:** "I'm using the sunoku:checking-status skill for the dashboard."

## The Process

1. Guard: `.sunoku/status.json` exists; otherwise say there is no record and route to
   sunoku:starting-a-product. Stop.
2. Run `node "${CLAUDE_PLUGIN_ROOT}/skills/checking-status/scripts/report.mjs"` and narrate
   from its JSON only — never re-derive its facts from record files:
   - one-liner, lifecycle + tracking in plain words;
   - open decisions (count; name high-stakes ones with their recommended defaults);
   - tasks when present: counts, ready frontier, per-milestone progress ("M1 3/5 done");
   - staleness when it signals, as context only: uncommitted work or commits landed since
     the record was last touched.
3. Suggest ONE next action, first match wins:
   1. High-stakes open decision → prompt to answer it, the row's `default` presented as
      "(Recommended)" first. Answers route through sunoku:writing-the-prd (reshape) when they
      change the PRD; otherwise resolve directly via `decisions.mjs --resolve`.
   2. Lifecycle is not `live` and `prd_stub` is false (an init run was interrupted after PRD
      approval) → offer go-live:
      `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --set lifecycle=live --set tracking=true`.
   3. `prd_stub` true → point to sunoku:writing-the-prd.
   4. Ready tasks exist → report the frontier; any executor works it — Sunoku never executes.
   5. Live record, no tasks → mention sunoku:planning-the-work is available.
   6. Otherwise: nothing needs attention — say so.
4. Mute/unmute on explicit request:
   `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --set tracking=false` (or `true`);
   confirm the new state in one line.

## Red Flags

| Thought | Reality |
|---------|---------|
| "Commits landed since the record was touched — suggest a PRD refresh" | Commits landing = executors working the plan, not drift. Staleness is narrate-only; only the user calls drift. |
| "I'll peek at PRD.md to enrich the dashboard" | Narrate the report JSON only. Content questions go to sunoku:querying-the-record. |
| "Two things need attention, I'll suggest both" | Exactly ONE next action. First match wins. |

## Integration

- Routes to: sunoku:starting-a-product (no record), sunoku:writing-the-prd (stub PRD or
  PRD-changing decision answers), sunoku:planning-the-work (live, no tasks).
