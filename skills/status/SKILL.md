---
name: status
description: The ongoing surface for a live Sunoku record. Current product state, recent journal entries, open questions, drift check with reconcile offer, and history answers — use for "what changed since May?", "why did we drop X?", "project status", "what is this product now?", or "reconcile". Suggests the next action.
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

   **Read canon.** With the guards passed, read `${CLAUDE_PLUGIN_ROOT}/reference/canon.md` in
   full before doing anything else. Obey its Triage, Checkpoints, Dispatch, and StatusFile
   sections verbatim for any write this run makes — this skill does not restate their rules.

2. **Report, concise, in this exact order** (for any `lifecycle` other than `shelved`):
   - **Product one-liner** — pulled from the PRD's `Problem` section (or the product name from
     status.json if the PRD is still a stub).
   - **Lifecycle + tracking state** — the raw `lifecycle` value and whether `tracking` is
     `true`/`false`, in plain words (e.g. "live, tracking on").
   - **Last 5 journal entries** — one line each (date + type + the `What:` line), most recent
     first, read from `.sunoku/JOURNAL.md`. Fewer than 5 if the journal has fewer.
   - **Open QUESTIONS count** — total open entries in `.sunoku/QUESTIONS.md`, and name any
     `stakes: high` ones individually (title + one-line gist), not just the count.
   - **Validation-report age**, if `.sunoku/validation/` has any dated report — cite it as
     "validated 2026-07" style (month granularity) from the report's filename/date. Omit this
     line entirely if no validation report exists (e.g. existing-code origin, or committed
     first-class skip).
   - **Drift** — run `git rev-list --count <last_reconciled_sha>..HEAD` read-only and check for
     a dirty working tree (`git status --porcelain`). Report as "N commits since last reconcile"
     (plus "working tree has uncommitted changes" if dirty). N=0 and clean → report "up to date."
     **Empty `last_reconciled_sha`**: `""..HEAD` is not a valid range and silently yields 0 — if
     `last_reconciled_sha` is empty, treat all current history as unreconciled instead: drift
     count = `git rev-list --count HEAD`.
   - **Suggested next action** — exactly one, chosen by this priority order: (1) offer reconcile
     if drift > 0 or the tree is dirty; (2) else prompt to answer the highest-stakes open
     question if one exists; (3) else, if `lifecycle` is `live` with no roadmap
     (`ROADMAP.md`/`TASKS.md` absent or still stub-sentineled), offer an optional PLAN pass;
     (4) else, if `.sunoku/TASKS.md` has any `todo`, `doing`, or `blocked` task, report the counts
     (e.g. "6 todo, 1 blocked in M2", or "1 doing — an interrupted task to resume" when a `doing`
     row is present) and note the backlog is ready to work with whatever executor the user prefers
     (canon Execution contract) — report, never execute; (5) else state plainly that nothing needs
     attention right now.

3. **History questions** — when the user asks something like "what changed since May?" or "why
   did we drop X?", answer strictly from the record:
   - Scan `.sunoku/JOURNAL.md` entry headers (`## YYYY-MM-DD — <type>`) by date first to find
     the relevant window or event, then read the matching entry bodies for the `Why:` content.
   - For "what changed" style questions, also check the PRD's `Change Log` table and cite
     matching rows (with their Journal ref).
   - Always cite the entry date(s) you're answering from.
   - **Never invent history.** If the journal (and Change Log) genuinely do not cover the
     question asked, say so directly — pre-Sunoku history is out of scope by design, not a gap
     to paper over with speculation or git-log archaeology.

4. **Reconcile** — run this when the user accepts the step-2 offer, or asks for it directly
   ("reconcile"):
   - Read the actual code diff: `git diff <last_reconciled_sha>..HEAD` (code-reading is the
     evidence; never substitute commit-message summaries for reading the diff, per canon).
     **Empty `last_reconciled_sha`**: `""..HEAD` is not a valid range and would silently read as
     an empty diff — if `last_reconciled_sha` is empty, read the full current tree instead of a
     diff (e.g. `git diff $(git hash-object -t tree /dev/null)..HEAD`, or read the tracked files
     directly) before triaging, so nothing since arming is skipped.
   - **Size gate**: if the diff touches ≲20 files AND ≲2k changed lines, read it inline
     yourself. If it exceeds either threshold, dispatch `sunoku:codebase-analyst` with the
     RECONCILE hat, scoped per canon Dispatch (absolute `.sunoku/` path, the exact sha range to
     diff, the exact report/fragment path to write, sentinel+summary obligation) rather than
     reading the whole diff yourself.
   - **Group** the resulting changes into coherent units (inline or from the dispatched report).
   - Run **each group** through the same triage `sunoku:log` uses: SILENT (skip, note nothing) /
     TRACK (append one journal entry per group, task row if applicable) / RESHAPE (invoke the
     `sunoku:log` skill's RESHAPE procedure in full for that group — blast radius, owning-agent
     re-dispatch only, one checkpoint per RESHAPE group covering that group's full delta).
     Multiple RESHAPE groups in one reconcile get one checkpoint each, never combined into a
     single omnibus checkpoint.
   - **Task statuses** (canon Execution contract): while triaging, when a group's diff shows the
     work of a planned TASKS.md task has landed, flip that row's Status to `done` (a `doing` row
     whose work the diff completes flips the same way) and cite the evidence in the reconcile
     summary. Never infer completion the diff doesn't show — partial work stays as-is, noted.
   - When all groups are resolved, set `last_reconciled_sha` to the current HEAD and update
     `updated`, in the canonical status.json serialization (one key per line, two-space indent,
     exact key order — hooks grep this byte-for-byte).

5. **Mute/unmute** — on explicit user request ("mute tracking", "turn tracking back on"), flip
   `tracking` in `.sunoku/status.json` to the requested boolean, preserving the canonical
   serialization exactly, and confirm the new state back to the user in one line. This is the
   only write this skill makes outside of a reconcile pass.
