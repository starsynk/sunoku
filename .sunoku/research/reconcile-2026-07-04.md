# Reconcile — 7678988..a728727 (2026-07-04): 58 files, +2021/−467 (~2488 changed lines), 47 commits

Baseline checked against: `.sunoku/PRD.md` (current). No `.sunoku/ROADMAP.md` or `.sunoku/TASKS.md`
exists, so there are no planned task rows this diff could flip — the 1.3.0 work was planned outside
the record (the new structure harness references "Task 2…13" from an untracked plan,
`tests/test-structure.sh:22,30,44,51,63,68,76,81,87,91`).

## Groups

### 1. Dogfood onboarding — Sunoku's own living record created

- **What changed** — the entire `.sunoku/` record is new inside this range: `BRIEF.md` (31 lines),
  as-built PRD (`.sunoku/PRD.md:1-186`), journal opened with the armed entry citing the range base
  sha (`.sunoku/JOURNAL.md:6-9`), `QUESTIONS.md` with Q-1/Q-2 open and Q-3 answered
  (`.sunoku/QUESTIONS.md:8-42`), evidence ledger and as-built report
  (`.sunoku/research/EVIDENCE.md`, `.sunoku/research/as-built.md`), `status.json`
  (`.sunoku/status.json:1-15`) and `.sunoku/.gitignore:1-2`. The journal then kept pace through the
  range: scaffold-detection track, work-loop reshape, migrations track, Coexistence track, work-drop
  reshape, and the 1.3.0 track entry (`.sunoku/JOURNAL.md:11-39`).
- **PRD/roadmap accuracy** — no product-doc impact: these files ARE the product docs. They are the
  baseline this report checks the rest of the diff against, not a change to reconcile.
- **Evidence** — `.sunoku/JOURNAL.md:6-9` (armed at `7678988…`, the exact range base);
  `.sunoku/status.json:12` (`last_reconciled_sha` = range base).

### 2. Init origin detection — fresh-scaffold substance test

- **What changed** — the old detector ("source present → existing-code flow") was replaced by a
  framework-agnostic substance test: "if this repo were deleted and its generator re-run, would
  anything of substance be lost?", judged on four signals (git-history shape, domain vocabulary,
  divergence from generator output, wiring). Fresh scaffolds (create-next-app, cargo new, etc.)
  now route to the greenfield flow with the scaffold recorded as the starting stack in BRIEF
  Constraints and confirmed inside the scoping batch
  (`skills/init/references/onboarding.md:5-28`). README documents the routing
  (`README.md:116-119`); Scenario E exercised it against a fake create-next-app fixture and passed
  (`tests/scenarios.md:212-235`).
- **PRD/roadmap accuracy** — low/none, and the journal already tracks it
  (`.sunoku/JOURNAL.md:11-14`). The PRD's UX line "Sunoku detects source" (`PRD.md:104-105`) stays
  accurate at its abstraction level; features 2 and 3 (`PRD.md:35-36`) are unchanged in substance.
  Unsure-flag: if the PRD is meant to name detection behavior at all, this is the one behavioral
  routing change in the range it does not mention.
- **Evidence** — `skills/init/references/onboarding.md:8-28`; `tests/scenarios.md:212-235`;
  `README.md:116-119`.

### 3. `sunoku:work` added (1.1.0) then dropped (1.2.0) — Execution contract and Coexistence survive

- **What changed** — net across the range no `skills/work/` exists, but the schema it introduced
  stays as an open contract: the TASKS template gained a Status legend, a `Status` column in the
  commented header, and a `## Blocked` table (`reference/templates/TASKS.md:5-12`); the planner's
  full-plan contract mandates `| ID | Task | Size | Trace | Depends on | Status |` with Status
  always `todo` at planning time and an empty Blocked section emitted
  (`reference/contracts/delivery-planner-full-plan.md:18,30-33`); the RESHAPE hat must preserve
  existing Status values (`reference/contracts/delivery-planner-reshape.md:5-8`). Canon's Prime
  directive now states executing the plan is deliberately not Sunoku's job
  (`reference/canon.md:10-12`), backed by a new Execution contract section — states, Blocked
  conventions, milestone-grained journaling, reconcile catch-up
  (`reference/canon/execution-contract.md:1-24`) — and a new top-level Coexistence principle:
  Sunoku settles product-design authority only and suppresses no other skill
  (`reference/canon.md:19-33`). `sunoku:status` now reports todo/doing/blocked counts as a
  next-action instead of naming an executor (`skills/status/SKILL.md:53-57`), reconcile flips
  diff-proven task rows to `done` (`skills/status/references/reconcile.md:25-28`), and README
  gained an "Executing the backlog" section with a `/loop` recipe (`README.md:138-190`).
