# Changelog

Notable changes to the Sunoku plugin. Record-schema changes additionally land as rows in
[reference/MIGRATIONS.md](reference/MIGRATIONS.md), which skills apply to legacy records
automatically on the first touch after an upgrade.

## 1.3.0 — 2026-07-04

Token optimization: progressive disclosure across the plugin.

- Canon split: always-read core (Prime directive, Coexistence, Triage, Disclosure map) plus
  per-section files under `reference/canon/`; skills load sections per lane.
- Guards now run before any canon read; dead invocations cost ~200 tokens.
- Lane files: `log` RESHAPE, `status` reconcile, all four `init` phases, and first-run onboarding load on demand.
- Multi-hat agent contracts split into `reference/contracts/<agent>-<hat>.md`; dispatches name
  the contract file (dispatch item 6).
- Hook context compressed; version-skew nudge is direction-aware (newer record -> update plugin).
- Skill/agent descriptions trimmed to routing triggers.
- status.json gains a summary index (`one_liner`, `open_questions`, `high_stakes`,
  `last_entry`); pre-1.3.0 records self-migrate on first touch.
- JOURNAL.md rolls entries past 30KB into `.sunoku/journal/<year>.md`.

## 1.2.0 — 2026-07-03

### Removed

- **`sunoku:work`** (breaking — the command is gone). One release in, owning execution proved to
  put Sunoku in the execution-harness business: to run unattended it had to pre-satisfy other
  plugins' design gates and forbid mid-run questions, displacing exactly the process discipline
  (TDD, plan execution, review checkpoints) users install other plugins for. Sunoku returns to
  its prime directive: it plans and documents, and never writes application code.

### Added

- **Canon `Coexistence` section** — a Sunoku flow settles product-design authority (already
  decided in the PRD, roadmap, and task trace) and suppresses no other skill from any plugin or
  source.
- **Canon `Execution contract`** (replaces `Work loop`) — `TASKS.md` is an open contract any
  executor may work: the status vocabulary, `Blocked` table + QUESTIONS.md flag conventions, and
  milestone-grained journaling, with Sunoku never policing the executor.
- **Reconcile status catch-up** — reconcile flips a planned task to `done` when the diff shows
  its work landed, so executors that never touch `Status` still leave a true record.
- Migration row (1.2.0): legacy `TASKS.md` Status legends naming `sunoku:work` self-rewrite on
  first touch.

### Changed

- README and `sunoku:init` describe the three-command surface; `sunoku:status` suggests the
  backlog as workable by any executor rather than naming a Sunoku command.

### Upgrade notes (from 1.1.0)

Nothing to migrate by hand; the record schema is unchanged — the `Status` column and `Blocked`
table stay. Stop invoking `/sunoku:work`: execute the backlog with anything you like (README
"Executing the backlog"), and the next reconcile keeps `TASKS.md` honest either way.

## 1.1.0 — 2026-07-03

### Added

- **`sunoku:work`** — the fourth command. Arms Claude Code's built-in `/loop` and executes
  `.sunoku/TASKS.md` one task per iteration: implement, verify, commit on an auto-created
  `sunoku/m<n>` milestone branch, mark done. A task that won't verify gets three attempts, then a
  `blocked` mark and the loop continues past it. Stops at every milestone boundary for review
  (exit-criteria report, one journal entry, interactive push + PR offer). Explicit invocation
  only; asks nothing mid-run; never pushes unattended.
- **TASKS.md schema** — `Status` column (`todo / doing / done / blocked`) on every task row and a
  `## Blocked` table (`ID | Attempts | Reason`). `delivery-planner` emits it; RESHAPE patches
  preserve existing Status values.
- **`status.json.sunokuVersion`** — the plugin version that last wrote the record; re-stamped on
  every record write.
- **Record migrations registry** (`reference/MIGRATIONS.md`) + canon "Record migrations" rule —
  legacy records self-migrate in place, silently, on the first skill touch after an upgrade.
- **Version-skew nudge** — the SessionStart hook compares `sunokuVersion` against the installed
  plugin and injects a one-line migration pointer on mismatch (read-only; hooks never write the
  record).
- Scenario F/F2 regression runs for the work loop; hook suite grown 12 → 15 assertions.

### Changed

- Canon: prime directive scoped to planning agents — `sunoku:work` is the single sanctioned
  execution surface, driving the main assistant; new "Work loop" and "Record migrations"
  sections; `version` / `sunokuVersion` field glosses.
- `sunoku:status` suggests the backlog (todo/doing/blocked counts) as a next action when nothing
  more urgent is pending.
- README and `sunoku:init` describe the four-command surface.

### Upgrade notes (from 1.0.0)

Nothing to do by hand. On the first session after upgrading, the session-start nudge flags the
record; the next record touch (e.g. `sunoku:status`) adds the `Status` column to any planned
TASKS.md (all rows `todo` — hand-mark rows already done before running `sunoku:work`) and stamps
`sunokuVersion`.

## 1.0.0 — 2026-07-02

Initial release: VALIDATE / DEFINE / PLAN / TRACK lifecycle; `sunoku:init`, `sunoku:log`,
`sunoku:status`; eight hub-and-spoke subagents; the `.sunoku/` living record (journal, PRD,
evidence, questions, status.json); two ambient hooks (session-start triage rule + drift count,
one-shot stop nudge); hook regression suite and headless scenario log.
