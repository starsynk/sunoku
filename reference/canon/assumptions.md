# Canon — Assumptions

When inference is required and a question isn't worth a checkpoint slot, take the default and log
it as a flagged assumption rather than blocking. Format, every field required:

- **Assumption** — what was assumed.
- **Chosen default** — the value used to keep moving.
- **Reasoning** — why that default.
- **Flip-if-wrong** — what changes if the assumption is wrong.
- **Stakes** — high or normal.

Log every flagged assumption to QUESTIONS.md immediately; the run continues without waiting.
Once 3 or more high-stakes assumptions have accrued, surface them inside the next checkpoint —
never as a standalone interruption — using this line verbatim:

> "I assumed X, Y, Z — confirm or this is built on sand."

## Answering

When the user answers a flagged question ("Q-2 is answered: ...", "the answer to X is ..."),
flush it — QUESTIONS.md holds open questions only; the story moves to the journal:

1. Locate the `## Q-<n>` block in QUESTIONS.md by id or title. Missing or already flushed →
   say so, point at `grep -n 'Q-<n>' .sunoku/JOURNAL.md`, write nothing.
2. Append a `decision` journal entry first (crash-safe order): **What** = "Q-<n> <title>
   answered: <answer gist>"; **Why** = the assumption taken, the answer, and its ripple —
   confirmed or flipped; **Refs** = the evidence or commits that answered it, else
   "conversation".
3. Triage the flip through the normal lanes. Answer confirms the assumption → journal entry
   only. Answer flips it → TRACK or RESHAPE; the entry's **Flip if wrong** text is the scope
   hint. An answer is never SILENT; ambiguity still defaults to TRACK.
4. Delete the whole `## Q-<n>` block from QUESTIONS.md. Never renumber surviving entries —
   Q-ids increase monotonically for the record's life.
5. Refresh the status.json summary fields plus `updated` in the same run per canon
   statusfile.md.