- **PRD/roadmap accuracy** — already reconciled: the PRD Change Log carries both the add and the
  drop (`PRD.md:184-185`), the features table skips #18, Prime-directive/out-of-scope bullets
  describe the open Execution contract (`PRD.md:82-85,127-129`), and the Architecture rulebook
  list names Coexistence and Execution contract (`PRD.md:76-78`). No new staleness from this
  group beyond the citation rot covered in group 5 (the cited canon sections moved files).
- **Evidence** — `reference/templates/TASKS.md:5-12`;
  `reference/contracts/delivery-planner-full-plan.md:30-33`; `reference/canon.md:10-12,19-33`;
  `reference/canon/execution-contract.md:8-24`; `skills/status/references/reconcile.md:25-28`;
  `PRD.md:184-185`.

### 4. Self-migrating record schema + version-skew nudge (PRD feature 19 landing)

- **What changed** — new migrations registry with shape-sniffed, idempotent, SILENT-lane rows for
  1.1.0 (TASKS Status column; `sunokuVersion` insertion), 1.2.0 (legend rewrite), and
  1.2.x→1.3.0 (summary-field backfill) (`reference/MIGRATIONS.md:9-30`), governed by a canon
  Record-migrations section — skills migrate, hooks only detect (`reference/canon/record-migrations.md:3-14`).
  The SessionStart hook gained a direction-aware version-skew nudge: record older → "migrates on
  next record touch"; record newer than plugin → "update the Sunoku plugin"
  (`hooks/scripts/session-start.sh:40-54`), and its injected CTX plus drift line were compressed
  (`hooks/scripts/session-start.sh:33-37`). `sunokuVersion` entered the canonical schema and the
  example template (`reference/canon/statusfile.md:10,29-31`;
  `reference/templates/status.json.example:3`). Hook suite grew four skew assertions (tests
  11-14, `tests/test-hooks.sh:96-119`); Scenario F3 verified a 1.0.0 record self-migrating on
  first touch (`tests/scenarios.md:283-330`).
- **PRD/roadmap accuracy** — this IS feature 19's work landing; the row already exists
  (`PRD.md:51`). Its trace goes slightly stale: "reference/canon.md (Record migrations)" now lives
  at `reference/canon/record-migrations.md`, and the cited `session-start.sh:40-52` block is now
  lines 40-54 with the direction-aware messaging. Feature 11's trace
  (`session-start.sh:33-40`, `PRD.md:44`) still points at the right block but the injected wording
  it describes was rewritten. No TASKS row to flip (none exists).
- **Evidence** — `reference/MIGRATIONS.md:23-30`; `hooks/scripts/session-start.sh:40-54`;
  `tests/test-hooks.sh:96-119`; `tests/scenarios.md:283-311`; `PRD.md:44,51`.

### 5. Canon split — always-read core + per-lane section files + Disclosure map (1.3.0)

