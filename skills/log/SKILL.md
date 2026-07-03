---
name: log
description: Capture a change or decision into the Sunoku living record and run the SILENT/TRACK/RESHAPE triage. Use when the user says "record that...", "log that...", "we decided...", "we're adding/dropping X", or when a Sunoku session hook asks for a triage of this session's work. Requires a live record (.sunoku/status.json with lifecycle live).
---

## Mission

You are the orchestrator. Run the triage engine against the subject of this invocation and leave
the living record (JOURNAL.md, PRD.md, ROADMAP.md/TASKS.md, QUESTIONS.md, status.json) exactly as
accurate as it was before the change, no more ceremony than that requires.

## Flow

1. **Guard: live record required.** Check `.sunoku/status.json`. If it does not exist, or its
   `lifecycle` value is not `live`, tell the user plainly there is no live record to log against
   and route them to `sunoku:init` (name it by that skill name). Do nothing else — no journal
   write, no file read beyond status.json. If `lifecycle` is `shelved`, the same guard applies:
   there is nothing live to track. Note `status.json`'s `tracking` flag is orthogonal to this
   guard: `tracking: false` mutes the AMBIENT layer only (hooks stop nudging), while an explicit
   user invocation of `sunoku:log` still runs the full triage — a direct request to record
   something always beats the mute.

2. **Read canon core.** With the guard passed, read `${CLAUDE_PLUGIN_ROOT}/reference/canon.md`
   (core: Prime directive, Coexistence, Triage, Disclosure map) in full. Then load exactly the
   `reference/canon/` section files the Disclosure map names for your lane — for SILENT/TRACK
   that is none; a RESHAPE loads its four before step 6. Obey loaded sections verbatim; this
   skill does not restate their rules.

3. **Establish the subject.** Two triggers:
   - **User-stated** — the user's own sentence ("we decided...", "we're dropping X...") is the
     subject; take it at face value, do not go hunting for corroborating diffs.
   - **Hook-triggered** — no explicit statement, just a triage request for "this session's
     work." Inspect the conversation for what was actually done, then run `git status` and
     `git diff` read-only (never write, stage, or commit) to see what actually changed on disk.
     Build the subject from what you find, not from what the session intended to do.

4. **Apply the canon Triage test verbatim** — "after this change, would the PRD or roadmap need
   editing to stay accurate?" — and route into exactly one lane:
   - **SILENT** — tell the user in one line that this was triaged as silent (bugfix, styling,
     refactor, perf, config, copy) and stop. No journal entry, no file touch, no agent dispatch.
     A SILENT change that gets a journal entry is a canon violation, not caution.
   - **TRACK** — append one journal entry (format in step 5). If a roadmap exists
     (`.sunoku/ROADMAP.md` / `TASKS.md` present and not stub-sentineled) and the work is
     genuinely new in-scope work (work consistent with the current scope — distinct from a
     change TO the scope, which is RESHAPE) — not just an implementation detail of an existing
     task — append a task row to TASKS.md. No subagents, no checkpoint; this lane is
     zero-ceremony by canon design.
   - **Ambiguous** (you cannot confidently place it in SILENT or RESHAPE) — default to TRACK
     (append the journal entry as above), and additionally append a flagged entry to
     QUESTIONS.md per canon's Assumption format, naming what's ambiguous about the
     classification and what would flip it to RESHAPE. Never silently RESHAPE on an ambiguous
     read.
   - **RESHAPE** (touches core bet, product scope, architecture, target segment, or pricing) —
     run the RESHAPE procedure in step 6 instead of the plain TRACK write.

5. **Journal entry format (exact, for TRACK and RESHAPE alike; `decision` entries use the same
   shape with type `decision`):**

   ```markdown
   ## 2026-07-02 — track
   **What:** <one-line summary>
   **Why:** <rationale — the story-changing part>
   **Refs:** <commit shas / PR numbers / "conversation" if uncommitted>
   ```

   Append to `.sunoku/JOURNAL.md`, newest entry at the bottom. If this is the first real entry
   (the file still carries `<!-- sunoku:stub -->` as its first line), delete that sentinel line
   as part of this write — the file is append-only from here on.

6. **RESHAPE procedure** — load the canon section files the Disclosure map names for
   "log — RESHAPE", then read `${CLAUDE_PLUGIN_ROOT}/skills/log/references/reshape.md` and
   execute it exactly. It defines blast-radius scoping, owning-agent re-dispatch, the single
   checkpoint, and the reconcile write order.

7. **After any write in this run** (TRACK entry, ambiguous TRACK+flag, or full RESHAPE
   reconcile), update `.sunoku/status.json`'s `updated` field to the current timestamp,
   preserving the exact canonical serialization (one key per line, two-space indent, exact key
   order) — hooks grep this file byte-for-byte, so reformatting it breaks them even if the JSON
   is still valid. A SILENT outcome makes no status.json write at all.
