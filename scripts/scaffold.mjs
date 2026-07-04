#!/usr/bin/env node
// Fresh-init scaffold (sunoku:init step 3): create .sunoku/, copy the template stubs verbatim
// (sentinels intact — only the filling agent removes them), and write the initial canonical
// status.json. Never clobbers: refuses if a record exists; skips any stub already present.
//
//   node scaffold.mjs --product "Name" --origin greenfield|existing [--lifecycle defining]
import { copyFileSync, existsSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import {
  die, LIFECYCLES, nowIso, ORIGINS, PLUGIN_ROOT, pluginVersion, projectRoot, statusPath,
  writeStatus,
} from './lib.mjs';

const { values } = parseArgs({
  options: {
    product: { type: 'string' },
    origin: { type: 'string' },
    lifecycle: { type: 'string' },
  },
});
if (!values.product) die('--product is required');
if (!ORIGINS.includes(values.origin ?? '')) die(`invalid origin: ${values.origin} (${ORIGINS.join('|')})`);
// Default first phase per flow; --lifecycle defining covers the committed-greenfield skip.
const lifecycle = values.lifecycle ?? (values.origin === 'greenfield' ? 'validating' : 'defining');
if (!LIFECYCLES.includes(lifecycle)) die(`invalid lifecycle: ${lifecycle} (${LIFECYCLES.join('|')})`);

const root = projectRoot();
if (existsSync(statusPath(root))) {
  die(`record already exists: ${statusPath(root)} — sunoku:init routes on its lifecycle instead`);
}

const sunoku = join(root, '.sunoku');
const templates = join(PLUGIN_ROOT, 'reference', 'templates');
const created = [];

mkdirSync(join(sunoku, 'research', '.fragments'), { recursive: true });
if (values.origin === 'greenfield') mkdirSync(join(sunoku, 'validation'), { recursive: true });

const copies = [
  ['BRIEF.md', 'BRIEF.md'],
  ['PRD.md', 'PRD.md'],
  ['JOURNAL.md', 'JOURNAL.md'],
  ['QUESTIONS.md', 'QUESTIONS.md'],
  ['EVIDENCE.md', join('research', 'EVIDENCE.md')],
  ['sunoku.gitignore', '.gitignore'],
  ['sunoku.gitattributes', '.gitattributes'],
];
for (const [from, to] of copies) {
  const dest = join(sunoku, to);
  if (existsSync(dest)) continue; // resume safety: never clobber a half-built record
  copyFileSync(join(templates, from), dest);
  created.push(to);
}

const now = nowIso();
writeStatus(root, {
  version: 1,
  sunokuVersion: pluginVersion(),
  product: values.product,
  origin: values.origin,
  lifecycle,
  tracking: false,
  one_liner: values.product,
  open_questions: 0,
  high_stakes: 0,
  last_entry: '',
  last_reconciled_sha: '',
  created: now,
  updated: now,
});
created.push('status.json');

process.stdout.write(`scaffolded .sunoku/ (${values.origin}, lifecycle ${lifecycle}): ${created.join(', ')}\n`);
