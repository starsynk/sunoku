# Sunoku

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Claude Code plugin that keeps a living record of a software product — why it exists, what it
actually is right now, and what changed since the last time you looked.

The record lives in `.sunoku/` at the root of your repo: a PRD that describes the product as it
is now, an append-only journal of what changed and why, an evidence trail behind every research
claim, and an open-questions list. When something reshapes the product, Sunoku reconciles the PRD
forward and leaves a journal entry explaining why. Six months from now, "what is this product,
what changed since March, and why did we drop feature X?" are all answerable from the record,
with dated entries and `file:line` citations.

## Install

```
/plugin marketplace add starsynk/sunoku
/plugin install sunoku
```

Requires Node ≥ 18 — the record scripts and the ambient hooks (session-start context, the
stop-time nudge) all run on it, on every platform. No other runtime needed.

**Upgrading:** nothing to migrate by hand — records written by an older plugin self-migrate the
next time any Sunoku command touches them. Per-release changes in [CHANGELOG.md](CHANGELOG.md),
exact record fixes in [reference/MIGRATIONS.md](reference/MIGRATIONS.md).

## Quickstart

There is exactly one command to learn: **`sunoku:init`**. It creates the record if none exists,
resumes one that's mid-phase, or hands off to status if the record is already live. Everything
else is surfaced from there.

- *"is this worth building?"* — kicks off VALIDATE on a new idea.
- *"document this repo"* — reads an existing codebase and drafts its as-built PRD.
- *"what changed since May?"* — answered by `sunoku:status` from the journal and change log.

Two more commands become available once tracking is armed:

- **`sunoku:log`** — record a change or decision. Usually you won't call it directly: the
  session-stop hook nudges you when code changed but the journal didn't. Runs the
  SILENT / TRACK / RESHAPE triage and does exactly as much ceremony as the answer requires.
- **`sunoku:status`** — current product state, recent journal entries, open questions, a drift
  check against the last reconciled commit (with a reconcile offer), and answers to history
  questions straight from the record.

## What the record looks like

```
.sunoku/
├── PRD.md          # current-state truth; change log at the bottom
├── JOURNAL.md      # append-only: what changed and why (rolls over past 30KB)
├── QUESTIONS.md    # open questions, flushed as they're answered
├── BRIEF.md        # what was committed to: idea, constraints, scope
├── status.json     # machine state: phase, tracking, drift index
└── research/       # evidence ledger: demand, competitors, as-built citations
```

`ROADMAP.md` and `TASKS.md` join the record if you accept the optional PLAN phase.

A journal entry, verbatim from this repo's own record:

> **2026-07-03 — reshape**
> **What:** Dropped `sunoku:work` (feature 18) in 1.2.0 — the command, canon's Work loop section,
> and the four-command surface are gone; Sunoku is plans-and-documents-only again. […]
> **Why:** One release of owning execution showed the cost: to run unattended the loop had to
> pre-satisfy other plugins' design gates and forbid mid-run questions, displacing exactly the
> process discipline users install other plugins for. […] Record-keeping is Sunoku's product;
> execution is commodity. Decided, approved, and removed the same day the feature shipped.

Sunoku tracks its own development — browse [.sunoku/](.sunoku) in this repo for a live record.

## The four phases

**VALIDATE** *(optional)* — for a greenfield idea, first asks whether it's worth building.
Research and feasibility agents build an evidence table in parallel, a red-team pass stress-tests
the claims, and it resolves to one checkpoint: go, no-go, or go-if. A no-go still produces a
record — an immutable report of why the idea was shelved, so it doesn't get re-litigated from
scratch later. If you're already committed to building, say so and Sunoku skips VALIDATE
entirely.

**DEFINE** — product, design, and architecture drafted in parallel from the validated brief, then
red-teamed for gaps and contradictions. The output is `PRD.md`. Approving it is a checkpoint:
nothing downstream treats it as current-state truth until you sign off.

