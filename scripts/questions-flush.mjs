#!/usr/bin/env node
// Flush an answered QUESTIONS.md entry (canon assumptions, Answering step 4): delete the
// whole ## Q-<n> block, never renumber survivors, refresh the status.json summary fields.
// The decision journal entry must already be written (journal-append.mjs) — crash-safe order.
//
//   node questions-flush.mjs --id Q-3
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import { computeSummary, die, projectRoot, readStatus, stampAndWrite, writeFileAtomic } from './lib.mjs';

const { values } = parseArgs({ options: { id: { type: 'string' } } });
if (!values.id) die('--id is required (e.g. --id Q-3)');
const id = /^\d+$/.test(values.id) ? `Q-${values.id}` : values.id;
if (!/^Q-\d+$/.test(id)) die(`invalid id: ${values.id} (expected Q-<n>)`);

const root = projectRoot();
const status = readStatus(root);
const questionsPath = join(root, '.sunoku', 'QUESTIONS.md');

let content;
try {
  content = readFileSync(questionsPath, 'utf8');
} catch {
  die(`no questions file: ${questionsPath}`);
}

const lines = content.split('\n');
const start = lines.findIndex((l) => new RegExp(`^## ${id} — `).test(l));
if (start === -1) {
  die(`${id} not found in QUESTIONS.md — already flushed? Check: grep -n '${id}' .sunoku/JOURNAL.md`);
}
let end = lines.length;
for (let i = start + 1; i < lines.length; i += 1) {
  if (/^## /.test(lines[i])) { end = i; break; }
}

const remaining = [...lines.slice(0, start), ...lines.slice(end)];
writeFileAtomic(questionsPath, `${remaining.join('\n').replace(/\n*$/, '')}\n`);

const summary = computeSummary(root, status);
stampAndWrite(root, status, summary);
process.stdout.write(
  `flushed ${id}; ${summary.open_questions} open (${summary.high_stakes} high-stakes); status.json refreshed\n`,
);
