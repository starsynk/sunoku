#!/usr/bin/env node
// Sole writer of .sunoku/decisions.jsonl — the human-in-the-loop decision log.
//
//   node decisions.mjs --add '{"question":"...","stakes":"high","default":"...","by":"prd"}'
//   node decisions.mjs --resolve D-002 --answer "usage-based"
//   node decisions.mjs --prune D-002
//   node decisions.mjs --list open|resolved|high|all
import { parseArgs } from 'node:util';
import {
  appendJsonl, die, filterDecisions, nextTaskId, projectRoot, readJsonl, recordPath, todayLocal,
  writeJsonl,
} from './lib.mjs';

const { values } = parseArgs({
  options: {
    add: { type: 'string' },
    resolve: { type: 'string' },
    answer: { type: 'string' },
    list: { type: 'string' },
    prune: { type: 'string' },
  },
});

const path = recordPath(projectRoot(), 'decisions.jsonl');
const BY = ['research', 'prd', 'plan'];
const STAKES = ['high', 'low'];

if (values.add) {
  let row;
  try {
    row = JSON.parse(values.add);
  } catch (e) {
    die(`--add expects JSON: ${e.message}`);
  }
  if (!row.question) die('question is required');
  if (!BY.includes(row.by)) die(`invalid by: ${row.by} (${BY.join('|')})`);
  row.status = 'open';
  row.stakes ??= 'low';
  if (!STAKES.includes(row.stakes)) die(`invalid stakes: ${row.stakes} (${STAKES.join('|')})`);
  row.asked ??= todayLocal();
  const rows = readJsonl(path);
  if (row.id !== undefined && rows.some((r) => r.id === row.id)) die(`duplicate id: ${row.id}`);
  row.id ??= nextTaskId(rows, 'decision');
  appendJsonl(path, row);
  process.stdout.write(JSON.stringify(row) + '\n');
} else if (values.resolve) {
  if (!values.answer) die('--resolve needs --answer');
  const rows = readJsonl(path);
  const row = rows.find((r) => r.id === values.resolve);
  if (!row) die(`no decision with id: ${values.resolve}`);
  row.status = 'resolved';
  row.answer = values.answer;
  row.resolved = todayLocal();
  writeJsonl(path, rows);
  process.stdout.write(JSON.stringify(row) + '\n');
} else if (values.prune) {
  const rows = readJsonl(path);
  const row = rows.find((r) => r.id === values.prune);
  if (!row) die(`no decision with id: ${values.prune}`);
  if (row.status !== 'resolved') die(`not prunable: ${row.id} is ${row.status} — resolve it first`);
  writeJsonl(path, rows.filter((r) => r.id !== row.id));
  process.stdout.write(JSON.stringify(row) + '\n');
} else if (values.list) {
  process.stdout.write(JSON.stringify(filterDecisions(readJsonl(path), values.list), null, 2) + '\n');
} else {
  die('nothing to do: pass --add, --resolve, --list, or --prune');
}
