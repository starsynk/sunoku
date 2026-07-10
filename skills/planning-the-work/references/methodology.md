# Decomposition methodology

What a good PM does, encoded:

1. **Milestone = vertical slice.** M1 is always the walking skeleton — the thinnest end-to-end
   path proving the product works (one persona, one core flow, deployed). Every later milestone
   ships a usable increment. Never phase-gates (all design → all frontend → ...) — a phase plan
   maximizes blocking.
2. **Epic = feature area, traced to PRD feature ids** (`"prd": ["F-1"]`). Hard rule: zero
   cross-epic dependencies. If two epics need the same thing, that thing is its own earlier task
   inside the epic that ships first — or the epics are drawn wrong; redraw them.
3. **Contract-first inside an epic.** Order within an epic: design task → API contract/schema
   task → frontend and backend tasks IN PARALLEL against the contract (mock one side) → wire-up
   + QA task. Discipline order lives inside the epic, never across the project.
4. **Deps explicit and minimal.** Every task carries `"deps": [ids]`. A task with 3+ deps means
   the decomposition is wrong — restructure. Workable = every dep done; the ready frontier
   should span multiple epics at all times.
5. **Sizes S/M/L, never calendar estimates.** S ≈ one sitting, M ≈ a day-ish of focus, L =
   consider splitting. Unknown-shaped work is a spike (`"spike": true`, size S, timeboxed) plus
   a decision row — never a fake L estimate.
6. **Description = self-contained task.** Every task row carries a `"description"` an
   executor can act on without this conversation: what to build, what done looks like
   (acceptance criteria), key constraints, and the PRD feature/section it serves when
   applicable. Meaningful prose, typically a few sentences — never a restatement of the
   title, never a full spec. The script rejects task rows without one.
