# As-Built — Sunoku

> Sunoku documenting itself: this is the Claude Code plugin repository at
> `/Users/patrickvillanueva/Documents/Personal/sunoku/`, read as a consumer product. Every claim below
> is grounded in `file:line`. Existing prose docs (README.md, canon.md) are compared against the
> actual manifests/scripts/markdown contracts; where they diverge, the divergence is called out.

## Stack

There is no compiled runtime and no package manager manifest anywhere in the tracked tree — `git
ls-files` returns 31 files, none of them `package.json`, `pyproject.toml`, `go.mod`, or similar
(confirmed by the full file listing itself, which contains only `.md`, `.json`, `.sh` files and
`LICENSE`). The product's substrate is entirely the Claude Code plugin format:

- **Plugin manifest** — `.claude-plugin/plugin.json:1-9` declares name `sunoku`, version `1.0.0`,
  description, author, license `MIT`, keywords.
- **Marketplace manifest** — `.claude-plugin/marketplace.json:1-8` declares a one-plugin
  marketplace (`sunoku-marketplace`) sourcing the plugin from `./` (this repo's own root).
- **Skills** — three Markdown files, each a YAML-frontmatter `SKILL.md` (`name` + `description`
  fields Claude Code uses for routing): `skills/init/SKILL.md:1-4`, `skills/log/SKILL.md:1-4`,
  `skills/status/SKILL.md:1-4`. No skill has any code body beyond Markdown instructions.
- **Subagents** — eight Markdown files under `agents/`, each with YAML frontmatter fields `name`,
  `description`, `tools` (an explicit allowlist), and `model` (a tier: `sonnet` or `best`). Example:
  `agents/codebase-analyst.md:1-6` (`tools: Read, Grep, Glob, Bash, Write`, `model: best`).
  Tool/model assignment per agent: `codebase-analyst` best (`agents/codebase-analyst.md:5`),
  `delivery-critic` best (`agents/delivery-critic.md:5`), `delivery-planner` best
  (`agents/delivery-planner.md:5`), `design-lead` sonnet (`agents/design-lead.md:5`),
  `feasibility-assessor` best (`agents/feasibility-assessor.md:5`), `product-owner` sonnet
  (`agents/product-owner.md:5`), `red-team` best (`agents/red-team.md:5`), `researcher` sonnet
  (`agents/researcher.md:5`).
- **Hooks** — a JSON manifest (`hooks/hooks.json:1-27`) wiring two POSIX Bash scripts
  (`hooks/scripts/session-start.sh`, `hooks/scripts/stop-nudge.sh`), both `#!/usr/bin/env bash`
  (`hooks/scripts/session-start.sh:1`, `hooks/scripts/stop-nudge.sh:1`) using only `set -u`, `sed`,
  `grep`, `git`, `cksum`, `printf` — no other language runtime.
- **Shared rulebook + templates** — `reference/canon.md` (173 lines) and eight Markdown stub
  templates under `reference/templates/` (`BRIEF.md`, `EVIDENCE.md`, `JOURNAL.md`, `PRD.md`,
  `QUESTIONS.md`, `ROADMAP.md`, `TASKS.md`, `status.json.example`, `validation-report.md`,
  `sunoku.gitignore`).
- **Test harness** — `tests/test-hooks.sh` is a Bash regression script (uses `mktemp`, `git`, and
  shells out to `python3 -m json.tool` at `tests/test-hooks.sh:94` for JSON-validity checking — the
  one place a non-Bash interpreter is invoked). `tests/scenarios.md` is a prose regression log, not
  executable code.
- **License** — MIT, `LICENSE:1-22`.

## Architecture

The system is a **hub-and-spoke orchestration** built entirely out of prompt-engineered Markdown
contracts, not executable application code. `reference/canon.md:69-71` states the rule directly:
"The orchestrator is the sole integrator. All work fans out from it and reports back to it — agents
never invoke or message each other." This is enforced structurally, not by any runtime guard: no
agent file grants any agent the ability to invoke another skill or agent — each agent's `tools:`
frontmatter line is the only capability boundary (e.g. `agents/product-owner.md:5` grants only
`Read, Write`; `agents/codebase-analyst.md:4` is the sole agent granted `Bash`).

Three orchestrating skills sit at the top of the hub: `skills/init/SKILL.md`, `skills/log/SKILL.md`,
`skills/status/SKILL.md`. Each begins its `## Flow` by mandating "Read canon first" before any other
step (`skills/init/SKILL.md:15`, `skills/log/SKILL.md:14`, `skills/status/SKILL.md:13`), making
`reference/canon.md` the single shared rulebook all three skills defer to rather than each
restating its own copy of the rules.

Eight single-purpose subagents are dispatched by the orchestrating skills, never by each other:
`codebase-analyst`, `delivery-critic`, `delivery-planner`, `design-lead`, `feasibility-assessor`,
`product-owner`, `red-team`, `researcher` (one file each under `agents/`). Several carry more than
one "hat" selected explicitly by the dispatch prompt rather than by separate files — e.g.
`codebase-analyst` has RECONSTRUCT and RECONCILE hats in the same file
(`agents/codebase-analyst.md:14-16`), `feasibility-assessor` has VALIDATE and DEFINE hats
(`agents/feasibility-assessor.md:13-18`), `delivery-planner` has full-plan / gap-plan / RESHAPE hats
(`agents/delivery-planner.md:14-18`), `product-owner` has DEFINE and RESHAPE hats
(`agents/product-owner.md:19`), `red-team` has VALIDATE and DEFINE hats (`agents/red-team.md:20`).

**Parallel-write isolation** ("fragments") is architected explicitly in canon:
`reference/canon.md:84-96` — parallel writers each write to their own
`research/.fragments/<phase>-<agent>.md`, never to a shared file; the orchestrator concatenates
fragments onto `research/EVIDENCE.md` after the phase barrier and deletes them, asserting fragment
count equals dispatched-writer count. All non-orchestrator agent files reference this pattern in
their own "Rules" sections (e.g. `agents/researcher.md:64-65`, `agents/feasibility-assessor.md:59`).

**State machine** — a single JSON file, `status.json`, is the sole lifecycle source of truth
(`reference/canon.md:136-138`), written only by the orchestrating skill, never by an agent
(`reference/canon.md:138-139`; reiterated per-skill, e.g. `skills/init/SKILL.md:183-186`). Its
`lifecycle` field drives a strict state machine documented at `reference/canon.md:163-169`:
`validating -> defining -> planning -> live`, with `defining -> live` as a direct edge for
existing/as-built products (skipping `planning`), and `(any phase) -> shelved` on kill.

**Ambient layer** — two Claude Code hooks read (never write meaningfully beyond a cache file)
`status.json` to inject context or nudge the user, gated by exact byte-level `grep` matches on
`"tracking": true` and `"lifecycle": "live"` (`hooks/scripts/session-start.sh:17-18`,
`hooks/scripts/stop-nudge.sh:15-16`), which is why canon mandates a fixed canonical JSON
serialization for `status.json` (`reference/canon.md:139-141`).

**Prime directive / boundary** — `reference/canon.md:9-11`: Sunoku "never writes application code
and never touches a consumer repo's source tree — only `.sunoku/` at the consumer repo root." This
is the architectural contract every agent's Rules section reiterates individually (e.g.
`agents/codebase-analyst.md:82-84`, `agents/delivery-planner.md:76-77`).

