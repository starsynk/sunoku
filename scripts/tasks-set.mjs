#!/usr/bin/env node
// Flip one TASKS.md row's Status cell (canon Execution contract: reconcile flips rows whose
// work the diff proves landed). Which row deserves the flip is the caller's judgment; this
// script only makes the edit mechanical.
//
//   node tasks-set.mjs --id T2 --status done
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import { die, projectRoot } from './lib.mjs';

const STATUSES = ['todo', 'doing', 'done', 'blocked'];

const { values } = parseArgs({
  options: { id: { type: 'string' }, status: { type: 'string' } },
});
if (!values.id) die('--id is required');
if (!STATUSES.includes(values.status ?? '')) die(`invalid status: ${values.status} (${STATUSES.join('|')})`);

const root = projectRoot();
const tasksPath = join(root, '.sunoku', 'TASKS.md');

let content;
try {
  content = readFileSync(tasksPath, 'utf8');
} catch {
  die(`no tasks file: ${tasksPath}`);
}

const rowPattern = new RegExp(`^\\|\\s*${values.id}\\s*\\|`);
const lines = content.split('\n');
const matches = lines.map((l, i) => (rowPattern.test(l) ? i : -1)).filter((i) => i !== -1);
if (matches.length === 0) die(`task ${values.id} not found in TASKS.md`);
if (matches.length > 1) die(`task ${values.id} matches ${matches.length} rows — fix TASKS.md ids first`);

const i = matches[0];
// Replace the last cell (the Status column) in place, preserving the row's spacing style.
const flipped = lines[i].replace(/\|([^|]*)\|\s*$/, (cell, prev) => cell.replace(prev, ` ${values.status} `));
if (flipped === lines[i] && !new RegExp(`\\| ${values.status} \\|\\s*$`).test(lines[i])) {
  die(`could not rewrite status cell of: ${lines[i]}`);
}
lines[i] = flipped;
writeFileSync(tasksPath, lines.join('\n'));
process.stdout.write(`${lines[i]}\n`);
