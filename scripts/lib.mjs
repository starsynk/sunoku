// Shared record plumbing. Not a command — the record scripts import from here so
// serialization, JSONL access, id sequencing, and PRD parsing have one implementation.
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, renameSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

export const LIFECYCLES = ['validating', 'defining', 'live'];
export const STATUS_KEY_ORDER = ['product', 'one_liner', 'lifecycle', 'tracking', 'created', 'updated'];
export const TASK_STATUSES = ['todo', 'doing', 'done', 'blocked'];
export const DISCIPLINES = ['design', 'frontend', 'backend', 'infra', 'qa', 'docs'];
export const STUB_SENTINEL = '<!-- sunoku:stub -->';

export function projectRoot() {
  return process.env.CLAUDE_PROJECT_DIR || process.cwd();
}

export function recordPath(root, ...rel) {
  return join(root, '.sunoku', ...rel);
}

export function statusPath(root) {
  return recordPath(root, 'status.json');
}

export function readStatus(root) {
  const p = statusPath(root);
  if (!existsSync(p)) die(`no record: ${p} does not exist — run sunoku:starting-a-product`);
  try {
    return JSON.parse(readFileSync(p, 'utf8'));
  } catch (e) {
    die(`unreadable record: ${p} is not valid JSON (${e.message})`);
  }
}

// Temp file + rename so a crash mid-write never leaves a half-written record file.
export function writeFileAtomic(path, content) {
  const tmp = `${path}.tmp-${process.pid}`;
  writeFileSync(tmp, content);
  renameSync(tmp, path);
}

export function writeStatus(root, status) {
  const ordered = {};
  for (const k of STATUS_KEY_ORDER) if (k in status) ordered[k] = status[k];
  for (const k of Object.keys(status)) if (!(k in ordered)) ordered[k] = status[k];
  writeFileAtomic(statusPath(root), JSON.stringify(ordered, null, 2) + '\n');
  return ordered;
}

// Every status.json write restamps `updated`, never touches `created`.
export function stampAndWrite(root, status, changes = {}) {
  return writeStatus(root, { ...status, ...changes, updated: nowIso() });
}

export function nowIso() {
  return new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
}

export function todayLocal() {
  const d = new Date();
  return [
    d.getFullYear(),
    String(d.getMonth() + 1).padStart(2, '0'),
    String(d.getDate()).padStart(2, '0'),
  ].join('-');
}

export function isStub(content) {
  return content !== null && content.split('\n', 1)[0].trim() === STUB_SENTINEL;
}

// --- JSONL ---

export function readJsonl(path) {
  if (!existsSync(path)) return [];
  return readFileSync(path, 'utf8')
    .split('\n')
    .filter((l) => l.trim())
    .map((l, i) => {
      try {
        return JSON.parse(l);
      } catch {
        die(`${path}:${i + 1} is not valid JSON`);
      }
    });
}

export function writeJsonl(path, rows) {
  writeFileAtomic(path, rows.map((r) => JSON.stringify(r)).join('\n') + (rows.length ? '\n' : ''));
}

export function appendJsonl(path, row) {
  const rows = readJsonl(path);
  rows.push(row);
  writeJsonl(path, rows);
  return row;
}

// Id shapes per spec: M1, E-01, T-001, D-001.
const ID_SHAPE = {
  milestone: { re: /^M(\d+)$/, make: (n) => `M${n}` },
  epic: { re: /^E-(\d+)$/, make: (n) => `E-${String(n).padStart(2, '0')}` },
  task: { re: /^T-(\d+)$/, make: (n) => `T-${String(n).padStart(3, '0')}` },
  decision: { re: /^D-(\d+)$/, make: (n) => `D-${String(n).padStart(3, '0')}` },
};

export function nextTaskId(rows, type) {
  const shape = ID_SHAPE[type] ?? die(`no id shape for type: ${type}`);
  const max = rows.reduce((m, r) => {
    const match = typeof r.id === 'string' && r.id.match(shape.re);
    return match ? Math.max(m, Number(match[1])) : m;
  }, 0);
  return shape.make(max + 1);
}

// --- tasks queries (shared by tasks.mjs --list and read's query.mjs) ---

export function readyTasks(rows) {
  const live = rows.filter((r) => !r.archived);
  const done = new Set(live.filter((r) => r.type === 'task' && r.status === 'done').map((r) => r.id));
  return live.filter((r) => r.type === 'task' && r.status === 'todo'
    && (r.deps ?? []).every((d) => done.has(d)));
}

export function filterTasks(rows, expr) {
  if (expr === 'archived') return rows.filter((r) => r.archived);
  const live = rows.filter((r) => !r.archived);
  if (expr === 'all') return live;
  if (expr === 'ready') return readyTasks(live);
  const eq = expr.indexOf('=');
  if (eq === -1) die(`invalid task filter: ${expr} (all|ready|archived|status=X|milestone=X|epic=X)`);
  const k = expr.slice(0, eq);
  const v = expr.slice(eq + 1);
  if (k === 'status') return live.filter((r) => r.status === v);
  if (k === 'epic') return live.filter((r) => r.epic === v || (r.type === 'epic' && r.id === v));
  if (k === 'milestone') {
    const epics = new Set(live.filter((r) => r.type === 'epic' && r.milestone === v).map((r) => r.id));
    return live.filter((r) => (r.type === 'task' && epics.has(r.epic))
      || (r.type === 'epic' && r.milestone === v)
      || (r.type === 'milestone' && r.id === v));
  }
  die(`unknown task filter key: ${k}`);
}

export function filterDecisions(rows, expr) {
  if (expr === 'all') return rows;
  if (expr === 'open' || expr === 'resolved') return rows.filter((r) => r.status === expr);
  if (expr === 'high') return rows.filter((r) => r.stakes === 'high' && r.status === 'open');
  die(`invalid decision filter: ${expr} (all|open|resolved|high)`);
}

// --- PRD parsing (shared by report.mjs and query.mjs) ---

export function prdSection(content, name) {
  const lines = content.split('\n');
  const start = lines.findIndex((l) => new RegExp(`^## ${name}\\b`, 'i').test(l));
  if (start === -1) return null;
  let end = lines.length;
  for (let i = start + 1; i < lines.length; i += 1) {
    if (/^## /.test(lines[i])) { end = i; break; }
  }
  return lines.slice(start, end).join('\n').trim();
}

export function changelogRows(content, since) {
  const section = prdSection(content, 'Change Log');
  if (!section) return [];
  return section.split('\n')
    .filter((l) => /^\|\s*\d{4}-\d{2}-\d{2}\s*\|/.test(l))
    .map((l) => {
      const c = l.split('|').map((s) => s.trim());
      return { date: c[1], change: c[2], why: c[3], trigger: c[4] ?? '' };
    })
    .filter((r) => !since || r.date >= since);
}

export function git(root, args) {
  try {
    return execFileSync('git', ['-C', root, ...args], {
      encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return null;
  }
}

export function die(message) {
  process.stderr.write(`${message}\n`);
  process.exit(1);
}