## Modules

- **`.claude-plugin/`** — plugin identity and marketplace registration.
  Key files: `plugin.json` (name/version/description/author/license/keywords,
  `.claude-plugin/plugin.json:1-9`), `marketplace.json` (one-plugin marketplace pointing at `./`,
  `.claude-plugin/marketplace.json:1-8`).

- **`skills/init/`** — the sole orchestrator for creating or resuming the living record; routes on
  `status.json.lifecycle`, scaffolds `.sunoku/`, and runs either the greenfield (VALIDATE→DEFINE→
  PLAN→TRACK) or existing-code (RECONSTRUCT→accuracy-gate→TRACK→optional gap-PLAN) flow.
  Key file: `skills/init/SKILL.md` (190 lines; routing at `skills/init/SKILL.md:23-48`, scaffold at
  `skills/init/SKILL.md:50-65`, greenfield flow `skills/init/SKILL.md:67-136`, existing-code flow
  `skills/init/SKILL.md:138-173`).

- **`skills/log/`** — the triage engine (SILENT/TRACK/RESHAPE) for a single change or decision;
  guards on a live record, appends journal entries, and runs the one-checkpoint RESHAPE procedure.
  Key file: `skills/log/SKILL.md` (108 lines; guard `skills/log/SKILL.md:18-25`, triage
  `skills/log/SKILL.md:35-53`, journal format `skills/log/SKILL.md:54-66`, RESHAPE procedure
  `skills/log/SKILL.md:68-103`).

