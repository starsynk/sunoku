# Sunoku Canon

The shared rulebook. Every skill reads this file first via `${CLAUDE_PLUGIN_ROOT}/reference/canon.md`
and cites it in every dispatch to agents. If a skill or agent instruction conflicts with this file,
this file wins.

## Prime directive

Sunoku plans and documents products. It never writes application code and never touches a
consumer repo's source tree — Sunoku writes only `.sunoku/` at the consumer repo root. Executing
the plan is deliberately not Sunoku's job: `TASKS.md` is an open contract worked by whatever the
user prefers (see reference/canon/execution-contract.md), and the record catches up by observation. No external
exports exist: nothing in this canon authorizes syncing the
record to any third-party system. The living record is the product: JOURNAL.md, EVIDENCE.md,
QUESTIONS.md, and status.json accumulate across the product's life. The PRD is not a one-time
deliverable — it is the current-state snapshot of that ongoing chronicle, reconciled forward as
the journal grows.

## Coexistence

A Sunoku flow narrows exactly one thing in the assistant's behavior: it settles **product design
authority** — what to build, why, and in what order — because that is already decided upstream in the
PRD, roadmap, and task trace. Inside such a flow the assistant does not re-open that design;
brainstorming or redesigning a task mid-execution is out of scope.

It narrows nothing else. Every other skill the assistant would apply outside a Sunoku flow —
engineering, testing, debugging, verification, house coding conventions, and the like, from any
plugin or source — stays fully live and must fire exactly as it normally would. Sunoku claims the
product-design decision and no other.

Suppressing an applicable skill because "a Sunoku flow is driving" is a Sunoku failure, as much as
pausing on a SILENT change is. Upstream approval removes the design question, never the assistant's
craft.

## Triage

Every change to a tracked product runs through one test before anything else. Ask it verbatim:

> "after this change, would the PRD or the plan need editing beyond a task-status flip — or
> did it complete a milestone?"

Route the answer into exactly one of three lanes:

- **SILENT** — the change alters implementation, not the product story: the PRD stays accurate
  as written (bugfixes, styling, refactors, perf, config, copy land here). Work a TASKS.md
  row already plans is silent too: flip it via `scripts/tasks-set.mjs` and stop; the task
  trace is the record. No journal entry, no agent, no other file touch.
- **TRACK** — fits the current direction and changes none of the reshape set. One journal entry,
  plus a task append if a roadmap exists. Zero ceremony: no subagents, no checkpoint gate.
  Journal grain is milestone/theme, never per task: a completed milestone earns one entry, a
  single planned task never does.
- **RESHAPE** — changes one of the reshape set: **{core bet, product scope, architecture, target segment, pricing}**.
  Triggers a scoped re-run, exactly one checkpoint, and a reconcile pass: journal → PRD → roadmap,
  plus a Change Log row.

If the lane is ambiguous, default to TRACK and drop a flag in QUESTIONS.md. Never silently RESHAPE.
Noise is a product failure: an orchestrator that RESHAPEs on every small change, or that pauses for
ceremony on a SILENT change, has failed this canon as surely as one that skips a real reshape.

## Disclosure map

This core file is always read in full. The sections that moved to `reference/canon/` load
per lane. A lane's list below is mandatory — load every file it names and nothing beyond it.
Every dispatch or skill step that loads one does so by exact path, never "if needed."

| Lane | Required section files (`reference/canon/`) |
|---|---|
| log — SILENT / TRACK | statusfile.md on any write (SILENT writes nothing and loads nothing) |
| log — RESHAPE | dispatch.md, checkpoints.md, assumptions.md, statusfile.md |
| status — report / history | none |
| status — reconcile | dispatch.md, statusfile.md, sentinels-resume.md |
| status — re-validate | dispatch.md, fragments.md, garbage-output.md, conflict.md, checkpoints.md, statusfile.md |
| init — any phase | dispatch.md, fragments.md, garbage-output.md, conflict.md, sentinels-resume.md, checkpoints.md, statusfile.md, assumptions.md |
| any run that detects version skew | record-migrations.md |
| any triage that flags an ambiguous classification | assumptions.md |
| answering a QUESTIONS.md entry | assumptions.md, statusfile.md |
| reporting a workable backlog | execution-contract.md |