- **What changed** — `reference/canon.md` shrank from 238 lines to 70: it retains only Prime
  directive, Coexistence, Triage, and a new Disclosure map that names, per lane, exactly which of
  the ten new `reference/canon/` section files to load ("load every file it names and nothing
  beyond it") (`reference/canon.md:55-70`). Checkpoints, Assumptions, Dispatch, Fragments,
  Garbage output, Conflict, Sentinels & resume, StatusFile, Record migrations, and Execution
  contract each moved verbatim-in-substance to their own file
  (`reference/canon/checkpoints.md`, `assumptions.md`, `dispatch.md`, `fragments.md`,
  `garbage-output.md`, `conflict.md`, `sentinels-resume.md`, `statusfile.md`,
  `record-migrations.md`, `execution-contract.md`). Later fixes made the map cover
  `assumptions.md` for init and ambiguous-flag triage (`reference/canon.md:67,69`) and pointed the
  core Execution-contract reference at its section file (`reference/canon.md:12`).
- **PRD/roadmap accuracy** — the biggest staleness in the range, concentrated in the PRD
  Architecture section. Stale now: "reference/canon.md (238 lines) is read first by all three
  skills … it owns [13 sections] so no skill restates them" (`PRD.md:74-78`) — canon is 70 lines,
  owns 4 sections, and log/status read it second (see group 6); "git ls-files = 40 files"
  (`PRD.md:57`) — now 70 tracked files; the Rejected-alternative bullet's cites
  `reference/canon.md:69-71` and `:84-96` (`PRD.md:92-96`) — that content now lives at
  `reference/canon/dispatch.md:3-6` and `reference/canon/fragments.md:3-13`; feature traces
  `canon.md:16-34` (feature 7, `PRD.md:40` — Triage is now `canon.md:35-53`), `canon.md:136-169`
  (feature 10, `PRD.md:43` — now `reference/canon/statusfile.md`), `canon.md:67-96` (feature 15,
  `PRD.md:48`); Success-metrics cites `canon.md:24-26`, `:28-30`, `:117-135`
  (`PRD.md:143,146,150` — now `canon.md:43-49` and `reference/canon/sentinels-resume.md:12-18`).
  The journal records the split (`.sunoku/JOURNAL.md:36-39`) but the PRD was not reconciled for it.
- **Evidence** — `reference/canon.md:55-70` (map); `wc -l reference/canon.md` = 70 vs
  `PRD.md:74`; `git ls-files | wc -l` = 70 vs `PRD.md:57`; `reference/canon/statusfile.md:1`;
  `reference/canon/dispatch.md:1`.

### 6. Skill-body restructure — guards before canon, lane files, init router

- **What changed** — `sunoku:log` and `sunoku:status` now run their record guards as step 1 and
  read canon core only after the guard passes (`skills/log/SKILL.md:14-27`;
  `skills/status/SKILL.md:13-25`), so dead invocations never load canon. The RESHAPE procedure
  moved whole to `skills/log/references/reshape.md:1-41` (SKILL.md keeps a pointer,
  `skills/log/SKILL.md:76-79`); the reconcile procedure moved to
  `skills/status/references/reconcile.md:1-32` (`skills/status/SKILL.md:76-80`). `sunoku:init`
  became a 137-line router: first-run onboarding (origin detection + both scoping flows) extracted
  to `skills/init/references/onboarding.md` and loaded only when `status.json` is absent
  (`skills/init/SKILL.md:53-56`), a resume table maps lifecycle+origin to exactly one phase file
  (`skills/init/SKILL.md:45-52`), and the four phases live in
  `skills/init/references/{validate,define,plan,existing}.md` loaded on demand
  (`skills/init/SKILL.md:85-121`). Behavioral fixes riding along: a resume that finds BRIEF.md
  still stub-sentineled loads the onboarding scoping section (`skills/init/SKILL.md:52-53`); the
  gap list's home is pinned as a `## Gap List` section inside PRD.md, never a separate file
  (`skills/init/references/existing.md:14-17`); critique fragments are explicitly deleted after
  each fix loop (`skills/init/references/validate.md:22`, `define.md:15-16`, `plan.md:10-11`,
  `existing.md:33`; `skills/log/references/reshape.md:20-23`); reconcile and drift both handle an
  empty `last_reconciled_sha` instead of silently reading zero
  (`skills/status/SKILL.md:46-49`; `skills/status/references/reconcile.md:8-11`).
- **PRD/roadmap accuracy** — feature-trace citation rot: features 1-6 cite
  `skills/init/SKILL.md:23-48/:138-173/:67-136/:83-105/:106-121/:123-129` (`PRD.md:34-39`) — the
  file is now 137 lines and those phase bodies live under `skills/init/references/`; feature 7's
  `skills/log/SKILL.md:35-53` and feature 8's `skills/status/SKILL.md:26-91` (`PRD.md:40-41`)
  shifted; UX cites `skills/init/SKILL.md:154-159` (accuracy gate) and `:161-165` (memory-first
  arm) (`PRD.md:107-108`) now live at `skills/init/references/existing.md:13-28`; out-of-scope's
  journal-starts-empty cite `skills/init/SKILL.md:150` (`PRD.md:138`) is now
  `skills/init/references/existing.md:9-11`; onboarding-fidelity metric cite
  `skills/init/SKILL.md:150-156` (`PRD.md:152`) likewise. The empty-sha drift fix also makes
  feature 14's description slightly richer than its trace (`PRD.md:47`). Substance of every flow
  is unchanged — this is stale-citation impact, not stale-behavior impact.
- **Evidence** — `skills/log/SKILL.md:14,23`; `skills/status/SKILL.md:13,22`;
  `skills/init/SKILL.md:45-56`; `skills/init/references/existing.md:13-28`;
  `skills/status/references/reconcile.md:8-11`.

### 7. Multi-hat agent contracts split into dispatch-named files

- **What changed** — the five multi-hat agents (product-owner, feasibility-assessor,
  codebase-analyst, delivery-planner, red-team) lost their embedded per-hat output contracts;
  each hat now lives in `reference/contracts/<agent>-<hat>.md` (11 files, 152 lines total) and
  every agent instead requires the dispatch to name its contract file
  (`agents/codebase-analyst.md:28-30`; `agents/delivery-planner.md:30-32`;
  `agents/product-owner.md:25-27`; `agents/feasibility-assessor.md:30-32`;
  `agents/red-team.md:25-27`). Canon Dispatch gained required item 6 — the exact contract file,
  multi-hat agents only (`reference/canon/dispatch.md:14-19`). Content moved intact (e.g. the
  no-git-archaeology rule now closes the reconstruct contract,
  `reference/contracts/codebase-analyst-reconstruct.md:29-32`), with two net-new pieces: a
  dedicated gap-plan contract narrowing full-plan to the named gap list
  (`reference/contracts/delivery-planner-gap-plan.md:3-6`, closing a dead end where the split
  left that hat contract-less), and the reshape hat's pointer fixed at the full-plan contract
  file (`reference/contracts/delivery-planner-reshape.md:10-12`). All eight agent descriptions
  (and the three skill descriptions) were trimmed to routing triggers with trigger phrases kept
  verbatim (`agents/*.md:3`; enforced by `tests/test-structure.sh:65-72`).
- **PRD/roadmap accuracy** — feature 15 (`PRD.md:48`) stays true in substance ("each a
  tool-scoped Markdown contract") but its `reference/canon.md:67-96` cite moved to
  `reference/canon/dispatch.md`, and the dispatch rule it summarizes is now six items, not five.
  No other PRD claim depends on where the hat contracts live.
- **Evidence** — `reference/canon/dispatch.md:14-19`; `ls reference/contracts/` (11 files);
  `reference/contracts/delivery-planner-gap-plan.md:3-6`;
  `reference/contracts/codebase-analyst-reconstruct.md:29-32`.

### 8. status.json summary index + status surface reads from it

- **What changed** — the canonical `status.json` schema gained four denormalized summary fields —
  `one_liner`, `open_questions`, `high_stakes`, `last_entry` — refreshed by every write that
  changes their source (`reference/canon/statusfile.md:8-23,40-44`), with a 1.2.x→1.3.0 migration
  row backfilling them on first touch (`reference/MIGRATIONS.md:23-30`). The status report now
  renders from the index instead of opening the record: one-liner from `one_liner`, journal
  freshness from `last_entry`, question counts from `open_questions`/`high_stakes` — with
  heading-anchored `grep` drill-ins only on request (`skills/status/SKILL.md:28-38`); only
  `status: open` entries count (`skills/status/SKILL.md:35-38`), where the old text counted all
  entries. log/RESHAPE/reconcile writes refresh the index in the same status.json write
  (`skills/log/SKILL.md:84-86`; `skills/log/references/reshape.md:38-41`;
  `skills/status/references/reconcile.md:29-32`); init stamps initial values at scaffold and arm
  (`skills/init/SKILL.md:66-72,104-107`). Observed inconsistency left by the diff:
  `reference/templates/status.json.example:1-11` gained only `sunokuVersion` and still lacks the
  four summary fields that `reference/canon/statusfile.md:8-23` declares part of the mandatory
  canonical key order — a fresh record scaffolded from the example alone would not match canon
  (init routes writers to statusfile.md, so this is a stale illustration, but it is the one
  in-repo contradiction this diff introduces).
- **PRD/roadmap accuracy** — feature 10 (`PRD.md:43`) understates the schema (its trace
  `canon.md:136-169` moved to `reference/canon/statusfile.md`, and "canonical serialization" now
  spans 12 keys including the index); feature 8's description of the report surface
  (`PRD.md:41`) predates index-backed reads. Both are precision staleness, not behavior
  contradiction. The template/canon mismatch above is a code-side inconsistency worth a flag
  rather than a PRD edit.
- **Evidence** — `reference/canon/statusfile.md:8-23,40-44`; `skills/status/SKILL.md:28-38`;
  `reference/templates/status.json.example:1-11`; `reference/MIGRATIONS.md:23-30`.

### 9. Journal rollover — entries past 30KB archive to `.sunoku/journal/<year>.md`

- **What changed** — after any TRACK append, if JOURNAL.md exceeds 30KB the oldest whole entries
  move (never split, bodies never edited, original order) into append-only
  `.sunoku/journal/<year-of-entry>.md` files until JOURNAL.md is under 15KB, leaving a
  `> Older entries: .sunoku/journal/` pointer line (`skills/log/SKILL.md:70-74`). History
  questions scan the archives too (`skills/status/SKILL.md:63-65`). Scenario G6 specifies the
  regression check (`tests/scenarios.md:405-410`).
- **PRD/roadmap accuracy** — feature 9 "Append-only living record: JOURNAL.md…" (`PRD.md:42`)
  does not mention the yearly archive files, and the UX claim that state lives "under `.sunoku/`,
  browsable directly" (`PRD.md:119-120`) now includes a `journal/` subdirectory it doesn't name.
  Append-only semantics are preserved, so this is an omission, not a contradiction — the one
  genuinely new user-visible capability in the range with no PRD feature row.
- **Evidence** — `skills/log/SKILL.md:70-74`; `skills/status/SKILL.md:63-65`;
  `tests/scenarios.md:405-410`.

### 10. Test infrastructure — structure harness, scenario log growth, hook suite 12→16

- **What changed** — new `tests/test-structure.sh` (94 lines): pure grep/stat invariants pinning
  the 1.3.0 shape — guard-before-canon ordering, the ten canon section files and core size cap,
  lane files, description length caps with trigger phrases intact, init router files, the 11
  contract files, six-item dispatch phrasing, summary fields, rollover rule, and version
  alignment (`tests/test-structure.sh:14-93`). The scenario log grew from 11 recorded runs to 11
  runs + full write-ups for E (scaffold routing, PASS, `tests/scenarios.md:212-235`), F/F2
  (work-loop runs, PASS, retired in place when 1.2.0 dropped the feature,
  `tests/scenarios.md:239-281`), F3 (migration, PASS, `tests/scenarios.md:283-330`), plus six
  NEW scenario specs G1-G6 for progressive disclosure and the 1.3.0 migration that carry
  expected behavior only — zero checked assertions and no "Result:" lines, i.e. defined but with
  no recorded runs (`tests/scenarios.md:379-410`). The hook suite went from 12 to 16 assertions
  (tests 11-14 added, `tests/test-hooks.sh:96-119`).
- **PRD/roadmap accuracy** — feature 16 "(15 assertions)" (`PRD.md:49`) is stale: the current
  count is 16 (13 `check` sites + 3 inline blocks; the 15 figure matched the pre-test-14 state
  the F3 log cites, `tests/scenarios.md:328-330`), and its `:46-118` range now ends at 121.
  Feature 17 "11 headless full-plugin runs" (`PRD.md:50`) is still literally true but its trace
  `tests/scenarios.md:28-375` predates the 410-line file, and neither it nor any row covers the
  structure harness or the unrun G specs. Gap G1 "no automated CI" (`PRD.md:171`) remains
  accurate — the new harness is still manual-run.
- **Evidence** — `tests/test-structure.sh:1-93`; `tests/test-hooks.sh:46-119` (16 assertion
  sites); `tests/scenarios.md:379-410` (G specs, no results); `PRD.md:49-50,171`.

## Non-substantive

- The `.sunoku/status.json` 1.3.0 migration commit itself (a728727: summary fields +
  `sunokuVersion` re-stamp on the dogfood record) — the mechanical self-migration named on this
  dispatch's ignore list.
- `.claude-plugin/plugin.json:5` version string 1.0.0→1.3.0 — release mechanics; each release's
  substance is covered by groups 3-9.
- `CHANGELOG.md:1-100` creation — release notes restating groups 3-9; no independent claims.
- README word-wrap reflow of "The three commands" paragraph (`README.md:109-112`) and the
  Upgrading/Layout additions (`README.md:94-105`) — user-doc restatements of groups 4, 5, and 7.
- Single-hat agent description trims (researcher, design-lead, delivery-critic — `agents/researcher.md:3`,
  `agents/design-lead.md:3`, `agents/delivery-critic.md:3`) — wording compression, no semantic
  change, no hat-contract move for these three.
- `tests/test-structure.sh:77` init-router size-cap widening (03286e7's 9472-byte tripwire
  headroom) — test-threshold churn.
- `.sunoku/.gitignore:1-2` — scaffold hygiene (`.cache/`, `research/.fragments/`).
