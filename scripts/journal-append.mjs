#!/usr/bin/env node
// Append one journal entry, then handle everything mechanical around it: stub-sentinel
// removal, the 30KB→15KB rollover into .sunoku/journal/<year>.md, and the status.json
// summary refresh canon requires on every record write.
//
//   node journal-append.mjs --type track --what "..." --why "..." --refs "abc123"
// Optional: --date YYYY-MM-DD (defaults to today).
import { existsSync, mkdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import {
  computeSummary, die, journalEntries, projectRoot, readStatus, stampAndWrite, STUB_SENTINEL,
  todayLocal, writeFileAtomic,
} from './lib.mjs';

const TYPES = ['track', 'reshape', 'decision'];
const ROLLOVER_AT = 30 * 1024;
const ROLLOVER_TO = 15 * 1024;
const OLDER_LINE = '> Older entries: .sunoku/journal/';

const { values } = parseArgs({
  options: {
    type: { type: 'string' },
    what: { type: 'string' },
    why: { type: 'string' },
    refs: { type: 'string' },
    date: { type: 'string', default: todayLocal() },
  },
});

for (const field of ['type', 'what', 'why', 'refs']) {
  if (!values[field]) die(`--${field} is required`);
}
// Entry fields are single-line by format (`**What:** ...`); collapse any stray newlines so a
// multi-line argument can never break the machine-scanned entry shape.
for (const field of ['what', 'why', 'refs']) {
  values[field] = values[field].replace(/\s+/g, ' ').trim();
}
if (!TYPES.includes(values.type)) die(`invalid type: ${values.type} (${TYPES.join('|')})`);
if (!/^\d{4}-\d{2}-\d{2}$/.test(values.date)) die(`invalid date: ${values.date} (YYYY-MM-DD)`);

const root = projectRoot();
const status = readStatus(root);
const journalPath = join(root, '.sunoku', 'JOURNAL.md');
if (!existsSync(journalPath)) die(`no journal: ${journalPath} does not exist — scaffold the record first`);

let content = readFileSync(journalPath, 'utf8');

// First real entry deletes the stub sentinel; the file is append-only from here on.
if (content.split('\n', 1)[0].trim() === STUB_SENTINEL) {
  content = content.split('\n').slice(1).join('\n');
}

const entry = `## ${values.date} — ${values.type}\n**What:** ${values.what}\n**Why:** ${values.why}\n**Refs:** ${values.refs}\n`;
content = `${content.replace(/\n*$/, '')}\n\n${entry}`;
writeFileAtomic(journalPath, content);

let rolled = 0;
if (statSync(journalPath).size > ROLLOVER_AT) {
  const { header, entries } = journalEntries(readFileSync(journalPath, 'utf8'));
  let keptHeader = header.replace(/\n*$/, '');
  if (!keptHeader.includes(OLDER_LINE)) keptHeader += `\n${OLDER_LINE}`;

  const archiveDir = join(root, '.sunoku', 'journal');
  mkdirSync(archiveDir, { recursive: true });

  // Move oldest whole entries (never split one) until the live file is small enough,
  // always keeping at least the entry just written.
  const kept = [...entries];
  const sizeOf = () => Buffer.byteLength(`${keptHeader}\n\n${kept.map((e) => e.text.replace(/\n*$/, '')).join('\n\n')}\n`);
  while (kept.length > 1 && sizeOf() > ROLLOVER_TO) {
    const oldest = kept.shift();
    const archivePath = join(archiveDir, `${oldest.date.slice(0, 4)}.md`);
    const block = `${oldest.text.replace(/\n*$/, '')}\n`;
    writeFileAtomic(archivePath, existsSync(archivePath)
      ? `${readFileSync(archivePath, 'utf8').replace(/\n*$/, '')}\n\n${block}`
      : block);
    rolled += 1;
  }
  writeFileAtomic(journalPath, `${keptHeader}\n\n${kept.map((e) => e.text.replace(/\n*$/, '')).join('\n\n')}\n`);
}

// Canon statusfile.md: every write that changes a summary source refreshes the index.
stampAndWrite(root, status, computeSummary(root, status));

const size = statSync(journalPath).size;
process.stdout.write(
  `appended ## ${values.date} — ${values.type}; journal ${size} bytes` +
  (rolled ? `; rolled ${rolled} entries to .sunoku/journal/` : '') +
  '; status.json refreshed\n',
);
