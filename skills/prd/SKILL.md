---
name: prd
description: Create or reshape the Sunoku PRD. Create mode drafts from a brief + research; existing mode reconstructs from the codebase; reshape mode patches named sections and appends a Change Log row. Use for "write the PRD", "update the PRD", "we're adding/dropping X", "refresh the PRD from the code".
---

## Mission

Own `.sunoku/PRD.md` — the human artifact and, via its Change Log table, the record's only
history. One checkpoint per run: approval of the draft (create/existing) or of the patch
(reshape).

## Routing

Requires a scaffolded record (`.sunoku/status.json` present) — if absent, route the user to
`sunoku:init` and stop. Then pick the mode:

| Situation | Mode | Reference to read and follow exactly |
|---|---|---|
| PRD missing or still stub-sentineled, greenfield | create | `references/create.md` |
| PRD missing or stub, codebase exists to document | existing | `references/existing.md` |
| PRD filled, a change is named (by user or sunoku:track) | reshape | `references/reshape.md` |

All references live under `${CLAUDE_PLUGIN_ROOT}/skills/prd/references/`.

## Rules

- Template: `${CLAUDE_PLUGIN_ROOT}/skills/prd/templates/PRD.md`. Keep its section set; the
  Change Log table format (`| date | change | why | trigger |`) is machine-read — never alter
  its columns.
- Every feature row traces to evidence (a research file / decision id) or names its assumption.
- Assumptions taken while drafting become decision rows with a recommended default
  (`decisions.mjs --add`, `"by":"prd"`); the run continues without waiting.
- A user answer that changes the PRD is a reshape; after patching, resolve the row
  (`decisions.mjs --resolve <id> --answer "..."`).
- After any approved draft or patch, restamp the record so staleness counting resets:
  `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --set one_liner="..."` when the
  one-liner changed, `--touch` otherwise.
- Never write application code; never touch files outside `.sunoku/`.
