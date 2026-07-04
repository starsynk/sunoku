#!/usr/bin/env node
// Sunoku ambient layer: inject standing triage rule + drift count at session start.
// Node (like scripts/) so hooks run anywhere Node ≥18 does — no bash dependency.
// This hook must never disturb a session: every failure path exits 0 silently.
import { execFileSync } from 'node:child_process';
import {
  existsSync, mkdirSync, readdirSync, readFileSync, statSync, unlinkSync, writeFileSync,
} from 'node:fs';
import { createHash } from 'node:crypto';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const PRUNE_AFTER_MS = 14 * 24 * 60 * 60 * 1000;

function git(root, args) {
  try {
    return execFileSync('git', ['-C', root, ...args], {
      encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return null;
  }
}

function cmpVer(a, b) {
  const pa = String(a).split('.').map(Number);
  const pb = String(b).split('.').map(Number);
  for (let i = 0; i < Math.max(pa.length, pb.length); i += 1) {
    const d = (pa[i] || 0) - (pb[i] || 0);
    if (d) return d < 0 ? -1 : 1;
  }
  return 0;
}

try {
  const input = JSON.parse(readFileSync(0, 'utf8'));
  if (!input.agent_id && input.session_id) {
    const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();
    const statusPath = join(root, '.sunoku', 'status.json');
    const status = JSON.parse(readFileSync(statusPath, 'utf8'));
    if (status.tracking === true && status.lifecycle === 'live'
      && git(root, ['rev-parse', '--git-dir']) !== null) {
      const headSha = git(root, ['rev-parse', 'HEAD']);
      if (headSha !== null) {
        const dirty = createHash('sha1').update(git(root, ['status', '--porcelain']) ?? '').digest('hex');

        const cacheDir = join(root, '.sunoku', '.cache');
        mkdirSync(cacheDir, { recursive: true });
        for (const f of readdirSync(cacheDir)) {
          try {
            const p = join(cacheDir, f);
            if (statSync(p).mtimeMs < Date.now() - PRUNE_AFTER_MS) unlinkSync(p);
          } catch { /* a vanished or unreadable cache file is not our problem */ }
        }
        writeFileSync(join(cacheDir, `session-${input.session_id}`), `${headSha} ${dirty}\n`);

        let ctx = 'Sunoku record active (.sunoku/). After any substantive change ask: would '
          + 'PRD.md or roadmap need edits to stay accurate? Yes/unsure -> run the sunoku:log '
          + 'triage. Bugfix/styling/refactor/perf/config/copy -> silent, do nothing.';

        const lastSha = status.last_reconciled_sha ?? '';
        if (lastSha && git(root, ['cat-file', '-e', `${lastSha}^{commit}`]) === null) {
          ctx += ` Reconcile baseline ${lastSha.slice(0, 7)} unreachable (history rewritten?) -> sunoku:status for a full reconcile.`;
        } else if (lastSha && lastSha !== headSha) {
          const drift = Number(git(root, ['rev-list', '--count', `${lastSha}..${headSha}`]) ?? 0);
          if (drift > 0) ctx += ` Drift: ${drift} commit(s) unreconciled -> sunoku:status.`;
        }

        const pluginJson = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '.claude-plugin', 'plugin.json');
        const pluginVer = JSON.parse(readFileSync(pluginJson, 'utf8')).version;
        const recordVer = status.sunokuVersion ?? '';
        if (pluginVer && recordVer !== pluginVer) {
          ctx += recordVer && cmpVer(recordVer, pluginVer) > 0
            ? ` Record schema ${recordVer} is newer than plugin ${pluginVer} -> update the Sunoku plugin.`
            : ` Record schema ${recordVer || 'pre-1.1.0'} older than plugin ${pluginVer} - migrates on next record touch; sunoku:status migrates now.`;
        }

        process.stdout.write(`${JSON.stringify({
          hookSpecificOutput: { hookEventName: 'SessionStart', additionalContext: ctx },
        })}\n`);
      }
    }
  }
} catch { /* silent — guards double as "no record / unreadable record" no-ops */ }
process.exit(0);
