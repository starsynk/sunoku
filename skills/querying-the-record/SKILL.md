---
name: querying-the-record
description: Internal — model-invoked record retrieval, not a user command. Use when the user asks what the record says: PRD content, decision history, task state, research findings, "why did we drop X?", "what changed since May?"
user-invocable: false
---

# Querying the Record

## Overview

Answer questions FROM the record, fast, without loading whole files. This skill serves
conversation retrieval only — working skills (writing-the-prd, planning-the-work,
checking-status) read their own files directly.

## The Process

1. Guard: `.sunoku/` exists; otherwise say there is no Sunoku record here and stop.
2. Fetch ONLY what the question needs via
   `node "${CLAUDE_PLUGIN_ROOT}/skills/querying-the-record/scripts/query.mjs"` — flags
   compose:
   - PRD content → `--prd <section>` (Problem, Features, Architecture, ...)
   - "why did we drop / when did we change X?" → `--changelog [--since YYYY-MM-DD]`
   - decision history → `--decisions open|resolved|high|all`
   - task state → `--tasks ready|all|status=X|milestone=X|epic=X`
   - research findings → `--research [name-fragment]`
3. Answer from the returned rows/sections, citing dates and row ids (`D-002, resolved
   2026-07-05`). Quote the Change Log `why` verbatim when the question is "why".

## Red Flags

| Thought | Reality |
|---------|---------|
| "The record doesn't cover it, but git log would" | Never invent history; git archaeology is not a fallback. Say the record doesn't cover it. |
| "I'll read the whole PRD, it's faster" | Never load a whole record file when a query flag answers it. |
| "I remember what the PRD says" | Records change. Query, then cite rows and dates. |

## Integration

- Fired ambiently on record questions; sunoku:checking-status handles state/next-action
  questions instead.
