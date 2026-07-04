#!/usr/bin/env node
// Assemble a stakeholder digest from the record: what the product is, where it stands,
// what changed in the window, what's open. Purely mechanical extraction — a derived,
// regenerate-anytime snapshot under .sunoku/digest/; the record stays the truth.
//
//   node digest.mjs [--days 30]
import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import {
  allJournalEntries, die, entryField, isStub, localDate, prdProblemParagraph, projectRoot,
  readRecordFile, readStatus, taskTables, todayLocal, writeFileAtomic,
} from './lib.mjs';

const { values } = parseArgs({ options: { days: { type: 'string', default: '30' } } });
const days = Number(values.days);
if (!Number.isInteger(days) || days < 1) die(`invalid --days: ${values.days}`);

const root = projectRoot();
const status = readStatus(root);
const today = todayLocal();
const cutoff = localDate(new Date(Date.now() - days * 24 * 60 * 60 * 1000));

const lines = [
  `# ${status.product} — digest — ${today}`,
  '',
  '> Generated from the Sunoku record (.sunoku/). Derived snapshot — regenerate anytime;',
  '> the journal and PRD stay the source of truth.',
  '',
  '## What this is',
  '',
  prdProblemParagraph(root) ?? status.one_liner ?? status.product,
  '',
  '## Where it stands',
  '',
  `- Lifecycle: ${status.lifecycle}, tracking ${status.tracking ? 'on' : 'off'}.`,
];

if (status.last_entry) lines.push(`- Last journal entry: ${status.last_entry}`);

const tasksFile = readRecordFile(root, 'TASKS.md');
if (tasksFile !== null && !isStub(tasksFile)) {
  const { milestones } = taskTables(tasksFile);
  for (const m of milestones) lines.push(`- ${m.name}: ${m.done}/${m.total} done.`);
} else {
  lines.push('- No roadmap in the record (planning elsewhere is a first-class choice).');
}

lines.push('', `## Changed in the last ${days} days`, '');
const recent = allJournalEntries(root).filter((e) => e.date >= cutoff);
if (recent.length === 0) {
  lines.push('No story-changing entries in the window — Sunoku stays silent on routine work by design.');
} else {
  for (const e of recent) {
    const why = entryField(e.text, 'Why');
    lines.push(`- ${e.date} (${e.type}): ${entryField(e.text, 'What')}${why ? ` — ${why}` : ''}`);
  }
}

lines.push('', '## Open questions', '');
const questions = readRecordFile(root, 'QUESTIONS.md');
const titles = [];
if (questions !== null && !isStub(questions)) {
  for (const line of questions.split('\n')) {
    const m = line.match(/^## (Q-\d+ — .+?)\s+\(stakes: (high|normal), status: open\)/);
    if (m) titles.push(`- ${m[1]} (${m[2]} stakes)`);
  }
}
lines.push(...(titles.length ? titles : ['None.']));

const digestDir = join(root, '.sunoku', 'digest');
mkdirSync(digestDir, { recursive: true });
const outPath = join(digestDir, `${today}.md`);
writeFileAtomic(outPath, `${lines.join('\n')}\n`);
process.stdout.write(`wrote .sunoku/digest/${today}.md (${days}-day window, ${recent.length} entr${recent.length === 1 ? 'y' : 'ies'})\n`);
