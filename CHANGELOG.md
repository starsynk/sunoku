# Changelog

## 3.0.1 — 2026-07-10

- **Task descriptions.** Task rows now require a `description` — self-contained enough
  for an executor to act on (what, done-when, constraints, PRD ref). Enforced on
  `tasks.mjs --add` for `type:"task"` only; existing records stay valid. `description`
  is settable (`--set T-nnn description=...`). The planning methodology writes them; the
  status frontier surfaces them (`report.mjs` gains a `frontier` array of
  id/title/description).
- **New skill: `sunoku:viewing-the-record`.** Renders `tasks.jsonl` + `decisions.jsonl`
  into one self-contained `.sunoku/record.html` (milestone → epic → task hierarchy with
  descriptions, status badges, filters; decisions with stakes/status/answers) and opens
  it in the browser. Read-only snapshot — no server, no writes; refresh = re-run
  `record-html.mjs`.

## 3.0.0 — 2026-07-10

Full transformation to a gateway-driven skill architecture. Breaking: skill names change and
custom agents are removed.

- **Gateway skill + injection.** New `sunoku:using-sunoku` skill (routing table, red-flags
  discipline). The SessionStart hook now injects its full content, wrapped in
  `<EXTREMELY_IMPORTANT>`, whenever a `.sunoku/` record exists (any lifecycle — previously a
  short hand-written cue, live records only), plus one line of record state. No record still
  means silence.
- **Skills renamed** verb-first and rewritten to a shared anatomy (Overview + core
  principle, "Announce at start", checklists, dot-digraph flowcharts at non-obvious
  decisions, red-flags tables, Integration cross-refs, hard gates): `init` →
  `starting-a-product`, `research` → `researching`, `prd` → `writing-the-prd`, `plan` →
  `planning-the-work`, `track` → `tracking-changes`, `status` → `checking-status`, `read` →
  `querying-the-record`. Descriptions rewritten to triggers-only ("Use when ...") so agents
  read the skill body instead of a workflow summary in frontmatter.
- **Agents removed.** The four custom agents (`researcher`, `red-team`, `product-owner`,
  `codebase-analyst`) are gone. Their roles live in skill-owned prompt files
  (`references/*-prompt.md`) with dispatch templates; skills dispatch generic general-purpose
  subagents that inherit the session model. Former `*-contract.md` files are merged
  into the prompt files. Tool restriction is prompt-enforced; the guard-record-writes hook
  still hard-blocks machine-file writes.
- All behavior preserved: three checkpoints, decisions.jsonl flow, script-only machine
  writes, restamp rules, never-execute, silent-by-default tracking, NO-GO wipe.

## 2.1.2 — 2026-07-10

- README superpowers loop prompts no longer force subagent-driven-development for every task:
  build inline or with subagents, taking the recommended option; specs and plans are written
  only when needed.

## 2.1.1 — 2026-07-09

- `status` no longer suggests a PRD refresh from staleness — commits landing is executors
  working the plan, not PRD drift. Staleness is narrate-only; only a stub PRD routes to
  `sunoku:prd`. Drift calls belong to the user (refresh on request) and to `sunoku:track` at
  prompt time.
- New `status-write.mjs --touch` restamps `updated` with no other change; `prd` flows now
  restamp after every approved draft/patch, so staleness counting resets even when the
  one-liner is unchanged.

## 2.1.0 — 2026-07-06

- `read` and `track` are now hidden from the `/` menu via `user-invocable: false` — model-only
  invocation is enforced by frontmatter, not just prose. `init` stays user-only via
  `disable-model-invocation`.
- README: new `## Loop` section documents `/loop` with Sunoku — self-paced backlog drain,
  fixed-interval watch, and three `superpowers` build-loop variants (in-place, one-PR,
  PR-per-task).

## 2.0.0 — 2026-07-05

Breaking rewrite. History before 2.0.0 is intentionally cleared.

- Seven self-contained skills: `init` (user-only setup), `research`, `prd`, `plan`, `track`
  (model-only, consent-gated), `status`, `read` (model-only retrieval). Every skill owns its
  references, templates, and scripts — the shared canon rulebook is gone.
- Record is now `PRD.md` + `status.json` + `tasks.jsonl` + `decisions.jsonl` + `research/*.md`.
  The PRD Change Log table is the only history.
- Removed: canon.md and disclosure machinery, JOURNAL.md and the log skill's triage lanes, the
  shelved lifecycle (a NO-GO wipes `.sunoku/`), reconcile ceremony, record migrations, the Stop
  nudge hook, and four agents (design-lead, feasibility-assessor, delivery-planner,
  delivery-critic).
- No migration path: delete any v1 `.sunoku/` and re-run `sunoku:init`.
