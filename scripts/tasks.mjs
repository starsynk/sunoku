#!/usr/bin/env node
// Sole writer of .sunoku/tasks.jsonl, plus its query surface.
//
//   node tasks.mjs --add '{"type":"task","epic":"E-01","title":"...","discipline":"backend","size":"S"}'
//   node tasks.mjs --set T-002 status=done
//   node tasks.mjs --list ready|all|status=todo|milestone=M1|epic=E-01
import { parseArgs } from 'node:util';
import {
  appendJsonl, die, DISCIPLINES, filterTasks, nextTaskId, projectRoot, readJsonl, recordPath,
  TASK_STATUSES, writeJsonl,
} from './lib.mjs';

const { values, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    add: { type: 'string' },
    set: { type: 'string' },
    list: { type: 'string' },
  },
});

const path = recordPath(projectRoot(), 'tasks.jsonl');
const TYPES = ['milestone', 'epic', 'task'];
const SETTABLE = ['status', 'title', 'size', 'discipline'];

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
} else if (values.list) {
  process.stdout.write(JSON.stringify(filterTasks(readJsonl(path), values.list), null, 2) + '\n');
} else {
  die('nothing to do: pass --add, --set, or --list');
}
