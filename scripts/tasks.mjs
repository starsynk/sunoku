#!/usr/bin/env node
// Sole writer of .sunoku/tasks.jsonl, plus its query surface.
//
//   node tasks.mjs --add '{"type":"task","epic":"E-01","title":"...","discipline":"backend","size":"S"}'
//   node tasks.mjs --set T-002 status=done
//   node tasks.mjs --list ready|all|archived|status=todo|milestone=M1|epic=E-01
//   node tasks.mjs --prune-milestone M1      (archives — rows stay, flagged archived)
//   node tasks.mjs --unarchive-milestone M1
import { parseArgs } from 'node:util';
import {
  appendJsonl, die, DISCIPLINES, filterTasks, nextTaskId, projectRoot, readJsonl, recordPath,
  TASK_STATUSES, todayLocal, writeJsonl,
} from './lib.mjs';

const { values, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    add: { type: 'string' },
    set: { type: 'string' },
    list: { type: 'string' },
    'prune-milestone': { type: 'string' },
    'unarchive-milestone': { type: 'string' },
  },
});

const path = recordPath(projectRoot(), 'tasks.jsonl');
const TYPES = ['milestone', 'epic', 'task'];
const SETTABLE = ['status', 'title', 'size', 'discipline', 'description'];

function validate(row) {
  if (row.status !== undefined && !TASK_STATUSES.includes(row.status)) {
    die(`invalid status: ${row.status} (${TASK_STATUSES.join('|')})`);
  }
  if (row.discipline !== undefined && !DISCIPLINES.includes(row.discipline)) {
    die(`invalid discipline: ${row.discipline} (${DISCIPLINES.join('|')})`);
  }
}

if (values.add) {
  let row;
  try {
    row = JSON.parse(values.add);
  } catch (e) {
    die(`--add expects JSON: ${e.message}`);
  }
  if (!TYPES.includes(row.type)) die(`invalid type: ${row.type} (${TYPES.join('|')})`);
  if (!row.title) die('title is required');
  if (row.type === 'task' && !row.description) die('description is required for tasks');
  if (row.type !== 'epic') row.status ??= 'todo';
  if (row.type === 'task') {
    row.deps ??= [];
    row.spike ??= false;
  }
  validate(row);
  const rows = readJsonl(path);
  if (row.id !== undefined && rows.some((r) => r.id === row.id)) die(`duplicate id: ${row.id}`);
  row.id ??= nextTaskId(rows, row.type);
  appendJsonl(path, row);
  process.stdout.write(JSON.stringify(row) + '\n');
} else if (values.set) {
  if (positionals.length === 0) die('--set expects key=value pairs after the id');
  const rows = readJsonl(path);
  const row = rows.find((r) => r.id === values.set);
  if (!row) die(`no row with id: ${values.set}`);
  for (const pair of positionals) {
    const eq = pair.indexOf('=');
    if (eq === -1) die(`expected key=value, got: ${pair}`);
    const key = pair.slice(0, eq);
    if (!SETTABLE.includes(key)) die(`not a settable key: ${key} (${SETTABLE.join(', ')})`);
    row[key] = pair.slice(eq + 1);
  }
  validate(row);
  writeJsonl(path, rows);
  process.stdout.write(JSON.stringify(row) + '\n');
} else if (values['prune-milestone']) {
  const id = values['prune-milestone'];
  const rows = readJsonl(path);
  const milestone = rows.find((r) => r.type === 'milestone' && r.id === id);
  if (!milestone) die(`no milestone with id: ${id}`);
  if (milestone.archived) die(`already archived: ${id}`);
  const doomed = filterTasks(rows, `milestone=${id}`);
  const doomedIds = new Set(doomed.map((r) => r.id));
  const notDone = doomed.filter((r) => r.type === 'task' && r.status !== 'done');
  if (notDone.length) {
    die(`not prunable: ${notDone.map((r) => `${r.id} (${r.status})`).join(', ')} not done`);
  }
  const dependents = rows.filter((r) => r.type === 'task' && !r.archived && !doomedIds.has(r.id)
    && (r.deps ?? []).some((d) => doomedIds.has(d)));
  if (dependents.length) {
    die(`not prunable: ${dependents.map((r) => r.id).join(', ')} depend on pruned tasks — prune their milestone first`);
  }
  const stamp = todayLocal();
  for (const r of doomed) { r.archived = true; r.archived_at = stamp; }
  writeJsonl(path, rows);
  for (const r of doomed) process.stdout.write(JSON.stringify(r) + '\n');
} else if (values['unarchive-milestone']) {
  const id = values['unarchive-milestone'];
  const rows = readJsonl(path);
  const milestone = rows.find((r) => r.type === 'milestone' && r.id === id);
  if (!milestone) die(`no milestone with id: ${id}`);
  if (!milestone.archived) die(`not archived: ${id}`);
  const epics = new Set(rows.filter((r) => r.type === 'epic' && r.milestone === id).map((r) => r.id));
  const restored = rows.filter((r) => r.archived && (r.id === id
    || (r.type === 'epic' && r.milestone === id)
    || (r.type === 'task' && epics.has(r.epic))));
  for (const r of restored) { delete r.archived; delete r.archived_at; }
  writeJsonl(path, rows);
  for (const r of restored) process.stdout.write(JSON.stringify(r) + '\n');
} else if (values.list) {
  process.stdout.write(JSON.stringify(filterTasks(readJsonl(path), values.list), null, 2) + '\n');
} else {
  die('nothing to do: pass --add, --set, --list, --prune-milestone, or --unarchive-milestone');
}
