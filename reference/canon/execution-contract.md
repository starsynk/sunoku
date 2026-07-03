# Canon — Execution contract

Sunoku plans the backlog and records what happens to it; it never executes it. `TASKS.md` is an
open contract that any executor may work — the user by hand, the main assistant in an ordinary
session, another plugin's process discipline, or a loop the user arms themselves. Sunoku never
polices the executor; the record catches up either way.

- **States**: `todo → doing → done`, or `todo → doing → blocked`. The planner writes only `todo`;
  whoever executes a task owns its row's Status from then on. Keep at most one `doing` at a time —
  it marks the task a resumed session should pick back up.
- **Blocked**: an executor giving up on a task marks it `blocked`, adds a row to the TASKS.md
  `Blocked` table (`| ID | Attempts | Reason |`), and drops one flag row in QUESTIONS.md naming
  the decision or fix that would unblock it.
- **Designed order**: milestones are dependency/risk-ordered and M1 is the walking skeleton, so
  the intended path is working tasks whose `Depends on` IDs are all `done` and finishing a
  milestone before entering the next. That is guidance for executors, not a rule Sunoku enforces.
- **Journal**: milestone-grained. One `track` entry when a milestone completes — what landed,
  what's still blocked. Per-task journal entries are noise, a silence-discipline violation;
  task-level history lives in TASKS.md. A task whose implementation turns out to reshape the
  product goes through Triage like any other change.
- **Reconcile catches up**: an executor that never touches `Status` costs nothing. When reconcile
  reads a diff showing a planned task's work has landed, it flips that row to `done` and cites the
  evidence in its summary; diff content it cannot map to a task row goes through normal Triage
  instead. Statuses are a view of reality, never a permission system.
