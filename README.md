# Sunoku

The living record of your product, as a Claude Code plugin. A PRD that stays current with
minimum touch: silent by default, asks before tracking, answers questions from its own record.

## Install

```
/plugin marketplace add starsynk/sunoku
/plugin install sunoku
```

## Skills

Nine skills, gateway-driven. When `.sunoku/` exists, a SessionStart hook injects the
gateway skill wholesale into every session — routing table from prompt to skill, plus the
red-flags discipline (never auto-track, never execute, never invent history). No record,
no injection: Sunoku stays silent.

| Skill | Invocation | Use when |
|---|---|---|
| `sunoku:using-sunoku` | Gateway — injected at session start when a record exists | Routes every product-shaped prompt to the right skill before any response. Implementation work (bugfixes, refactors, in-scope features) stays silent. |
| `sunoku:starting-a-product` | User command only (model won't self-invoke) | Set up a project. Routes by origin: validate a new idea (research + go/no-go), define a committed idea, or document an existing codebase. A NO-GO wipes `.sunoku/` — nothing to maintain for a dead idea. |
| `sunoku:researching` | User or model | Market/demand/competitor validation, or a deep cited research dive on anything. Findings land in `.sunoku/research/`, adversarially red-teamed. |
| `sunoku:writing-the-prd` | User or model | Create the PRD (from research or from the codebase) or reshape it — "we're adding/dropping X". The PRD's Change Log table is the record's only history. |
| `sunoku:planning-the-work` | User or model | PRD → `tasks.jsonl`: vertical-slice milestones, zero cross-epic deps, contract-first tasks that maximize parallel work. Also re-plans after a PRD change. |
| `sunoku:checking-status` | User or model | "Status", "what's next", "where are we", mute/unmute tracking. Dashboard + exactly one suggested next action. |
| `sunoku:viewing-the-record` | User or model | "Show tasks", "task board", "open the backlog". Renders tasks + decisions into a self-contained `.sunoku/record.html` snapshot and opens it — read-only, no server. |
| `sunoku:tracking-changes` | Internal — model-invoked consent gate | Fires when a work prompt would reshape the PRD (scope, core bet, architecture, target segment, pricing) on a live record. Asks first, never auto-tracks. |
| `sunoku:querying-the-record` | Internal — model-invoked retrieval | "What does the PRD say", "why did we drop X", "what changed since May", task state — answered from the record with citations, never from memory. |

Every skill shares one anatomy: overview + core principle, announce-at-start, checklists,
flowcharts at non-obvious decisions, red-flags tables, and integration cross-refs that name
the next skill. Research and PRD skills dispatch generic subagents from skill-owned prompt
files (`references/*-prompt.md`) — no custom agent types.

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
/loop run sunoku:checking-status, take a ready task, build it, mark it done, repeat until the frontier is empty
```

Each tick reads the frontier from `sunoku:checking-status`, builds one task (your executor, not Sunoku),
flips it done via `tasks.mjs --set T-nnn status=done`.

**Watch from the side (fixed interval):** `/loop 15m /sunoku:checking-status` — dashboard on a cadence,
silent unless something needs you.

**Opinionated build loop** (needs the `superpowers` plugin). Three variants by how the work
lands:

*Build in place* — no branch ceremony:

```
/loop Pick a task from /sunoku:checking-status. Never skip these superpowers steps: run
superpowers:brainstorming and take its recommended approach; build it inline or with
superpowers:subagent-driven-development, taking the recommended option; write specs and plans
automatically when needed. Do not create branches or worktrees — stay on the current branch.
Maximum 10 tasks, then stop.
```

*One branch, one PR* — all tasks share a branch, single PR at the end:

```
/loop Pick a task from /sunoku:checking-status. On the first task create a branch; commit each task to
it. Never skip these superpowers steps: run superpowers:brainstorming and take its recommended
approach; build it inline or with superpowers:subagent-driven-development, taking the
recommended option; write specs and plans automatically when needed. Maximum 10 tasks, then
open one PR and stop.
```

*Branch + PR per task* — isolate every task (fits Sunoku's parallel-ready backlog):

```
/loop Pick a task from /sunoku:checking-status. Create a fresh branch off main for the task. Never skip
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
