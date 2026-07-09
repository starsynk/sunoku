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

## Loop

Sunoku holds the backlog and state; it never executes. Claude Code's `/loop` drives whatever
executor you prefer over the record.

**Drain the backlog (self-paced):**

```
/loop run sunoku:status, take a ready task, build it, mark it done, repeat until the frontier is empty
```

Each tick reads the frontier from `sunoku:status`, builds one task (your executor, not Sunoku),
flips it done via `tasks.mjs --set T-nnn status=done`.

**Watch from the side (fixed interval):** `/loop 15m /sunoku:status` — dashboard on a cadence,
silent unless something needs you.

**Opinionated build loop** (needs the `superpowers` plugin). Three variants by how the work
lands:

*Build in place* — no branch ceremony:

```
/loop Pick a task from /sunoku:status. Never skip these superpowers steps: run
superpowers:brainstorming and take its recommended approach; build it inline or with
superpowers:subagent-driven-development, taking the recommended option; write specs and plans
automatically when needed. Do not create branches or worktrees — stay on the current branch.
Maximum 10 tasks, then stop.
```

*One branch, one PR* — all tasks share a branch, single PR at the end:

```
/loop Pick a task from /sunoku:status. On the first task create a branch; commit each task to
it. Never skip these superpowers steps: run superpowers:brainstorming and take its recommended
approach; build it inline or with superpowers:subagent-driven-development, taking the
recommended option; write specs and plans automatically when needed. Maximum 10 tasks, then
open one PR and stop.
```

*Branch + PR per task* — isolate every task (fits Sunoku's parallel-ready backlog):

```
/loop Pick a task from /sunoku:status. Create a fresh branch off main for the task. Never skip
these superpowers steps: run superpowers:brainstorming and take its recommended approach;
build it inline or with superpowers:subagent-driven-development, taking the recommended
option; write specs and plans automatically when needed. Open a PR for the task and return to
main. Maximum 10 tasks, then stop.
```

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