- **`skills/status/`** — the read-mostly reporting surface: state summary, journal tail, open
  questions, drift check, history answers, and a reconcile action gated behind explicit
  acceptance. Key file: `skills/status/SKILL.md` (83 lines; report contract
  `skills/status/SKILL.md:26-46`, history-answer rule `skills/status/SKILL.md:48-57`, reconcile
  `skills/status/SKILL.md:59-77`, mute/unmute `skills/status/SKILL.md:79-83`).

- **`agents/`** — eight single-purpose Markdown subagent contracts, each with a fixed output
  section order and a "Rules" footer repeating the write-boundary discipline. `codebase-analyst.md`
  (RECONSTRUCT/RECONCILE, sole Bash-bearing agent), `delivery-critic.md` (plan critique, findings
  only), `delivery-planner.md` (ROADMAP.md/TASKS.md, three hats), `design-lead.md` (PRD UX section,
  words only, no mockups per `agents/design-lead.md:47-49`), `feasibility-assessor.md`
  (VALIDATE/DEFINE hats, only agent with `WebSearch`/`WebFetch` besides researcher and red-team),
  `product-owner.md` (PRD Problem/Personas/Features/Out-of-scope/Success/Commercial),
  `red-team.md` (adversarial critique, mandatory strongest-objection rule at
  `agents/red-team.md:12-13`), `researcher.md` (VALIDATE demand/competitor research).

- **`hooks/`** — the ambient layer. Key files: `hooks/hooks.json` (SessionStart + Stop event
  wiring, `hooks/hooks.json:2-27`), `hooks/scripts/session-start.sh` (41 lines — injects the
  standing-triage-rule context and a drift count), `hooks/scripts/stop-nudge.sh` (35 lines —
  one-shot per-session nudge to run `sunoku:log` when code changed but the journal did not).

- **`reference/`** — the shared rulebook and the stub templates every scaffold step copies from.
  Key files: `reference/canon.md` (Prime directive, Triage, Checkpoints, Assumptions, Dispatch,
  Fragments, Garbage output, Conflict, Sentinels & resume, StatusFile — 173 lines total), and ten
  files under `reference/templates/` (`BRIEF.md`, `EVIDENCE.md`, `JOURNAL.md`, `PRD.md`,
  `QUESTIONS.md`, `ROADMAP.md`, `TASKS.md`, `status.json.example`, `sunoku.gitignore`,
  `validation-report.md`).

