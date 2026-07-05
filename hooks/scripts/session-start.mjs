#!/usr/bin/env node
// Sunoku ambient layer: one context cue when a live record exists. Node so it runs anywhere
// Node ≥18 does. Must never disturb a session: every failure path exits 0 silently.
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

try {
  const input = JSON.parse(readFileSync(0, 'utf8'));
  if (!input.agent_id && input.session_id) {
    const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();
    const status = JSON.parse(readFileSync(join(root, '.sunoku', 'status.json'), 'utf8'));
    if (status.lifecycle === 'live') {
      const ctx = status.tracking === true
        ? `Sunoku record active (.sunoku/): ${status.product}. Watch for prompts that reshape `
          + 'the PRD — scope, core bet, architecture, target segment, pricing. On detection run '
          + 'the sunoku:track consent flow: ask the user first, never auto-track. Implementation '
          + 'work (bugfixes, styling, refactors, perf, config, copy, in-scope features) is silent '
          + '— no record write, no mention. Questions about the PRD, decisions, tasks, or '
          + 'research history route through sunoku:read.'
        : 'Sunoku record present but muted (tracking off): no ambient watching, no sunoku:track '
          + 'detection. Explicit sunoku commands still work.';
      process.stdout.write(`${JSON.stringify({
        hookSpecificOutput: { hookEventName: 'SessionStart', additionalContext: ctx },
      })}\n`);
    }
  }
} catch { /* silent — no record / unreadable record are no-ops */ }
process.exit(0);
