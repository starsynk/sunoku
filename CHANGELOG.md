# Changelog

Notable changes to the Sunoku plugin. Record-schema changes additionally land as rows in
[reference/MIGRATIONS.md](reference/MIGRATIONS.md), which skills apply to legacy records
automatically on the first touch after an upgrade.

## 1.8.0 — 2026-07-05

Record hygiene at scale: aging, attribution, escalation, release notes, wider write guard.

- **Question aging** — flagged assumptions gain an `**Opened:** YYYY-MM-DD` field (canon
  Assumptions + template); `report.mjs` returns `questions_aging` (id, stakes, days open,
  oldest first) and `sunoku:status` names the oldest when it passes 30 days. Undated legacy
  entries simply don't age — no migration needed.
- **Journal attribution** — `journal-append.mjs --by <name>` writes an optional `**By:**` line
  (opt-in; solo records stay clean); `report.mjs` journal matches carry `by`.
- **Drift escalation** — past 20 unreconciled commits the session-start nudge switches to
  "the record is falling behind" wording instead of the routine one-liner.
- **Write guard widened** — the PreToolUse guard now also denies direct Edit/Write on
  `.sunoku/JOURNAL.md` (use `journal-append.mjs`) and `.sunoku/journal/*` archives
  (immutable rollover history).
- **`scripts/release-notes.mjs`** — journal window (`--since`, optional `--tag`) → markdown
  changelog draft on stdout; the missing 20% on top of digest/`--since` queries.
- Tests: scripts suite 144 → 156 assertions, hooks suite 26 → 31 checks.

## 1.7.0 — 2026-07-05

Record self-service: doctor, digest, re-validation, tagged history.

- **`scripts/doctor.mjs`** — read-only integrity check as one JSON verdict: status.json enum
  values + canonical key order, summary-index freshness, live-with-stub-PRD, malformed or
  out-of-order journal headers, duplicate/malformed Q-ids, duplicate task ids / bad statuses /
  multiple `doing`, orphan phase fragments, crashed-write `*.tmp-*` leftovers, unreachable
  reconcile baseline, missing 1.6.0 `.gitattributes`. Every finding names its fix.
  `sunoku:status` narrates it on "check the record".
- **`scripts/digest.mjs`** — stakeholder one-pager assembled mechanically from the record
  (Problem paragraph, lifecycle + per-milestone standing, journal window, open questions) into
  `.sunoku/digest/<date>.md`. Derived and regenerate-anytime; `--days N` sets the window.
- **Validation staleness** — `report.mjs` flags `validation_stale` when the newest validation
  report is older than ~6 months; `sunoku:status` surfaces it and offers the new re-validate
  lane (`skills/status/references/revalidate.md`): VALIDATE machinery re-runs against the
  current PRD, produces a new immutable dated report beside the old, and the verdict lands as
  a `decision` journal entry — lifecycle stays `live` throughout.
- **Journal tags** — `journal-append.mjs --tags "pricing, auth"` writes an optional
  `**Tags:**` line; `report.mjs --since YYYY-MM-DD` / `--tag <t>` returns `journal_matches`
  across archives + live journal in one call. History queries stop degrading as the journal
  spans years.
- Disclosure map row: "status — re-validate". Canon core and status-skill size caps bumped
  consciously (4096 → 4608, 6400 → 8192) for the three new surfaces.
- Tests: scripts suite 118 → 144 assertions.

## 1.6.0 — 2026-07-05

Reliability hardening: Node hooks, a status.json write guard, and crash-safe record writes.

- **Hooks ported to Node** (`hooks/scripts/*.mjs`) — one runtime for the whole plugin (Node ≥18,
  same as `scripts/`); the Git-Bash-on-Windows requirement is gone. Behavior unchanged, plus:
  - **Baseline-lost detection** — when `last_reconciled_sha` no longer resolves (rebase, squash
    merge, force-push), the session-start context says so and points at a full reconcile instead
    of silently reporting zero drift. `report.mjs` carries the same fact as `baseline_lost`, and
    the reconcile procedure treats an unreachable sha like an empty one (full-tree read).
  - **Cache pruning** — `.sunoku/.cache/` entries older than 14 days are deleted at session
    start; the cache no longer grows without bound.
