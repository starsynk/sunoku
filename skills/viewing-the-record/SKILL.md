---
name: viewing-the-record
description: Use when the user wants to see the backlog or decisions in a browser — "show tasks", "task board", "open the backlog", "visual view", "show decisions". Read-only snapshot; status flips still go through tasks.mjs
---

# Viewing the Record

## Overview

Human-readable view of the record: one self-contained HTML snapshot of `tasks.jsonl`
(milestones → epics → tasks with descriptions, status badges, filters) and
`decisions.jsonl`, written to `.sunoku/record.html` and opened in the browser.
Read-only — the page never writes back.

**Announce at start:** "I'm using the sunoku:viewing-the-record skill to open the record."

## The Process

1. Guard: `.sunoku/status.json` exists; otherwise say there is no record and route to
   sunoku:starting-a-product. Stop.
2. Run `node "${CLAUDE_PLUGIN_ROOT}/skills/viewing-the-record/scripts/record-html.mjs"` —
   it writes `.sunoku/record.html`, prints the path, and opens it.
3. Report the path in one line. If the record changes later, re-run the script to refresh;
   the page is a snapshot, not live.

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll edit record.html to fix the display" | Generated artifact. Fix the generator, re-run the script. |
| "The user clicked around — maybe flip statuses to match" | The page is read-only. Status flips go through `tasks.mjs --set`. |
| "The snapshot looks stale, the record must be stale" | Snapshot ≠ record. Re-run the script before concluding anything. |

## Integration

- Routed from: sunoku:using-sunoku ("show tasks", "task board", "visual view").
- Pairs with: sunoku:checking-status (narrated dashboard) — this skill is the visual
  counterpart, not a replacement for the one-next-action suggestion.
