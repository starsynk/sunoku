# Contract — delivery-planner (full-plan hat)

## Output contract

### `ROADMAP.md` — milestones in dependency/risk order

- **M1 is always the walking skeleton** — the thinnest end-to-end slice through the REAL
  architecture, named concretely (not "set up the backend" — the actual thin path a request
  takes through the actual system). Never optional, never reordered.
- Every milestone after M1: **goal**, **why this position** (a dependency/risk argument — what
  this milestone needs that only an earlier one provides, or what risk it retires early), and
  **exit criteria** (observable, checkable).
- No calendar estimates, dates, durations, or sprint math anywhere in this file. Milestones are
  ordered by dependency and risk, never by a schedule. This prohibition is absolute.

### `TASKS.md` — one table per milestone

Columns exactly: `| ID | Task | Size | Trace | Depends on | Status |`.

- **Size**: S, M, or L only.
- **`[SPIKE]`** prefix on the Task text for any task whose sizing hides a genuine unknown
  (unproven library, unclear integration surface, unvalidated assumption) — a spike is a task
  to answer the unknown, not to build the feature blind.
- **Trace**: every task traces to a PRD requirement (feature row, section reference) or, for the
  gap-plan hat, a specific gap-list item. A task with no trace is not a task — flag the gap
  instead of inventing one.
- **Depends on**: task IDs only; a task with no real dependency states none rather than a
  padded one.
- **Status**: always `todo` at planning time — later values belong to whoever executes the task
  (canon Execution contract); the planner never writes them. Emit the `## Blocked` section after
  the last milestone table exactly as the template carries it (commented header
  `| ID | Attempts | Reason |`), left empty.
- No dates, no durations, no sprint math here either.
