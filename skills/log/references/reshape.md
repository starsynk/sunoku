# log — RESHAPE procedure

Preconditions: canon core read; canon sections dispatch, checkpoints, assumptions, statusfile
loaded per the Disclosure map. Exactly one checkpoint, no more, per canon Checkpoints.

a. **Scope the blast radius.** Name explicitly which PRD sections (`Problem`, `Personas`,
   `Features`, `Architecture`, `UX`, `Out of scope`, `Success metrics`, `Commercial`) and
   which roadmap/task slices are invalidated by this change. Be specific — "Features and
   Architecture" not "parts of the PRD."

b. **Re-dispatch only the owning agents for the named slices**, per canon Dispatch (absolute
   `.sunoku/` path, exact files to read, exact files to write, hat named, hat contract file named,
   sentinel+summary obligation in every dispatch):
   - `sunoku:product-owner` for scope / target segment / pricing sections — RESHAPE hat,
     patching only the named PRD sections.
   - `sunoku:feasibility-assessor` DEFINE hat for architecture changes — patching only the
     architecture section.
   - `sunoku:design-lead` for the UX section — its dispatch names only the affected
     journeys/screens, not the whole design doc.
   - `sunoku:delivery-planner` (RESHAPE hat) then `sunoku:delivery-critic` for the affected
     roadmap/task slices only. `delivery-critic` writes `research/.fragments/plan-critique.md`;
     once its findings are folded into the checkpoint delta (step c), delete the critique
     fragment.
   Never dispatch the validation machinery (researcher, red-team, market/feasibility
   VALIDATE hats) for a RESHAPE — that machinery answers "should we build this at all,"
   which this event does not reopen.

c. **Present ONE checkpoint**: the full delta as a single unit — proposed PRD section edits +
   roadmap/task patch + a draft `reshape` journal entry (format from step 5) — presented
   together for approval. Apply any user corrections and re-present the full delta again
   until the user approves it as a whole. Do not split this into multiple approval rounds.

d. **On approval, reconcile in this exact order**, writing each in turn:
   i. Append the `reshape` journal entry via
      `node "${CLAUDE_PLUGIN_ROOT}/scripts/journal-append.mjs" --type reshape --what ... --why ... --refs ...`.
   ii. Apply the approved PRD section edits to `.sunoku/PRD.md` and append a Change Log row
       (`| Date | Change | Why | Journal ref |`) pointing at the entry just written.
   iii. Apply the approved patch to `.sunoku/ROADMAP.md` / `TASKS.md`.
   iv. Run `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --refresh` — restamps
       `updated` and recomputes the summary fields from the files just written, in the
       canonical serialization (canon statusfile.md).
