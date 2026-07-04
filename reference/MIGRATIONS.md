# Sunoku Record Migrations

Shape-sniffed fixes applied in place by whichever skill touches a `.sunoku/` record first, per
canon "Record migrations" — mechanically, by running `scripts/migrate.mjs` (this file is the
human-readable registry; the script is the applier). Grouped by the plugin version that
introduced them, newest section last. Rows are idempotent: Detect describes exactly the legacy
shape, so a migrated record never matches again. Migrations are SILENT-lane — no journal entry;
the script's output lines are the only trace.

## 1.1.0

| Detect (legacy shape) | Fix (in place) |
|---|---|
| `TASKS.md` exists, non-stub, and its task-table header lacks a `Status` column | Append `Status` to the header of every milestone table and `todo` to every task row; append an empty `## Blocked` section (commented header `\| ID \| Attempts \| Reason \|`) after the last milestone table; add the Status legend line under the file's intro blockquote |
| `status.json` lacks a `sunokuVersion` key | Insert `sunokuVersion` with the current plugin version (from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`), in canonical key order (canon StatusFile) |

## 1.2.0

| Detect (legacy shape) | Fix (in place) |
|---|---|
| `TASKS.md` Status legend line references `sunoku:work` | Replace that legend line with the current template's legend (`reference/templates/TASKS.md`): Status is maintained by whoever executes; reconcile flips rows the diff proves landed |

## 1.2.x -> 1.3.0

Records written before 1.3.0 lack `one_liner`, `open_questions`, `high_stakes`, `last_entry`.
On the first record touch: compute `one_liner` from the PRD `## Problem` first sentence (product
name if the PRD is a stub); `open_questions` = count of entries marked open (the file's
`status: open` literal) in QUESTIONS.md (0 if absent); `high_stakes` = count of OPEN entries
carrying `stakes: high`; `last_entry` from the final JOURNAL.md
`## YYYY-MM-DD — <type>` header plus its `What:` line (empty string for a stub journal). Insert
in canonical key order per canon statusfile.md and bump `sunokuVersion` in the same write.

## 1.6.0

| Detect (legacy shape) | Fix (in place) |
|---|---|
| `.sunoku/.gitattributes` missing on an existing record | Copy `reference/templates/sunoku.gitattributes` to `.sunoku/.gitattributes` — union-merge for the append-only ledgers (JOURNAL.md, `journal/*.md`, `research/EVIDENCE.md`) so concurrent branch appends never conflict |