**PLAN** *(optional)* — offered once: a milestone roadmap and task breakdown, walking-skeleton M1
first, no calendar estimates. Declining is fine — skipping PLAN costs you a roadmap, not your
tracking.

**TRACK** — runs for the rest of the product's life. Every change gets triaged: would the PRD or roadmap need
edits to stay accurate? No → silence. Yes → a journal entry. Reshapes the product → a scoped
re-dispatch to the owning agents, one checkpoint for the full delta, and journal + PRD + roadmap
reconciled together.

**Existing codebase?** Sunoku reads the repo, writes an as-built PRD with every claim cited
`file:line`, and hands it back with one question: "here is what I understood your product to
be — correct me." Tracking arms as soon as you approve. Both paths run through the same
`sunoku:init`; it detects which one you're in. (A freshly generated scaffold counts as greenfield —
the scaffold becomes your recorded starting stack.)

Full doctrine — triage lanes, checkpoint ceremony, coexistence with your other plugins — lives in
[reference/canon.md](reference/canon.md).

## What doesn't get recorded

Bugfixes, refactors, and style passes don't get journal entries — the triage stays silent on them
by design, so the journal only holds entries that change the product's story. To go fully quiet,
ask `sunoku:status` to mute tracking (it flips `tracking: false` in `status.json`); the record
stays intact for whenever you turn it back on. If commits land without matching journal entries,
`sunoku:status` reports the drift and offers to reconcile: it reads the actual diff, groups it,
and runs each group through the same triage as `sunoku:log`.

## Executing the backlog

Sunoku deliberately ships no executor. `TASKS.md` is an open contract — statuses
`todo / doing / done / blocked`, a `Blocked` table, dependency-ordered milestones — that anything
can work: you by hand, a plain Claude session, or whatever process plugins you already run.
Executors that update `Status` keep the record realtime; executors that never touch it cost
nothing — the next reconcile reads the actual diff and flips landed tasks to `done`.

One shape that works well: pair the built-in `/loop` with a one-task-per-iteration prompt, so the
loop's state lives in `TASKS.md`, not the conversation:

```
/loop Work exactly one task from .sunoku/TASKS.md this iteration: resume the `doing` row if one
exists, else take the first `todo` in the current milestone whose "Depends on" IDs are all done.
Mark it doing first, implement it with tests on a work branch (never the default branch), verify
with the project's own test/build, then mark it done and commit as "T-<n>: <title>". If it won't
verify after 3 distinct attempts, mark it blocked with a reason in the Blocked table, flag what
would unblock it in .sunoku/QUESTIONS.md, and move on to a task that doesn't depend on it. Never
ask me questions mid-run — take the inferable default and flag it in QUESTIONS.md. When the
milestone has no eligible task left, report each ROADMAP exit criterion as met/unmet and stop
the loop.
```

- Run it in a session pre-approved for edits, git, and tests — one permission dialog stalls an
  unattended iteration.
- The milestone boundary is your review gate: let the loop stop there, review, merge, re-arm.
- Your other plugins keep firing inside each iteration — TDD, verification, house conventions.
  Sunoku only settles the task's design (the PRD trace); process discipline still applies.

## How the plugin is built

- `reference/canon.md` — always-read core rulebook; per-lane sections in `reference/canon/` load
  on demand.
- `reference/contracts/` — per-hat output contracts for multi-hat agents.
- `skills/*/references/` — lane and phase procedures loaded only when that branch runs.
- `scripts/` — zero-dependency Node (≥18) scripts that perform every mechanical record write:
  canonical `status.json` serialization, journal append + rollover, question flushes, task-status
  flips, scaffolding, migrations — plus read-only reporting (`report.mjs`, `doctor.mjs`,
  `digest.mjs`, `release-notes.mjs`). Skills decide *what* to record; scripts make the bytes
  deterministic.

## License

MIT — see [LICENSE](LICENSE).
