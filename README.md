# Sunoku

The living record of your product, as a Claude Code plugin. A PRD that stays current with
minimum touch: silent by default, asks before tracking, answers questions from its own record.

## Install

```
/plugin marketplace add starsynk/sunoku
/plugin install sunoku
```

## Surface

One command to learn:

- **`sunoku:init`** — set up a project (user-only). Routes by origin: validate a new idea
  (research + go/no-go), define a committed idea, or document an existing codebase. A NO-GO
  wipes `.sunoku/` — nothing to maintain for a dead idea.

The rest fires when you need it:

- **`sunoku:research`** — market/demand/competitor validation, or a deep research dive on
  anything. Cited findings in `.sunoku/research/`.
- **`sunoku:prd`** — create the PRD (from research or from the codebase) or reshape it. The
  PRD's Change Log table is the record's only history.
- **`sunoku:plan`** — PRD → `tasks.jsonl`: vertical-slice milestones, zero cross-epic deps,
  contract-first tasks that maximize parallel work.
- **`sunoku:status`** — dashboard + exactly one suggested next action.
- **`sunoku:track`** (model-invoked) — detects prompts that reshape the PRD and asks first.
  Never auto-tracks; implementation work is always silent.
- **`sunoku:read`** (model-invoked) — answers "what does the PRD say / why did we drop X /
  what's ready to work?" straight from the record, with citations.

## The record

```
.sunoku/
  PRD.md            the product, current truth; Change Log = history
  status.json       machine state (script-written)
  tasks.jsonl       backlog: milestones, epics, tasks with deps (script-written)
  decisions.jsonl   human-in-the-loop decision log (script-written)
  research/*.md     cited findings
```

Machine files are guarded by a PreToolUse hook — writes go through `scripts/status-write.mjs`,
`scripts/tasks.mjs`, `scripts/decisions.mjs`. JSONL merges cleanly (`merge=union`) and greps
fast.

Sunoku plans and documents. It never writes application code, never executes tasks, and never
syncs the record anywhere.

## Tests

```
bash tests/test-structure.sh
bash tests/test-scripts.sh
bash tests/test-hooks.sh
```

## Requirements

Node ≥ 18. Cross-platform (hooks and scripts are Node, no bash dependency).

## License

MIT
