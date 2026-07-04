# PRD — Sunoku

> Living document. Current state only — history lives in JOURNAL.md; changes land in the Change Log below.
> As-built snapshot: every claim is grounded in `file:line` from the repo at onboarding.

## Problem

Planning artifacts rot. A team writes a PRD or spec, ships against it, and within months the
document no longer describes the product — the real answer to "what is this, what changed, and why"
lives in scattered Slack threads, commit messages, and someone's memory. Coming back to a project
after a gap means re-deriving intent from code. Sunoku's premise (`README.md:8-22`) is that the
record, not the document, is the deliverable: a `.sunoku/` living record that stays true because a
standing triage reconciles it forward on every real change and stays silent on noise, so six months
later the journal, PRD, and evidence ledger answer those three questions with citations instead of
recollection.

## Personas

- **Solo builder / small-team owner on Claude Code** (primary; segment per `BRIEF.md`, assumption
  `Q-2`). Owns a repo, wants a trustworthy record without running a heavyweight PM process. Enters
  through one command and lets tracking arm itself.
- **The returning maintainer** — the same person (or a teammate) six months later asking "what is
  this product now, what changed since March, why did we drop X?" The record is built to answer them
  from JOURNAL.md, the PRD Change Log, and EVIDENCE.md (`README.md:19-22`).
- **The pre-commitment decider** — someone with a greenfield idea deciding whether to build at all,
  served by the optional VALIDATE phase and its immutable go/no-go report
  (`skills/init/references/validate.md`).

## Features
<!-- Trace = as-built ref (file:line / evidence ID) for a built capability -->

