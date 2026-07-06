---
name: read
description: Internal — model-invoked record retrieval, not a user command. Fires when the user asks what the record says: PRD content, decision history, task state, research findings, "why did we drop X?", "what changed since May?". Answers strictly from the record with citations.
user-invocable: false
---

## Mission

Answer questions FROM the record, fast, without loading whole files. This skill serves
conversation retrieval only — working skills (prd, plan, status) read their own files directly.

## Flow

1. Guard: `.sunoku/` exists; otherwise say there is no Sunoku record here and stop.
2. Fetch ONLY what the question needs via
   `node "${CLAUDE_PLUGIN_ROOT}/skills/read/scripts/query.mjs"` — flags compose:
   - PRD content → `--prd <section>` (Problem, Features, Architecture, ...)
   - "why did we drop / when did we change X?" → `--changelog [--since YYYY-MM-DD]`
   - decision history → `--decisions open|resolved|high|all`
   - task state → `--tasks ready|all|status=X|milestone=X|epic=X`
   - research findings → `--research [name-fragment]`
3. Answer from the returned rows/sections, citing dates and row ids (`D-002, resolved
   2026-07-05`). Quote the Change Log `why` verbatim when the question is "why".

## Never

- Never invent history. If the record does not cover the question, say so plainly —
  pre-record history is out of scope by design, and git archaeology is not a fallback.
- Never load a whole record file when a query flag answers it.