- **`tests/`** — the regression surface. `tests/test-hooks.sh` (96 lines, 10 assertions against the
  two hook scripts in isolated `mktemp` git repos). `tests/scenarios.md` (209 lines, a prose log of
  8 headless full-plugin runs — A, B, C, D1–D5 — against throwaway repos, with pass/fail results
  recorded by the repo's own maintainers, not by this audit).

## Data model

The "data model" is the on-disk `.sunoku/` living-record schema — Markdown files plus one JSON
state file — defined by `reference/canon.md` and the stub templates under `reference/templates/`.

- **`status.json`** — the only structured (JSON) artifact, and the single lifecycle source of
  truth (`reference/canon.md:136-138`). Canonical shape and field order, verbatim
  (`reference/canon.md:143-153`, mirrored in `reference/templates/status.json.example:1-11`):
  `version`, `product`, `origin`, `lifecycle`, `tracking`, `last_reconciled_sha`, `created`,
  `updated`. Field semantics (`reference/canon.md:156-161`): `origin` ∈ {`greenfield`,
  `existing`}; `lifecycle` ∈ {`validating`, `defining`, `planning`, `live`, `shelved`}; `tracking`
  is a boolean gating the TRACK/RESHAPE triage; `last_reconciled_sha` is the consumer-repo commit
  the journal was last reconciled against. Serialization is mandatory-canonical — one key per
  line, two-space indent, exact key order — because the hooks `grep` the file byte-for-byte
  (`reference/canon.md:139-141`; enforced literally at `hooks/scripts/session-start.sh:17-18` and
  `hooks/scripts/stop-nudge.sh:15-16`, which `grep -q '"tracking": true'` and
  `grep -q '"lifecycle": "live"'`). Lifecycle transitions are a fixed directed graph
  (`reference/canon.md:165-169`).

- **`BRIEF.md`** — fixed sections `Segment`, `Wedge`, `Monetization stance`, `Constraints`,
  `Commitment` (`reference/templates/BRIEF.md:1-18`).

- **`PRD.md`** — fixed sections `Problem`, `Personas`, `Features` (table with a `Trace` column
  pointing at a `V-n` / `file:line` / `Q-n` reference), `Architecture` (with exactly one
  `### Rejected alternative` subsection), `UX`, `Out of scope`, `Success metrics`, `Commercial`
  (optional), and an append-only `Change Log` table (`| Date | Change | Why | Journal ref |`)
  (`reference/templates/PRD.md:1-29`).

- **`JOURNAL.md`** — append-only, newest entry at the bottom, machine-scanned header pattern
  `## YYYY-MM-DD — <type>` where `<type>` ∈ {`track`, `reshape`, `decision`}
  (`reference/templates/JOURNAL.md:4-5`, `reference/canon.md:125-127`). Entry body shape
  (`skills/log/SKILL.md:57-62`): `**What:**`, `**Why:**`, `**Refs:**`.

- **`QUESTIONS.md`** — flagged-assumption / open-question ledger. Entry pattern
  `## Q-<n> — <title>  (stakes: high|normal, status: open|answered)` with `**Assumption taken:**`,
  `**Reasoning:**`, `**Flip if wrong:**` fields (`reference/templates/QUESTIONS.md:4-7`). The
  canon's full assumption format additionally requires `**Chosen default**` and adds `**Stakes**`
  as its own line (`reference/canon.md:53-59`).

- **`research/EVIDENCE.md`** — append-only ledger, one row per claim, columns
  `| ID | Claim | Source | Kind | Strength | Phase |`, `Kind` ∈ {`URL`, `file:line`}
  (`reference/templates/EVIDENCE.md:4-7`).

- **`research/.fragments/<phase>-<agent>.md`** — transient per-writer evidence files, deleted by
  the orchestrator after being concatenated onto `EVIDENCE.md` (`reference/canon.md:86-96`); the
  gitignore template excludes this directory and `.cache/` from version control
  (`reference/templates/sunoku.gitignore:1-2`).

- **`ROADMAP.md`** — milestone sections, `M1` always literally titled "Walking skeleton"
  (`reference/templates/ROADMAP.md:6`), no calendar estimates.

- **`TASKS.md`** — one table per milestone, columns `| ID | Task | Size | Trace | Depends on |`
  (`reference/templates/TASKS.md:7`), `Size` ∈ {S, M, L}, `[SPIKE]` tag for hidden unknowns.

- **`validation/<YYYY-MM-DD>-validation.md`** — immutable once finalized (a later re-examination
  produces a new dated file instead of an edit) (`reference/templates/validation-report.md:1-3`),
  sections `Verdict`, `Demand`, `Room`, `Buildability`, `Sustainability`, an `Evidence table`, an
  `Adversarial verification` subsection, and `Assumptions carried`
  (`reference/templates/validation-report.md:6-26`).

- **Sentinel convention** — every stub template's literal first line is `<!-- sunoku:stub -->`
  (verified present as line 1 of `BRIEF.md`, `EVIDENCE.md`, `JOURNAL.md`, `PRD.md`, `QUESTIONS.md`,
  `ROADMAP.md`, `TASKS.md`, `validation-report.md` under `reference/templates/`); an artifact
  counts as done once it exists, is non-empty, and the sentinel has been removed by the filling
  agent (`reference/canon.md:119-124`).

## Entry points

The system is invoked exclusively through Claude Code's skill-routing mechanism plus two
lifecycle-gated hooks — there is no CLI binary, HTTP server, or script the user runs directly.

1. **`sunoku:init`** — `skills/init/SKILL.md:1-4` frontmatter description lists its trigger
   phrases ("is this idea worth building?", "document this repo/codebase", "set up sunoku", etc.).
   README frames it as "the only command a user must learn" (`README.md:96-100`); it creates the
   record if none exists, resumes a mid-phase one, or refuses and hands off to `sunoku:status` if
   `lifecycle` is already `live` (`skills/init/SKILL.md:26-28`).

2. **`sunoku:log`** — `skills/log/SKILL.md:1-4`; guarded on a live record
   (`skills/log/SKILL.md:18-25`), runs the SILENT/TRACK/RESHAPE triage.

3. **`sunoku:status`** — `skills/status/SKILL.md:1-4`; the read-mostly surface plus reconcile and
   mute/unmute actions.

4. **`SessionStart` hook** — wired in `hooks/hooks.json:3-14` with `matcher:
   "startup|resume|clear|compact"`, invoking `bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/session-start.sh"`
   with a 10-second timeout. The script exits silently (0, no output) unless `status.json` exists
   with `tracking: true` and `lifecycle: live` on a valid git repo
   (`hooks/scripts/session-start.sh:16-19`); when active it emits a
   `hookSpecificOutput.additionalContext` JSON payload injecting the standing triage rule and any
   drift count (`hooks/scripts/session-start.sh:33-40`).

5. **`Stop` hook** — wired in `hooks/hooks.json:15-25`, invoking
   `bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/stop-nudge.sh"`. Fires at most once per session
   (guarded by a `.sunoku/.cache/nudged-<session>` marker file,
   `hooks/scripts/stop-nudge.sh:20-21,33`), only when code changed since the session-start snapshot
   and the journal was not updated after that snapshot
   (`hooks/scripts/stop-nudge.sh:24-31`).

6. **Local dev entry** — `claude --plugin-dir /path/to/sunoku` bypasses the marketplace entirely
   (`README.md:83-87`); marketplace install is `/plugin marketplace add ...` +
   `/plugin install sunoku` (`README.md:75-78`).

**Doc-vs-code note:** `hooks/hooks.json` and both scripts use `bash "${CLAUDE_PLUGIN_ROOT}/..."` as
the invocation form for both hooks (`hooks/hooks.json:9,20`), which matches the README's own
Windows caveat that these hooks need Git Bash on PATH or they silently no-op (`README.md:89-92`) —
the doc and code agree here.

## What demonstrably works

Distinguishing what is independently, mechanically tested from what is merely present and
internally consistent:

- **Hook behavior is covered by an executable regression script**, `tests/test-hooks.sh` (96
  lines), which spins up isolated `mktemp` git repos and asserts on `session-start.sh` and
  `stop-nudge.sh` stdout/exit codes for 10 distinct cases: no-record no-op
  (`tests/test-hooks.sh:47-48`), tracking-muted no-op (`tests/test-hooks.sh:51-53`), live+tracking
  context injection plus snapshot-file write (`tests/test-hooks.sh:56-59`), drift-count surfacing
  (`tests/test-hooks.sh:62-64`), subagent-invocation no-op via the `agent_id` guard
  (`tests/test-hooks.sh:67-68`), Stop-with-no-snapshot no-op (`tests/test-hooks.sh:71-72`),
  Stop nudges once then a marker suppresses the second nudge (`tests/test-hooks.sh:75-79`),
  Stop stays silent once the journal file is newer than the snapshot (`tests/test-hooks.sh:82-85`),
  malformed `status.json` no-op (`tests/test-hooks.sh:88-89`), and hook JSON output validity via
  `python3 -m json.tool` (`tests/test-hooks.sh:91-94`). This audit read the script but, per its
  RECONSTRUCT hard rules (no script execution), did not re-run it — the pass/fail state of this
  suite as of the repo's current HEAD is not independently re-verified here, only its presence and
  the specific behaviors it is designed to check.

- **The full orchestration (skills + agents) is exercised, not unit-tested**, via headless
  full-plugin runs logged in `tests/scenarios.md` (209 lines), because the "code" here is
  prompt-driven Markdown with no direct API to unit-test. The file itself states the verification
  method: "behaviour is verified by exercising the flow, never by reading the source"
  (`tests/scenarios.md:5`). Per that document's own self-reported results (not re-executed by this
  audit): greenfield GO path (Scenario A) reported PASS 14/14
  (`tests/scenarios.md:28-49`); greenfield NO-GO→shelved with a revive-refusal re-run (Scenario B)
  reported PASS on both runs (`tests/scenarios.md:52-73`); greenfield skip-validate/committed path
  (Scenario C) reported PASS 6/6 (`tests/scenarios.md:77-91`); and five existing-code lifecycle
  scenarios chained on one fixture repo — D1 onboarding with an accuracy-gate correction
  (`tests/scenarios.md:105-124`), D2 a TRACK-lane triage (`tests/scenarios.md:126-141`), D3 a
  RESHAPE pivot with one checkpoint (`tests/scenarios.md:143-159`), D4 out-of-band drift + reconcile
  (`tests/scenarios.md:161-179`, noting a first-attempt failure on sonnet that required an opus
  retry to pass — `tests/scenarios.md:174-179`), and D5 a history answer plus live-record
  re-init refusal (`tests/scenarios.md:181-197`) — each reported PASS.