- **New PreToolUse guard** (`guard-record-writes.mjs`) — denies Edit/Write tool calls that target
  `.sunoku/status.json` and names `scripts/status-write.mjs` as the sanctioned path. The
  script-only invariant is now enforced mechanically, not just by canon instruction.
- **Crash-safe record writes** — every script write (status.json, journal + archives, questions,
  tasks) goes through temp-file + rename (`writeFileAtomic`), so a crash mid-write can never
  leave a half-written record file.
- **Agent `model:` fix** — five agents declared the undocumented value `best` (silently ignored);
  they now declare `opus` explicitly.
- **Journal field hygiene** — `journal-append.mjs` collapses newlines in `--what/--why/--refs`
  (entry fields are single-line by format), and the denormalized `status.json.last_entry` caps
  the What excerpt at 140 chars; the full text stays in the journal.
- **`tasks-set.mjs`** escapes regex metacharacters in `--id` (a `T1.` can no longer
  wildcard-match another row).
- **Union-merge ledgers** — scaffold now writes `.sunoku/.gitattributes` marking JOURNAL.md, its
  archives, and EVIDENCE.md `merge=union`, so two branches appending entries stop conflicting.
  Migration row backfills it on existing records (1.6.0).
- **`report.mjs`** gains per-milestone `milestones` counts (name/total/done) for burnup narration.
- **CI** — GitHub Actions runs all three suites on Node 18/20/22 for every push and PR.
- `plugin.json` gains `homepage`/`repository`.
- Tests: scripts suite 100 → 118 assertions, hooks suite 16 → 26 checks.

## 1.5.0 — 2026-07-04

Deterministic record scripts.

- New `scripts/` layer: nine zero-dependency Node scripts perform every mechanical record
  operation — `status-write.mjs` (all canonical status.json writes), `report.mjs` (the whole
  `sunoku:status` step-2 report as one JSON call), `journal-append.mjs` (entry append, stub
  sentinel, 30KB→15KB rollover, summary refresh), `questions-flush.mjs` (answered-block
  deletion, never renumbering), `tasks-set.mjs` (Status cell flips), `scaffold.mjs` (fresh-init
  record), `sentinels.mjs` (resume done-map), `migrate.mjs` (MIGRATIONS.md applier), sharing
  internals via `lib.mjs`.
- Skills and canon now run these scripts instead of hand-editing: judgment (triage lanes, blast
  radius, entry prose) stays with the orchestrator; serialization, counts, timestamps, shas,
  and rollovers are computed. Hand-written status.json risked breaking the byte patterns hooks
  grep; the report path drops from ~6 tool calls to 1.
- `report.mjs` counts a working tree as dirty only outside `.sunoku/` — record-only edits no
  longer trigger a reconcile offer.
- No record-shape change, so no new MIGRATIONS.md row; `sunokuVersion` restamps on next touch.
- Tests: `tests/test-scripts.sh` (100 assertions) covers all nine scripts.

## 1.4.0 — 2026-07-04

QUESTIONS.md answer-and-flush lifecycle.

- Canon assumptions gained `## Answering`: answering a flagged question appends a journal
  `decision` entry first (crash-safe order), triages the flip through the normal lanes (an
  answer is never SILENT), deletes the `## Q-<n>` block from QUESTIONS.md, and refreshes the
  status.json summary fields in the same run.
- QUESTIONS.md is now an open-questions-only working set; the chronicle lives in the journal,
  where history queries already read. Q-ids stay monotonic — surviving entries never renumber.
- Disclosure map row: answering a QUESTIONS.md entry loads `assumptions.md` + `statusfile.md`.
- `sunoku:log` gained the question-answer subject trigger; `sunoku:status` routes answers to
  `sunoku:log`.
- Template header rewritten; the `status:` field only ever holds `open` while an entry exists.
- No record migration: answered entries left in older records are inert (tooling matches
  `status: open` only) — flush them by answering, or leave them.

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
