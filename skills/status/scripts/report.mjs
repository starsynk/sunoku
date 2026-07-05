#!/usr/bin/env node
// One-shot v2 record report for sunoku:status. Read-only, one JSON object on stdout.
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import {
  filterDecisions, git, isStub, projectRoot, readJsonl, readStatus, readyTasks, recordPath,
} from '../../../scripts/lib.mjs';

const root = projectRoot();
const status = readStatus(root);

const prdPath = recordPath(root, 'PRD.md');
const prd = existsSync(prdPath) ? readFileSync(prdPath, 'utf8') : null;

const decisions = readJsonl(recordPath(root, 'decisions.jsonl'));
const open = filterDecisions(decisions, 'open');
const high = filterDecisions(decisions, 'high');

const taskRows = readJsonl(recordPath(root, 'tasks.jsonl'));
let tasks = null;
if (taskRows.length > 0) {
  const counts = { todo: 0, doing: 0, done: 0, blocked: 0 };
  for (const r of taskRows) if (r.type === 'task' && r.status in counts) counts[r.status] += 1;
  const milestones = taskRows.filter((r) => r.type === 'milestone').map((m) => {
    const epics = new Set(taskRows.filter((r) => r.type === 'epic' && r.milestone === m.id).map((r) => r.id));
    const inMilestone = taskRows.filter((r) => r.type === 'task' && epics.has(r.epic));
    return {
      id: m.id,
      title: m.title,
      total: inMilestone.length,
      done: inMilestone.filter((r) => r.status === 'done').length,
    };
  });
  tasks = { counts, ready: readyTasks(taskRows).length, milestones };
}

const researchDir = recordPath(root, 'research');
const research = existsSync(researchDir)
  ? readdirSync(researchDir).filter((f) => f.endsWith('.md')).sort()
  : [];

const staleness = { dirty: null, commits_since_updated: null };
if (git(root, ['rev-parse', '--git-dir']) !== null) {
  const porcelain = git(root, ['status', '--porcelain']);
  staleness.dirty = porcelain === null
    ? null
    : porcelain.split('\n').some((l) => l && !l.slice(3).startsWith('.sunoku'));
  const count = git(root, ['rev-list', '--count', `--since=${status.updated}`, 'HEAD']);
  staleness.commits_since_updated = count === null ? null : Number(count);
}

process.stdout.write(JSON.stringify({
  product: status.product ?? null,
  one_liner: status.one_liner ?? null,
  lifecycle: status.lifecycle ?? null,
  tracking: status.tracking ?? null,
  prd_stub: prd === null || isStub(prd),
  decisions: {
    open: open.length,
    high: high.length,
    high_titles: high.map((d) => ({ id: d.id, question: d.question, default: d.default ?? '' })),
  },
  tasks,
  research,
  staleness,
}, null, 2) + '\n');
