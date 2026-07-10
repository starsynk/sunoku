#!/usr/bin/env node
// Sunoku gateway injection: when a record exists, the full using-sunoku
// skill rides into context from turn zero, plus one line of record state. No record, subagent
// session, or any failure: silent exit 0 — Sunoku must never disturb a session.
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

try {
  const input = JSON.parse(readFileSync(0, 'utf8'));
  if (!input.agent_id && input.session_id) {
    const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();
    const status = JSON.parse(readFileSync(join(root, '.sunoku', 'status.json'), 'utf8'));
    const pluginRoot = process.env.CLAUDE_PLUGIN_ROOT
      || join(dirname(fileURLToPath(import.meta.url)), '..', '..');
    const gateway = readFileSync(
      join(pluginRoot, 'skills', 'using-sunoku', 'SKILL.md'), 'utf8');
    const state = `Record state: product "${status.product}", lifecycle ${status.lifecycle}, `
      + (status.tracking === true
        ? 'tracking ON (sunoku:tracking-changes consent gate is armed — never auto-track).'
        : 'tracking muted (no ambient detection; explicit sunoku skills still work).');
    const ctx = '<EXTREMELY_IMPORTANT>\nThis project has a Sunoku record.\n\n'
      + "**Below is the full content of your 'sunoku:using-sunoku' skill — how Sunoku skills "
      + "route product work. For all other skills, use the 'Skill' tool:**\n\n"
      + `${gateway}\n\n${state}\n</EXTREMELY_IMPORTANT>`;
    process.stdout.write(`${JSON.stringify({
      hookSpecificOutput: { hookEventName: 'SessionStart', additionalContext: ctx },
    })}\n`);
  }
} catch { /* silent — no record / unreadable record are no-ops */ }
process.exit(0);
