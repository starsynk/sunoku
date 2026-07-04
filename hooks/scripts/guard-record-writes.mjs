#!/usr/bin/env node
// PreToolUse guard: the script-written record files (status.json, the journal and its
// archives) reject direct Edit/Write tool calls, each denial pointing at the sanctioned
// script. Everything else allows silently; so does any guard-side error (exit 0, no output).
import { readFileSync } from 'node:fs';

const RULES = [
  [/(^|\/)\.sunoku\/status\.json$/,
    '.sunoku/status.json is script-written: use node '
    + '"${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" (canon statusfile.md). Hand edits '
    + 'break the canonical serialization and the updated/sunokuVersion restamp.'],
  [/(^|\/)\.sunoku\/JOURNAL\.md$/,
    '.sunoku/JOURNAL.md is script-written: use node '
    + '"${CLAUDE_PLUGIN_ROOT}/scripts/journal-append.mjs" — it owns stub removal, the '
    + '30KB rollover, and the status.json summary refresh.'],
  [/(^|\/)\.sunoku\/journal\/[^/]+\.md$/,
    '.sunoku/journal/ archives are written only by journal-append.mjs rollover — '
    + 'archived entries are immutable history, never edited.'],
];

try {
  const input = JSON.parse(readFileSync(0, 'utf8'));
  const filePath = String(input?.tool_input?.file_path ?? '').replaceAll('\\', '/');
  const rule = RULES.find(([pattern]) => pattern.test(filePath));
  if (rule) {
    process.stdout.write(`${JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'deny',
        permissionDecisionReason: rule[1],
      },
    }, null, 2)}\n`);
  }
} catch { /* silent allow — the guard must never block a session on its own bug */ }
process.exit(0);
