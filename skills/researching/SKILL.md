---
name: researching
description: Use when a product idea needs market, demand, or competitor validation, or when the user asks for a deep, cited research dive on any topic — "deep research X", "who are the competitors", "validate this idea's demand"
---

# Researching

## Overview

Produce cited, adversarially-checked findings under `.sunoku/research/`. Recommend; never
decide — go/no-go is always the user's call, surfaced by whoever invoked this skill.

**Announce at start:** "I'm using the sunoku:researching skill to gather cited findings."

## Modes

Route by invocation:

- **Validation mode** — invoked by sunoku:starting-a-product (or the user asks to validate
  the bet). Read `${CLAUDE_PLUGIN_ROOT}/skills/researching/references/validate.md` and follow
  it exactly.
- **Standalone mode** — the user asks for a deep dive on anything (market, competitor,
  technical landscape). Read
  `${CLAUDE_PLUGIN_ROOT}/skills/researching/references/standalone.md` and follow it. Works
  without a full record: if `.sunoku/` is missing, create only `.sunoku/research/` and touch
  nothing else.

## Rules

- Every claim in a research file carries its source (link or named dataset + access date).
  No source, no claim — write "could not verify" instead.
- Subagents are generic (general-purpose); their role lives in skill-owned prompt files.
  Dispatches name: files to read, the exact output file to write, and the prompt file the
  subagent must read first. An under-specified dispatch is a bug; fix the dispatch, not the
  subagent.
- Go-if conditions and unverifiable-but-load-bearing claims become decision rows:
  `node "${CLAUDE_PLUGIN_ROOT}/scripts/decisions.mjs" --add '{"question":"...","stakes":"high","default":"...","by":"research"}'`
- Never write application code; never touch files outside `.sunoku/research/` and
  `decisions.jsonl` (via its script).

## Red Flags

| Thought | Reality |
|---------|---------|
| "This market size is common knowledge" | No source, no claim. Write "could not verify". |
| "The findings look strong, skip the red team" | Validation mode always red-teams. Unchallenged findings are marketing. |
| "I'll decide go/no-go myself, it's obvious" | Recommend only. The call is the user's, at the checkpoint. |

## Integration

- Invoked by: sunoku:starting-a-product (validation mode) or the user directly.
- Dispatches subagents via `references/researcher-prompt.md` and
  `references/red-team-prompt.md`.
- Returns its recommendation to the invoker; sunoku:starting-a-product presents the go/no-go
  checkpoint.
