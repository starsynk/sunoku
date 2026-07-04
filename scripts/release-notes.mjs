#!/usr/bin/env node
// Draft human release notes from the journal: one markdown bullet per entry in the window,
// oldest first. Read-only; prints to stdout for pasting into a changelog or announcement.
//
//   node release-notes.mjs --since YYYY-MM-DD [--tag <tag>]
import { parseArgs } from 'node:util';
import {
  allJournalEntries, die, entryField, projectRoot, readStatus,
} from './lib.mjs';

const { values } = parseArgs({
  options: { since: { type: 'string' }, tag: { type: 'string' } },
});
if (!values.since) die('--since is required (YYYY-MM-DD)');
if (!/^\d{4}-\d{2}-\d{2}$/.test(values.since)) die(`invalid --since: ${values.since} (YYYY-MM-DD)`);

const root = projectRoot();
const status = readStatus(root);

const entries = allJournalEntries(root)
  .filter((e) => e.date >= values.since)
  .filter((e) => {
    if (!values.tag) return true;
    const tags = entryField(e.text, 'Tags').split(',').map((t) => t.trim().toLowerCase()).filter(Boolean);
    return tags.includes(values.tag.toLowerCase());
  });

const lines = [`# ${status.product} — changes since ${values.since}`, ''];
if (entries.length === 0) {
  lines.push('No story-changing entries in the window — Sunoku stays silent on routine work by design.');
} else {
  for (const e of entries) {
    const why = entryField(e.text, 'Why');
    const tags = entryField(e.text, 'Tags');
    lines.push(`- **${e.date}** (${e.type}) ${entryField(e.text, 'What')}${why ? ` — ${why}` : ''}${tags ? ` _[${tags}]_` : ''}`);
  }
}
process.stdout.write(`${lines.join('\n')}\n`);
