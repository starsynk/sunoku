---
name: log
description: Capture a change or decision into the Sunoku living record and run the SILENT/TRACK/RESHAPE triage. Use when the user says "record that...", "log that...", "we decided...", "we're adding/dropping X", or when a Sunoku session hook asks for a triage of this session's work. Requires a live record (.sunoku/status.json with lifecycle live).
---

## Mission

You are the orchestrator. Run the triage engine against the subject of this invocation and leave
the living record (JOURNAL.md, PRD.md, ROADMAP.md/TASKS.md, QUESTIONS.md, status.json) exactly as
accurate as it was before the change, no more ceremony than that requires.

## Flow

1. **Read canon first.** Read `${CLAUDE_PLUGIN_ROOT}/reference/canon.md` in full before doing
   anything else. Obey its Triage, Checkpoints, Dispatch, and StatusFile sections verbatim —
   this skill does not restate their rules, only invokes them in order below.

2. **Guard: live record required.** Check `.sunoku/status.json`. If it does not exist, or its
   `lifecycle` value is not `live`, tell the user plainly there is no live record to log against
   and route them to `sunoku:init` (name it by that skill name). Do nothing else — no journal
   write, no file read beyond status.json. If `lifecycle` is `shelved`, the same guard applies:
   there is nothing live to track.

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
     genuinely new scope-fitting work — not just an implementation detail of an existing task —
     append a task row to TASKS.md. No subagents, no checkpoint; this lane is zero-ceremony by
     canon design.
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

6. **RESHAPE procedure** — exactly one checkpoint, no more, per canon Checkpoints:

   a. **Scope the blast radius.** Name explicitly which PRD sections (`Problem`, `Personas`,
      `Features`, `Architecture`, `Out of scope`, `Success metrics`, `Commercial`) and which
      roadmap/task slices are invalidated by this change. Be specific — "Features and
      Architecture" not "parts of the PRD."

   b. **Re-dispatch only the owning agents for the named slices**, per canon Dispatch (absolute
      `.sunoku/` path, exact files to read, exact files to write, hat named, sentinel+summary
      obligation in every dispatch):
      - `sunoku:product-owner` for scope / target segment / pricing sections — RESHAPE hat,
        patching only the named PRD sections.
      - `sunoku:feasibility-assessor` DEFINE hat for architecture changes — patching only the
        architecture section.
      - `sunoku:delivery-planner` (RESHAPE hat) then `sunoku:delivery-critic` for the affected
        roadmap/task slices only.
      Never dispatch the validation machinery (researcher, red-team, market/feasibility
      VALIDATE hats) for a RESHAPE — that machinery answers "should we build this at all,"
      which this event does not reopen.

   c. **Present ONE checkpoint**: the full delta as a single unit — proposed PRD section edits +
      roadmap/task patch + a draft `reshape` journal entry (format from step 5) — presented
      together for approval. Apply any user corrections and re-present the full delta again
      until the user approves it as a whole. Do not split this into multiple approval rounds.

   d. **On approval, reconcile in this exact order**, writing each in turn:
      i. Append the `reshape` journal entry to `.sunoku/JOURNAL.md` (delete the stub sentinel
         if this is the first entry).
      ii. Apply the approved PRD section edits to `.sunoku/PRD.md` and append a Change Log row
          (`| Date | Change | Why | Journal ref |`) pointing at the entry just written.
      iii. Apply the approved patch to `.sunoku/ROADMAP.md` / `TASKS.md`.
      iv. Update `.sunoku/status.json` `updated` timestamp (canonical serialization — see
          canon StatusFile; you are the only writer).

7. **After any write in this run** (TRACK entry, ambiguous TRACK+flag, or full RESHAPE
   reconcile), update `.sunoku/status.json`'s `updated` field to the current timestamp,
   preserving the exact canonical serialization (one key per line, two-space indent, exact key
   order) — hooks grep this file byte-for-byte, so reformatting it breaks them even if the JSON
   is still valid. A SILENT outcome makes no status.json write at all.