| # | Feature | Priority | Trace |
|---|---------|----------|-------|
| 1 | Single entry command `sunoku:init` — creates, resumes, or refuses-and-hands-off a record based on `status.json.lifecycle` | P0 | skills/init/SKILL.md:23-56 (AB-20, AB-41) |
| 2 | Existing-code onboarding: RECONSTRUCT → accuracy gate → memory-first TRACK arm → optional gap roadmap | P0 | skills/init/references/existing.md:1-38 |
| 3 | Greenfield onboarding: scoping → optional VALIDATE → DEFINE → optional PLAN → TRACK | P0 | skills/init/SKILL.md:74-136; skills/init/references/onboarding.md |
| 4 | VALIDATE phase producing an immutable dated go/no-go/go-if report with an evidence table and adversarial verification | P1 | skills/init/references/validate.md; reference/templates/validation-report.md:1-27 (AB-37) |
| 5 | DEFINE phase assembling `PRD.md` from parallel product/design/architecture fragments, red-teamed | P0 | skills/init/references/define.md (AB-28) |
| 6 | Optional PLAN phase → `ROADMAP.md` (M1 = walking skeleton) + `TASKS.md`, critic-reviewed, no calendar estimates | P1 | skills/init/references/plan.md; reference/templates/ROADMAP.md:4-6 (AB-35) |
| 7 | `sunoku:log` triage engine — SILENT / TRACK / RESHAPE, ceremony scaled to the lane | P0 | skills/log/SKILL.md:38-51 (AB-21); reference/canon.md:35-53 |
| 8 | `sunoku:status` surface — state summary, journal tail, open questions, drift check, reconcile, mute/unmute | P0 | skills/status/SKILL.md:27-84 (AB-22) |
| 9 | Append-only living record: JOURNAL.md (entries past 30KB roll into `.sunoku/journal/<year>.md`), EVIDENCE.md, QUESTIONS.md, PRD Change Log | P0 | skills/log/SKILL.md:70-74; reference/templates/JOURNAL.md; EVIDENCE.md; QUESTIONS.md (AB-29, AB-33) |
| 10 | `status.json` lifecycle state machine, single-writer, canonical serialization (12 keys incl. `one_liner`/`open_questions`/`high_stakes`/`last_entry` summary index) | P0 | reference/canon/statusfile.md:1-56 (AB-16, AB-17, AB-25) |
| 11 | Ambient SessionStart hook: injects standing triage rule + drift count when tracking is live | P1 | hooks/scripts/session-start.sh:33-40 (AB-45) |
| 12 | Ambient Stop hook: one-shot per-session nudge to `sunoku:log` when code changed but journal didn't | P1 | hooks/scripts/stop-nudge.sh:24-33 (AB-47, AB-48) |
| 13 | Mute switch — `tracking:false` silences hooks while preserving the record | P1 | skills/status/SKILL.md:88-91; hooks/scripts/session-start.sh:17 (AB-18) |
| 14 | Drift + reconcile — count commits since `last_reconciled_sha`, offer to diff/group/re-triage | P1 | skills/status/SKILL.md:39-86; hooks/scripts/session-start.sh:27-37 |
| 15 | Eight single-purpose subagents dispatched hub-and-spoke, each a tool-scoped Markdown contract; multi-hat output contracts split into `reference/contracts/` | P0 | agents/*.md (AB-5, AB-6, AB-14); reference/canon/dispatch.md:1-19; reference/contracts/ (11 files) |
| 16 | Hook regression suite (16 assertions) exercising both scripts in isolated repos | P2 | tests/test-hooks.sh:46-121 (AB-52) |
| 17 | Scenario regression log — 11 headless full-plugin runs (A, B, C, D1–D5, E, F, F3) | P2 | tests/scenarios.md:28-375 (AB-54–AB-58) |
| 19 | Self-migrating record schema — MIGRATIONS.md registry applied on first touch, `sunokuVersion` stamp, version-skew session nudge | P1 | reference/MIGRATIONS.md; reference/canon/record-migrations.md; hooks/scripts/session-start.sh:40-54 |

## Architecture

Sunoku is **not application code** — it is a hub-and-spoke orchestration built entirely from
prompt-engineered Markdown contracts plus two Bash hooks, running on the Claude Code plugin
substrate. There is no compiled runtime and no package manifest (`git ls-files` = 70 files, all
`.md`/`.json`/`.sh`/LICENSE — AB-1).

- **Substrate**: Claude Code plugin. Three skills (`skills/*/SKILL.md`) are the orchestrators;
  eight subagents (`agents/*.md`) are dispatched workers, each with a `tools:` allowlist and a
  `model` tier (`agents/codebase-analyst.md:1-6`, AB-5). `codebase-analyst` is the only agent
  granted Bash (`agents/codebase-analyst.md:4`, AB-6).
- **Hub-and-spoke, sole integrator**: the orchestrating skill fans work out to agents and is the
  only integrator; agents never invoke or message each other (`reference/canon/dispatch.md:3-4`, AB-12).
  Parallel writers never share a file — each writes a `research/.fragments/<phase>-<agent>.md`
  fragment merged onto EVIDENCE.md at the phase barrier (`reference/canon/fragments.md:4-10`, AB-15).
- **Single source of truth**: `status.json` at the `.sunoku/` root, written only by the
  orchestrator, in a mandated canonical serialization (one key per line, two-space indent, fixed key
  order) because the hooks `grep` it byte-for-byte (`reference/canon/statusfile.md:4-24`, AB-16, AB-18,
  AB-25). Its `lifecycle` drives the state machine `validating → defining → planning → live`, with
  `defining → live` for existing/as-built products and `(any) → shelved` on kill
  (`reference/canon/statusfile.md:47-51`, AB-17).
- **Shared rulebook (progressive disclosure)**: `reference/canon.md` is a 70-line always-read
  **core** — Prime directive, Coexistence, Triage, and a Disclosure map — read by each skill
  *after* its record guard passes (`skills/log/SKILL.md:14-27`, `skills/status/SKILL.md:13-25`,
  `skills/init/SKILL.md:23-56`, AB-13). The Disclosure map (`reference/canon.md:55-70`) names, per
  lane, exactly which of the ten `reference/canon/` section files to load and nothing beyond it —
  Checkpoints, Assumptions, Dispatch, Fragments, Garbage output, Conflict, Sentinels & resume,
  StatusFile, Record migrations, and Execution contract each live in their own file, loaded on
  demand.
- **Ambient layer**: two hooks (`hooks/hooks.json`, AB-8) gated on `tracking:true` + `lifecycle:live`
  — SessionStart injects the triage rule and drift count; Stop nudges once per session when code
  changed but the journal didn't. Both are `bash "${CLAUDE_PLUGIN_ROOT}/..."` invocations (AB-50).
- **Prime directive**: Sunoku never writes application code and writes only `.sunoku/` at the
  consumer repo root. Executing the backlog is an open contract worked by any executor the user
  chooses, with reconcile flipping diff-proven tasks to `done`
  (`reference/canon.md` Prime directive + Execution contract).

### Rejected alternative

**A peer-to-peer agent mesh** — letting subagents invoke and hand off to one another directly (e.g.
researcher calling red-team, planner calling critic) instead of every result routing back through
the orchestrating skill. It would cut orchestrator round-trips and read as more "autonomous." It was
rejected — and the rejection is codified in canon (`reference/canon/dispatch.md:3-6`) — because a mesh has
no single integrator: with multiple writers there is no one owner of `status.json` (which must stay
byte-canonical for the hooks, AB-18) and no clean phase barrier for the fragments-merge invariant
(`reference/canon/fragments.md:4-10`). The single-integrator constraint is what makes the record's
consistency and resumability provable; the mesh trades that away for parallelism the workload does
not need.

## UX

Words-only; there is no GUI. The entire surface is three Claude Code skill invocations plus two
ambient hooks.

- **Onboarding an existing repo (the flow just run)**: user invokes `sunoku:init`. Sunoku detects
  source, scaffolds `.sunoku/`, reads the repo, and reconstructs an as-built PRD with every claim
  cited. It presents one line — "here is what I understood your product to be — correct me" — the
  accuracy gate (`skills/init/references/existing.md:17`). On approval it arms tracking *immediately*,
  memory-first, before asking anything else (`skills/init/references/existing.md:21-27`), then offers exactly
  one optional extra: a gap roadmap.
- **Onboarding a greenfield idea**: scoping (≤5 batched questions), then optional VALIDATE resolving
  to one go/no-go checkpoint, then DEFINE → PRD approve, then an optional PLAN → roadmap approve,
  then arm. A NO-GO is a successful, shelved outcome with an immutable report, not a failure
  (`skills/init/SKILL.md:90-92`).
- **Steady state**: the user mostly does nothing. The Stop hook nudges when a change went
  undocumented; `sunoku:log` runs the triage and does exactly as much as the lane demands (silence
  for a bugfix, one journal line for a tracked change, a scoped re-dispatch + one checkpoint for a
  reshape). `sunoku:status` answers "what changed since May?" from the journal and Change Log.
- **Navigation / IA**: one command to learn (`sunoku:init`); the other two are surfaced once
  tracking is armed (`README.md:100-106`). State lives in human-readable Markdown under `.sunoku/`,
  browsable directly.
- **Accessibility**: text-only, terminal-native, no color- or pointer-dependent affordances; the
  record is plain Markdown/JSON readable outside Claude Code. Windows caveat: hooks need Git Bash on
  PATH or they silently no-op (`README.md:89-92`).

## Out of scope

- Writing or modifying consumer application code — Sunoku plans and documents only. Executing the
  backlog belongs to whatever tool the user chooses; `TASKS.md` is an open contract and reconcile
  records what landed (`reference/canon.md` Prime directive, Execution contract).
- Any write outside `.sunoku/` at the consumer repo root; no external exports or third-party sync
  (`reference/canon.md:9-14`).
- Calendar/time estimates in roadmaps — sizes are S/M/L only (`reference/templates/ROADMAP.md:4`).
- Mockups, wireframes, or generated images — design output is words only
  (`agents/design-lead.md:47-49`, AB-23).
- Multi-repo / org-level governance, roles, or a hosted control plane — the model is one
  `.sunoku/` per repo.
- Git archaeology of pre-Sunoku history — the journal starts empty at onboarding
  (`skills/init/references/existing.md:9-10`).

## Success metrics

- **Silence discipline**: SILENT-lane changes (bugfix/refactor/style/config/copy) produce zero
  journal entries — the record does not grow with noise (`reference/canon.md:43-44`).
- **Reshape capture**: every change to the reshape set {core bet, scope, architecture, segment,
  pricing} yields exactly one journal entry, one checkpoint, and a reconciled PRD + Change Log row
  (`reference/canon.md:47-49`).
- **Six-month test**: the record answers "what is this now / what changed since <date> / why did we
  drop X" from JOURNAL.md + Change Log + EVIDENCE.md without external memory (`README.md:19-22`).
- **Resumability**: an interrupted run resumes at the first not-done artifact without clobbering
  finished ones (`reference/canon/sentinels-resume.md:12-18`).
- **Onboarding fidelity**: the accuracy gate catches misreads before anything becomes canon
  (`skills/init/references/existing.md:17`).

## Commercial

Not applicable at present. Sunoku is MIT-licensed (`LICENSE:1`, `.claude-plugin/plugin.json:7`) and
distributed free as a Claude Code plugin via its own marketplace
(`.claude-plugin/marketplace.json:1-8`). No pricing, packaging, or paid-tier artifacts exist in the
repo. The non-commercial stance is carried as flagged assumption `Q-1`.

## Gap List
<!-- Must-have features not yet built (existing-code flow). Seeded from as-built Gaps & TODOs. -->

The core product — VALIDATE / DEFINE / PLAN / TRACK, the four skills, eight agents, two hooks, the
living-record schema — is **fully built and internally wired** (all 19 features above trace to
shipped source). No core product capability is missing. The open items are **hardening / ops gaps,
not absent must-have features**, and are classified as such:

| # | Gap | Kind | Must-have? | Evidence |
|---|-----|------|-----------|----------|
| G1 | No automated CI — `test-hooks.sh` and the scenario runs are manual only; nothing enforces re-run before a change lands | Ops / quality | No (nice-to-have) | as-built Gaps; AB-59; tests/scenarios.md:7-16 |
| G2 | Windows hook fragility — both hooks are `bash "${CLAUDE_PLUGIN_ROOT}/..."`; no Windows-native fallback, silent no-op without Git Bash | Reliability (documented) | No — degrades gracefully, README-disclosed | AB-49, AB-50; README.md:89-92 |
| G3 | No `status.json` schema validator — hooks guard on two substring greps only; a malformed-but-parseable file could pass undetected | Robustness | No (nice-to-have) | as-built Gaps; hooks/scripts/session-start.sh:17-18 |
| G4 | `test-hooks.sh` has an undocumented `python3` dependency (`json.tool`) | Test infra nit | No | AB-11; tests/test-hooks.sh:94 |
| G5 | Reconcile flow completion not guaranteed under all subagent models (D4 stalled on sonnet, passed on opus retry) | Reliability edge | No — model-following, not plugin logic | AB-58; tests/scenarios.md:174-179 |

**Assessment:** the gap list contains no must-have product features — every item is a quality,
robustness, or ops hardening task on an otherwise complete product. Per the existing-code flow, a
gap roadmap over these is optional and, given none are must-haves, not warranted.

## Change Log
| Date | Change | Why | Journal ref |
|---|---|---|---|
| 2026-07-03 | Added feature 18 (`sunoku:work` execution loop); prime directive scoped to planning agents; out-of-scope and UX surface updated | Complete the loop: plan → execute → track without leaving the record | 2026-07-03 — reshape |
| 2026-07-03 | Dropped feature 18 (`sunoku:work`) in 1.2.0; command surface back to three; prime directive restored to plans-and-documents-only; TASKS.md Status/Blocked schema kept as the open Execution contract with reconcile status catch-up; canon gained the Coexistence principle | Owning execution displaced other plugins' process discipline (design gates pre-satisfied, questions forbidden mid-run); record-keeping is the product, execution is commodity | 2026-07-03 — reshape (sunoku:work drop) |
| 2026-07-04 | Reconciled the PRD to as-built through `a728727` for the 1.3.0 progressive-disclosure release: rewrote the Architecture "Shared rulebook" bullet for the canon core + ten `reference/canon/` section files + Disclosure map, corrected `git ls-files` 40→70 and canon 238→70 lines, re-pointed moved `reference/canon/` and `skills/*/references/` traces across features/UX/out-of-scope/metrics, added journal 30KB rollover to feature 9, refreshed features 10/15/16/19 | The 1.3.0 work was TRACK-lane and journaled, but TRACK does not edit the PRD, so the snapshot had drifted 46 commits — reconcile-forward, not a reshape (architecture substance unchanged, only canon packaging moved) | 2026-07-04 — track (reconcile) |
