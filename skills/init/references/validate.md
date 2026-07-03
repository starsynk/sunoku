# init — VALIDATE phase

Preconditions: canon core read; canon sections for "init — any phase" loaded per the Disclosure map.

c. **VALIDATE** (lifecycle `validating`). Dispatch `sunoku:researcher` and
   `sunoku:feasibility-assessor` (VALIDATE hat) **in parallel** — one message, both dispatches.
   Per canon Dispatch each names: the absolute `.sunoku/` path; read list (`BRIEF.md`); write
   targets (`research/demand.md` + `research/competitors.md` for the researcher;
   `research/feasibility.md` for the assessor) plus each agent's own evidence fragment
   (`research/.fragments/validate-researcher.md`, `research/.fragments/validate-feasibility.md`);
   the section list from their contracts; and the sentinel+summary closer. At the phase barrier
   (both returned), merge per canon Fragments: concatenate both fragments onto `research/EVIDENCE.md`,
   delete the fragment files, and assert fragment count == 2 dispatched writers (a missing fragment
   is a lost agent — re-dispatch that one; never invent rows). Then dispatch `sunoku:red-team`
   (VALIDATE hat): read list = `BRIEF.md` + `research/demand.md` + `research/competitors.md` +
   `research/feasibility.md` + `research/EVIDENCE.md`; write = `research/.fragments/validate-critique.md`.
   Run the conflict loop per canon Conflict (evidence-resolvable disagreements re-run only the
   affected piece, capped at 3 attempts total; judgment calls become flagged assumptions, not
   retries). Then YOU compose `validation/<YYYY-MM-DD>-validation.md` from the validation-report
   template: verdict (GO / NO-GO / GO-IF with named conditions), the per-claim evidence table with
   strength self-ratings, the red-team's fetched-source verification notes, and assumptions
   carried, then delete the critique fragment. This file is immutable once finalized.
   **Checkpoint = the go/no-go.** If the retry cap
   was hit with a blocking objection still open, present this checkpoint labeled **NON-CONVERGED**
   and let the user break the tie. If ≥3 high-stakes assumptions have accrued, surface them inside
   this checkpoint using canon's verbatim line.
