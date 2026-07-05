---
name: status
description: Sunoku dashboard: product state, open decisions, task progress, staleness, and exactly one suggested next action. Use for "project status", "what's next", "where are we", "mute/unmute tracking". Content questions ("why did we drop X?") belong to sunoku:read, not here.
---

## Mission

Read-mostly dashboard. Run the report script, narrate it, suggest exactly one next action. The
only writes this skill ever makes are the mute/unmute flag flips.

## Flow

1. Guard: `.sunoku/status.json` exists; otherwise say there is no record and route to
   `sunoku:init`. Stop.
2. Run `node "${CLAUDE_PLUGIN_ROOT}/skills/status/scripts/report.mjs"` and narrate from its JSON
   only — never re-derive its facts from record files:
   - one-liner, lifecycle + tracking in plain words;
   - open decisions (count; name high-stakes ones with their recommended defaults);
   - tasks when present: counts, ready frontier, per-milestone progress ("M1 3/5 done");
   - staleness when it signals: uncommitted work or commits landed since the record was last
     touched.
3. Suggest ONE next action, first match wins:
   1. High-stakes open decision → prompt to answer it, the row's `default` presented as
      "(Recommended)" first. Answers route through `sunoku:prd` (reshape) when they change the
      PRD; otherwise resolve directly via `decisions.mjs --resolve`.
   2. Lifecycle is not `live` and `prd_stub` is false (an init run was interrupted after PRD
      approval) → offer go-live:
      `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --set lifecycle=live --set tracking=true`.
   3. `prd_stub` true, or staleness signals the PRD lags the code → point to `sunoku:prd`.
   4. Ready tasks exist → report the frontier; any executor works it — Sunoku never executes.
   5. Live record, no tasks → mention `sunoku:plan` is available.
   6. Otherwise: nothing needs attention — say so.
4. Mute/unmute on explicit request:
   `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --set tracking=false` (or `true`);
   confirm the new state in one line.
