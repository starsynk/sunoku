# Changelog

Notable changes to the Sunoku plugin. Record-schema changes additionally land as rows in
[reference/MIGRATIONS.md](reference/MIGRATIONS.md), which skills apply to legacy records
automatically on the first touch after an upgrade.

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