- **Wired end-to-end, confirmed by direct reading of the contracts** (present + internally
  consistent, independent of the exercised-run claims above): `hooks/hooks.json` correctly
  references both script paths that exist on disk (`hooks/hooks.json:9` →
  `hooks/scripts/session-start.sh`; `hooks/hooks.json:20` → `hooks/scripts/stop-nudge.sh`, both
  confirmed present in `git ls-files`); `skills/init/SKILL.md` names all eight agent files that
  exist under `agents/` (cross-checked: `sunoku:codebase-analyst`
  `skills/init/SKILL.md:146`, `sunoku:researcher`/`sunoku:feasibility-assessor`
  `skills/init/SKILL.md:84`, `sunoku:red-team` `skills/init/SKILL.md:93`, `sunoku:product-owner`/
  `sunoku:design-lead` `skills/init/SKILL.md:110-111`, `sunoku:delivery-planner`/
  `sunoku:delivery-critic` `skills/init/SKILL.md:125-127` — all eight agent basenames match files
  under `agents/` per the `git ls-files` listing); the marketplace manifest's plugin source path
  `./` (`.claude-plugin/marketplace.json:6`) correctly resolves to this repo's own root, which
  does contain `.claude-plugin/plugin.json`.

- **Not demonstrated by this audit**: no CI workflow exists in the tracked tree (`git ls-files`
  contains no `.github/workflows/` or other CI config path), so neither `tests/test-hooks.sh` nor
  the scenario runs in `tests/scenarios.md` are shown to run automatically on any commit or PR —
  their execution is manual, per the "How to run" instructions at `tests/scenarios.md:7-16`.

