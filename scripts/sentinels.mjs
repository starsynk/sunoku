#!/usr/bin/env node
// Done-map for resume (canon sentinels-resume): per artifact — done | stub | empty |
// empty-ledger | missing — as one JSON object. An artifact is done when it exists, is
// non-empty, and the stub sentinel is absent; ledgers additionally need >=1 real entry.
import { existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { isStub, journalEntries, projectRoot, readRecordFile } from './lib.mjs';

const ARTIFACTS = [
  'BRIEF.md', 'PRD.md', 'JOURNAL.md', 'QUESTIONS.md', 'research/EVIDENCE.md',
  'ROADMAP.md', 'TASKS.md',
];

const root = projectRoot();
const map = {};

for (const rel of ARTIFACTS) {
  const content = readRecordFile(root, rel);
  if (content === null) { map[rel] = 'missing'; continue; }
  if (isStub(content)) { map[rel] = 'stub'; continue; }
  if (!content.trim()) { map[rel] = 'empty'; continue; }
  if (rel === 'JOURNAL.md') {
    map[rel] = journalEntries(content).entries.length > 0 ? 'done' : 'empty-ledger';
    continue;
  }
  if (rel === 'research/EVIDENCE.md') {
    // A real ledger row is a table line beyond the header and |---| separator.
    const rows = content.split('\n').filter((l) => /^\|/.test(l) && !/^\|[\s-|]*\|$/.test(l));
    map[rel] = rows.length > 1 ? 'done' : 'empty-ledger';
    continue;
  }
  map[rel] = 'done';
}

map['status.json'] = existsSync(join(root, '.sunoku', 'status.json')) ? 'done' : 'missing';

const validationDir = join(root, '.sunoku', 'validation');
map['validation/'] = existsSync(validationDir)
  ? (readdirSync(validationDir).length > 0 ? 'done' : 'empty')
  : 'missing';

process.stdout.write(JSON.stringify(map, null, 2) + '\n');
