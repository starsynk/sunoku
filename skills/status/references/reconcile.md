# status — Reconcile procedure

Preconditions: canon core read; canon sections dispatch, statusfile, sentinels-resume loaded
per the Disclosure map.

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
  work of a planned TASKS.md task has landed, flip that row via
  `node "${CLAUDE_PLUGIN_ROOT}/scripts/tasks-set.mjs" --id <id> --status done` (a `doing` row
  whose work the diff completes flips the same way) and cite the evidence in the reconcile
  summary. Never infer completion the diff doesn't show — partial work stays as-is, noted.
- When all groups are resolved, run
  `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --sha-head --refresh` — one write
  that sets `last_reconciled_sha` to HEAD, restamps `updated`, and refreshes the summary
  fields in the canonical serialization (canon statusfile.md).