## Gaps & TODOs

- **No automated CI.** `git ls-files` contains no `.github/workflows/` or any other CI
  configuration file — `tests/test-hooks.sh` and the scenario runs documented in
  `tests/scenarios.md` are both manually invoked (`tests/scenarios.md:7-16`); nothing in the repo
  enforces that they are re-run before a change lands.

- **Windows fragility, self-acknowledged.** `README.md:89-92` states plainly that both hooks are
  Bash scripts invoked via `bash "${CLAUDE_PLUGIN_ROOT}/...}"` and require Git Bash on PATH on
  Windows; without it "the hooks silently no-op and you lose the ambient nudges." This is a known,
  documented rough edge, not a hidden one — but it is real: `hooks/hooks.json:9,20` shows both
  hook commands are hard-coded to the `bash` invocation form with no Windows-native (e.g.
  PowerShell) fallback path defined anywhere in the manifest.

- **No literal `TODO`/`FIXME` markers exist anywhere in the actual plugin source.** A repo-wide
  grep for `TODO|FIXME|XXX` across the tracked tree returns matches only inside prose that
  *describes* the concept (e.g. `agents/codebase-analyst.md:39-40` instructing the agent to look
  for such markers in a *consumer* repo, and `skills/init/SKILL.md:149,156` referencing the "Gaps
  & TODOs" section name) — none are markers left in Sunoku's own code. This is itself worth
  recording as an as-built fact for a future RECONCILE pass: the absence is confirmed, not assumed.

- **D4's first attempt failed on model-following, not on plugin logic**, per the repo's own
  regression record: `tests/scenarios.md:174-179` reports that a sonnet-driven run of the
  reconcile flow correctly detected and reported drift but then stopped at the reconcile offer
  instead of acting on a prompt that had pre-supplied acceptance; a retry with `--model opus`
  completed the flow. The scenario log frames this as "weak model-following, not a plugin
  defect" (`tests/scenarios.md:176-177`) — that is the maintainers' own characterization, not an
  independently re-verified conclusion by this audit, and it stands as a documented reliability
  edge: the reconcile flow's completion is not guaranteed under all subagent models, only under
  the ones actually exercised (sonnet subagents, opus retry — `tests/scenarios.md:22`).

- **`tests/test-hooks.sh` depends on `python3` being present** at `tests/test-hooks.sh:94` (for
  `python3 -m json.tool`) purely to validate that hook stdout is well-formed JSON — this is the one
  place the test harness reaches outside pure Bash/git/coreutils, an implicit environment
  dependency not stated anywhere in `README.md` or `tests/scenarios.md`.

- **`reference/templates/status.json.example` is a template, not a schema/validator.** Nothing in
  the tracked tree programmatically validates that a real `.sunoku/status.json` matches the
  canonical serialization canon mandates (`reference/canon.md:139-141`) beyond the two hook
  scripts' narrow `grep` checks on two specific substrings
  (`hooks/scripts/session-start.sh:17-18`, `hooks/scripts/stop-nudge.sh:15-16`) — a malformed but
  differently-shaped `status.json` (e.g. correct keys, wrong indentation, but still containing
  those two exact substrings) would pass the hooks' guard undetected; only `test-hooks.sh` case 9
  (`tests/test-hooks.sh:88-89`) exercises one specific malformed-JSON case (`{broken`), not
  malformed-but-parseable variants.

- **Gap list is a candidate input, not exhaustive by design.** Per
  `agents/codebase-analyst.md:39-40` and `skills/init/SKILL.md:156`, this section is explicitly
  scoped as "candidate input for the gap-list the orchestrator builds later" — the orchestrator
  (a future `sunoku:init` accuracy-gate pass) still owns synthesizing the final gap list from this
  document; this file does not itself constitute that gap list.
