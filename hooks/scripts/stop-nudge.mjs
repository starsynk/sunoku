#!/usr/bin/env node
// Sunoku one-shot Stop nudge: fires at most once per session, and only when
// code changed but the journal did not. Never blocks stopping (always exit 0).
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { join } from 'node:path';

function git(root, args) {
  try {
    return execFileSync('git', ['-C', root, ...args], {
      encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return null;
  }
}

try {
  const input = JSON.parse(readFileSync(0, 'utf8'));
  if (!input.agent_id && input.session_id) {
    const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();
    const status = JSON.parse(readFileSync(join(root, '.sunoku', 'status.json'), 'utf8'));
    const snapPath = join(root, '.sunoku', '.cache', `session-${input.session_id}`);
    const markerPath = join(root, '.sunoku', '.cache', `nudged-${input.session_id}`);
    if (status.tracking === true && status.lifecycle === 'live'
      && existsSync(snapPath) && !existsSync(markerPath)
      && git(root, ['rev-parse', '--git-dir']) !== null) {
      const headSha = git(root, ['rev-parse', 'HEAD']);
      if (headSha !== null) {
        const dirty = createHash('sha1').update(git(root, ['status', '--porcelain']) ?? '').digest('hex');
        const changed = `${headSha} ${dirty}\n` !== readFileSync(snapPath, 'utf8');
        const journalPath = join(root, '.sunoku', 'JOURNAL.md');
        const journaled = existsSync(journalPath)
          && statSync(journalPath).mtimeMs > statSync(snapPath).mtimeMs;
        if (changed && !journaled) {
          writeFileSync(markerPath, '');
          process.stdout.write(`${JSON.stringify({
            hookSpecificOutput: {
              hookEventName: 'Stop',
              additionalContext: 'Sunoku: code changed in this session but the journal did not. '
                + 'Run the sunoku:log triage on the work from this session now. SILENT is a valid '
                + 'outcome — planned TASKS.md task work needs only its status flip (tasks-set.mjs), '
                + 'never a journal entry. Journal only if the PRD or the plan would need editing '
                + 'beyond a status flip, or a milestone completed.',
            },
          })}\n`);
        }
      }
    }
  }
} catch { /* silent — a nudge is never worth disturbing a stop */ }
process.exit(0);
