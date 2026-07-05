#!/usr/bin/env node
// PreToolUse guard: the script-written record files reject direct Edit/Write calls, each
// denial pointing at the sanctioned script. Everything else allows silently; so does any
// guard-side error (exit 0, no output).
import { readFileSync } from 'node:fs';

const RULES = [
  [/(^|\/)\.sunoku\/status\.json$/,
    '.sunoku/status.json is script-written: use node '
    + '"${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --set key=value.'],
  [/(^|\/)\.sunoku\/tasks\.jsonl$/,
    '.sunoku/tasks.jsonl is script-written: use node '
    + '"${CLAUDE_PLUGIN_ROOT}/scripts/tasks.mjs" (--add / --set / --list).'],
  [/(^|\/)\.sunoku\/decisions\.jsonl$/,
    '.sunoku/decisions.jsonl is script-written: use node '
    + '"${CLAUDE_PLUGIN_ROOT}/scripts/decisions.mjs" (--add / --resolve / --list).'],
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
