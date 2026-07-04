#!/usr/bin/env node
// PreToolUse guard: .sunoku/status.json is script-written (canon statusfile.md) — deny
// Edit/Write tool calls that target it and point at the sanctioned script instead.
// Everything else allows silently; so does any guard-side error (exit 0, no output).
import { readFileSync } from 'node:fs';

try {
  const input = JSON.parse(readFileSync(0, 'utf8'));
  const filePath = String(input?.tool_input?.file_path ?? '').replaceAll('\\', '/');
  if (/(^|\/)\.sunoku\/status\.json$/.test(filePath)) {
    process.stdout.write(`${JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'deny',
        permissionDecisionReason: '.sunoku/status.json is script-written: use node '
          + '"${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" (canon statusfile.md). Hand edits '
          + 'break the canonical serialization and the updated/sunokuVersion restamp.',
      },
    }, null, 2)}\n`);
  }
} catch { /* silent allow — the guard must never block a session on its own bug */ }
process.exit(0);
