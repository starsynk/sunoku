---
name: viewing-the-record
description: Use when the user wants to see the backlog or decisions in a browser — "show tasks", "task board", "open the backlog", "visual view", "show decisions". Live read-only view; status flips still go through tasks.mjs
---

# Viewing the Record

## Overview

Human-readable live view of the record: a small local server renders `tasks.jsonl`
(milestones → epics → tasks with descriptions, status badges, filters) and
`decisions.jsonl`, and open tabs reload themselves whenever the record changes.
Read-only — the page never writes back. The server binds 127.0.0.1 with a session
key in the URL and stops itself ~15 minutes after the last tab closes.

**Announce at start:** "I'm using the sunoku:viewing-the-record skill to open the record."

## The Process

1. Guard: `.sunoku/status.json` exists; otherwise say there is no record and route to
   sunoku:starting-a-product. Stop.
2. Run `node "${CLAUDE_PLUGIN_ROOT}/skills/viewing-the-record/scripts/record-server.mjs"` —
   it starts (or reuses) the server, prints one JSON line with the `url`, and opens the
   browser.
3. Relay the URL in one line and note the page is live — it reloads on record changes,
   and the server stops itself ~15 minutes after the last tab closes. Asking again later
   just re-runs the script: a running server is reused, a stopped one restarts.

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll edit the served HTML to fix the display" | Generated per request. Fix `render.mjs`, re-request. |
| "The user clicked around — maybe flip statuses to match" | The page is read-only. Status flips go through `tasks.mjs --set`. |
| "The server should stay up forever" | It idles out on purpose. Re-running the script is the restart. |
| "I'll add a data API / write endpoint while I'm here" | One rendering path, read-only. The server serves the view, nothing else. |

## Integration

- Routed from: sunoku:using-sunoku ("show tasks", "task board", "visual view").
- Pairs with: sunoku:checking-status (narrated dashboard) — this skill is the visual
  counterpart, not a replacement for the one-next-action suggestion.
