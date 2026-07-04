---
name: status
description: Surface for a live Sunoku record: product state, recent journal, open questions, drift with reconcile offer, history answers. Use for "what changed since May?", "why did we drop X?", "project status", "what is this product now?", or "reconcile". Suggests the next action.
---

## Mission

You are the orchestrator. This skill is read-mostly: report the current truth of the record, then
optionally act (reconcile, mute/unmute) only when the user asks or accepts an offered action.

## Flow

1. **Guard: record required.** Check `.sunoku/status.json`. If it does not exist, tell the user
   plainly there is no Sunoku record for this repo yet and route them to `sunoku:init`. Do
   nothing else.

   **Guard: shelved.** If `lifecycle` is `shelved`, do not run the live-record report in step 2.
   Instead read `.sunoku/JOURNAL.md` for the `decision` entry (or entries) that explain the kill,
   summarize the shelving rationale from those entries in the user's terms, and mention that
   `sunoku:init` can revive the record if they want to pick it back up. Stop there.

   **Read canon core.** With the guards passed, read `${CLAUDE_PLUGIN_ROOT}/reference/canon.md`
   in full. The report and history paths need no section files; a reconcile loads exactly the
   files the Disclosure map names for "status — reconcile" before step 4 runs. Obey loaded
   sections verbatim; this skill does not restate their rules.

2. **Report, concise, in this exact order** (for any `lifecycle` other than `shelved`). Run
   `node "${CLAUDE_PLUGIN_ROOT}/scripts/report.mjs"` — one JSON blob carrying every fact this
   step needs (summary fields, drift with the empty-`last_reconciled_sha` fallback baked in,
   dirty flag, validation reports, roadmap state, task counts). Never re-derive its facts from
   the record files. Narrate:
   - **Product one-liner** — `one_liner`, directly.
   - **Lifecycle + tracking state** — in plain words (e.g. "live, tracking on").
   - **Journal freshness** — `last_entry` as-is (date + type + What line, or "no entries yet"
     if empty). Drill in with `grep -n '^## ' .sunoku/JOURNAL.md | tail -n 5` only if asked
     for more; never read the whole journal for this line.
   - **Open QUESTIONS count** — `open_questions`/`high_stakes`. When `high_stakes` > 0, name
     the entries from `high_stakes_titles`, reading only those blocks (title + one-line gist).
   - **Validation-report age**, from `validation_reports` — cite as "validated 2026-07" style
     (month granularity). `validation_stale` true → add that the newest report is over 6 months
     old. Omit this line entirely when the list is empty (e.g. existing-code origin, or
     committed first-class skip).
   - **Drift** — `drift`/`dirty`, as "N commits since last reconcile" (plus "working tree has
     uncommitted changes" if dirty). `baseline_lost` true → say the reconcile baseline no longer
     resolves (history rewritten) instead of a count. 0 and clean → report "up to date."
   - **Suggested next action** — exactly one, chosen by this priority order: (1) offer reconcile
     if drift > 0, `baseline_lost` is true (a full reconcile — the procedure treats a lost
     baseline like an empty one), or the tree is dirty; (2) else prompt to answer the
     highest-stakes open question if one exists (answers route through `sunoku:log`); (3) else,
     if `validation_stale` is true, offer a re-validate pass (step 6); (4) else, if `lifecycle`
     is `live` and `roadmap` is `absent` or `stub`, offer an optional PLAN pass; (5) else, if
     `tasks` has any `todo`, `doing`, or `blocked`, report the counts with per-milestone
     progress from `milestones` (e.g. "M1 3/5 done; 6 todo, 1 blocked", or "1 doing — an
     interrupted task to resume") and note the backlog is ready to work with whatever executor
     the user prefers (canon Execution contract) — report, never execute; (6) else state
     plainly that nothing needs attention right now.

   `summary_fields_missing` true (pre-1.3.0 record) → run
   `node "${CLAUDE_PLUGIN_ROOT}/scripts/migrate.mjs"` now, re-run the report, then narrate.
   `summary_stale` true → run `scripts/status-write.mjs --refresh` first, same way.

3. **History questions** — when the user asks something like "what changed since May?" or "why
   did we drop X?", answer strictly from the record:
   - When a window or tag is named, run
     `node "${CLAUDE_PLUGIN_ROOT}/scripts/report.mjs" --since YYYY-MM-DD --tag <t>` (either flag
     alone works) — `journal_matches` returns date/type/What/tags across archives and the live
     journal in one call. Otherwise scan headers with `grep -n '^## ' .sunoku/JOURNAL.md` (and
     any `.sunoku/journal/*.md` archives) first; read only the matching entry bodies for `Why:`.
   - For "what changed" style questions, also check the PRD's `Change Log` table and cite
     matching rows (with their Journal ref).
   - Always cite the entry date(s) you're answering from.
   - **Never invent history.** If the journal (and Change Log) genuinely do not cover the
     question asked, say so directly — pre-Sunoku history is out of scope by design, not a gap
     to paper over with speculation or git-log archaeology.

4. **Reconcile** — when the user accepts the step-2 offer or asks directly ("reconcile"): load
   the canon section files the Disclosure map names for "status — reconcile", then read
   `${CLAUDE_PLUGIN_ROOT}/skills/status/references/reconcile.md` and execute it exactly. It
   defines the diff read (including the empty `last_reconciled_sha` fallback), the ≲20-file/≲2k-line
   size gate for dispatching `sunoku:codebase-analyst` (RECONCILE hat), per-group triage, task
   status flips, and the closing `last_reconciled_sha`/`updated` write.

5. **Mute/unmute** — on explicit user request ("mute tracking", "turn tracking back on"), run
   `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --set tracking=false` (or `=true`)
   and confirm the new state back to the user in one line. Outside of a reconcile pass, this and
   a re-validate's closing writes are the only record writes this skill makes.

6. **Re-validate** — when the user accepts the stale-validation offer or asks directly
   ("re-validate", "is the bet still sound?"): load the canon section files the Disclosure map
   names for "status — re-validate", then read
   `${CLAUDE_PLUGIN_ROOT}/skills/status/references/revalidate.md` and execute it exactly.

7. **Doctor** — on request ("check the record", "record health"): run
   `node "${CLAUDE_PLUGIN_ROOT}/scripts/doctor.mjs"` (read-only) and narrate findings grouped by
   level, each with its named fix; `ok` true → one all-clear line. Never auto-apply fixes beyond
   the scripts a finding names.

8. **Digest** — on request ("digest", "stakeholder summary"): run
   `node "${CLAUDE_PLUGIN_ROOT}/scripts/digest.mjs"` (add `--days N` if the user names a
   window) and reply with the written path. The file under `.sunoku/digest/` is a derived
   snapshot — regenerating is always safe; the record stays the truth.
