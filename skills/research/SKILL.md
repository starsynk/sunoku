---
name: research
description: Sunoku research: market/demand/competitor validation for a product idea, or a deep research dive on any topic the user asks for. Writes cited findings to .sunoku/research/. Use for "deep research X", "market research", "who are the competitors", "validate this idea's demand".
---

## Mission

Produce cited, adversarially-checked findings under `.sunoku/research/`. Recommend; never decide
— go/no-go is always the user's call, surfaced by whoever invoked this skill.

## Modes

Route by invocation:

- **Validation mode** — invoked by `sunoku:init` (or the user asks to validate the bet). Read
  `${CLAUDE_PLUGIN_ROOT}/skills/research/references/validate.md` and follow it exactly.
- **Standalone mode** — the user asks for a deep dive on anything (market, competitor, technical
  landscape). Read `${CLAUDE_PLUGIN_ROOT}/skills/research/references/standalone.md` and follow
  it. Works without a full record: if `.sunoku/` is missing, create only `.sunoku/research/` and
  touch nothing else.

## Rules

- Every claim in a research file carries its source (link or named dataset + access date).
  No source, no claim — write "could not verify" instead.
- Dispatches name: files to read, the exact output file to write, and the contract file the
  agent must read first. An under-specified dispatch is a bug; fix the dispatch, not the agent.
- Go-if conditions and unverifiable-but-load-bearing claims become decision rows:
  `node "${CLAUDE_PLUGIN_ROOT}/scripts/decisions.mjs" --add '{"question":"...","stakes":"high","default":"...","by":"research"}'`
- Never write application code; never touch files outside `.sunoku/research/` and
  `decisions.jsonl` (via its script).
