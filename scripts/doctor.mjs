#!/usr/bin/env node
// Read-only record integrity check: every invariant the scripts, hooks, and canon rely on,
// as one JSON verdict on stdout. Never writes; each finding names the fix that clears it.
//
//   node doctor.mjs
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  computeSummary, git, isStub, journalEntries, KEY_ORDER, LIFECYCLES, ORIGINS, projectRoot,
  readRecordFile, readStatus, statusPath,
} from './lib.mjs';

const root = projectRoot();
const status = readStatus(root);
const findings = [];
const add = (level, check, detail) => findings.push({ level, check, detail });

// --- status.json ---

if (!LIFECYCLES.includes(status.lifecycle)) add('error', 'status_unknown_value', `lifecycle: ${status.lifecycle}`);
if (!ORIGINS.includes(status.origin)) add('error', 'status_unknown_value', `origin: ${status.origin}`);

const keys = Object.keys(JSON.parse(readFileSync(statusPath(root), 'utf8')));
const canonical = KEY_ORDER.filter((k) => keys.includes(k));
const actual = keys.filter((k) => KEY_ORDER.includes(k));
if (canonical.join() !== actual.join()) {
  add('warn', 'status_key_order', 'keys out of canonical order — any record script rewrite fixes it');
}

if ('one_liner' in status) {
  const live = computeSummary(root, status);
  const stale = ['one_liner', 'open_questions', 'high_stakes', 'last_entry']
    .filter((k) => k in status && status[k] !== live[k]);
  if (stale.length) add('warn', 'summary_stale', `${stale.join(', ')} — run status-write.mjs --refresh`);
}

// --- lifecycle vs artifacts ---

const prd = readRecordFile(root, 'PRD.md');
if (status.lifecycle === 'live' && prd !== null && isStub(prd)) {
  add('error', 'lifecycle_artifact', 'lifecycle live but PRD.md is still stub-sentineled');
}

// --- journal ---

const journal = readRecordFile(root, 'JOURNAL.md');
if (journal !== null && !isStub(journal)) {
  const ENTRY = /^## \d{4}-\d{2}-\d{2} — (track|reshape|decision)\s*$/;
  for (const line of journal.split('\n')) {
    if (/^## /.test(line) && !ENTRY.test(line)) add('error', 'journal_header', `malformed entry header: ${line}`);
  }
  const { entries } = journalEntries(journal);
  for (let i = 1; i < entries.length; i += 1) {
    if (entries[i].date < entries[i - 1].date) {
      add('warn', 'journal_order', `${entries[i].date} after ${entries[i - 1].date} — newest belongs at the bottom`);
      break;
    }
  }
}

// --- questions ---

const questions = readRecordFile(root, 'QUESTIONS.md');
if (questions !== null && !isStub(questions)) {
  const ids = [...questions.matchAll(/^## (Q-\d+) — /gm)].map((m) => m[1]);
  const dupes = [...new Set(ids.filter((id, i) => ids.indexOf(id) !== i))];
  if (dupes.length) add('error', 'questions_duplicate_id', dupes.join(', '));
  for (const line of questions.split('\n')) {
    if (/^## Q-/.test(line) && !/\(stakes: (high|normal), status: open\)\s*$/.test(line)) {
      add('error', 'questions_title', `malformed title line: ${line}`);
    }
  }
}

// --- tasks ---

const tasks = readRecordFile(root, 'TASKS.md');
if (tasks !== null && !isStub(tasks)) {
  const STATUSES = ['todo', 'doing', 'done', 'blocked'];
  const seen = [];
  let doing = 0;
  let inMilestone = false;
  for (const line of tasks.split('\n')) {
    if (/^## M\d+/.test(line)) { inMilestone = true; continue; }
    if (/^## /.test(line)) { inMilestone = false; continue; }
    if (!inMilestone || !line.startsWith('|')) continue;
    if (/^\| ID \|/.test(line) || /^\|[\s:|-]+\|$/.test(line)) continue;
    const cells = line.split('|').map((c) => c.trim()).filter(Boolean);
    if (cells.length < 2) continue;
    const [id] = cells;
    const st = cells[cells.length - 1];
    if (seen.includes(id)) add('error', 'tasks_duplicate_id', id);
    else seen.push(id);
    if (!STATUSES.includes(st)) add('error', 'tasks_status', `${id}: ${st}`);
    if (st === 'doing') doing += 1;
  }
  if (doing > 1) add('warn', 'tasks_multiple_doing', `${doing} rows doing — canon Execution contract keeps at most one`);
}

// --- leftovers ---

const fragDir = join(root, '.sunoku', 'research', '.fragments');
if (existsSync(fragDir)) {
  const orphans = readdirSync(fragDir).filter((f) => !f.startsWith('.')).length;
  if (orphans) add('warn', 'orphan_fragments', `${orphans} file(s) in research/.fragments — a phase barrier didn't clean up`);
}

const strays = [];
(function walk(dir) {
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name.includes('.tmp-')) strays.push(p.slice(root.length + 1));
  }
}(join(root, '.sunoku')));
if (strays.length) add('warn', 'stray_tmp', `${strays.join(', ')} — crashed atomic write leftover, safe to delete`);

// --- git baseline + merge attributes ---

if (git(root, ['rev-parse', '--git-dir']) !== null) {
  const sha = status.last_reconciled_sha ?? '';
  if (sha && git(root, ['cat-file', '-e', `${sha}^{commit}`]) === null) {
    add('error', 'baseline_unreachable', `${sha.slice(0, 7)} — history rewritten; run a full reconcile (sunoku:status)`);
  }
}

if (!existsSync(join(root, '.sunoku', '.gitattributes'))) {
  add('warn', 'gitattributes_missing', 'run migrate.mjs — 1.6.0 union-merge ledgers');
}

const errors = findings.filter((f) => f.level === 'error').length;
process.stdout.write(`${JSON.stringify({
  ok: findings.length === 0, errors, warnings: findings.length - errors, findings,
}, null, 2)}\n`);
