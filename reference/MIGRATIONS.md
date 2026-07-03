# Sunoku Record Migrations

Shape-sniffed fixes applied in place by whichever skill touches a `.sunoku/` record first, per
canon "Record migrations". Grouped by the plugin version that introduced them, newest section
last. Rows are idempotent: Detect describes exactly the legacy shape, so a migrated record never
matches again. Migrations are SILENT-lane — no journal entry; one line in the skill's output is
the only trace.

## 1.1.0

| Detect (legacy shape) | Fix (in place) |
|---|---|
| `TASKS.md` exists, non-stub, and its task-table header lacks a `Status` column | Append `Status` to the header of every milestone table and `todo` to every task row; append an empty `## Blocked` section (commented header `\| ID \| Attempts \| Reason \|`) after the last milestone table; add the Status legend line under the file's intro blockquote |
| `status.json` lacks a `sunokuVersion` key | Insert `sunokuVersion` with the current plugin version (from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`), in canonical key order (canon StatusFile) |
