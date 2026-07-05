#!/usr/bin/env node
// Retrieval for sunoku:read — matching rows/sections only, never whole files.
// JSONL filtering delegates to the shared lib filters (one implementation).
//
//   node query.mjs --tasks ready --decisions open
//   node query.mjs --changelog --since 2026-05-01
//   node query.mjs --prd Problem
//   node query.mjs --research [name-fragment]
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import {
  changelogRows, die, filterDecisions, filterTasks, prdSection, projectRoot, readJsonl, recordPath,
} from '../../../scripts/lib.mjs';

const { values } = parseArgs({
  options: {
    tasks: { type: 'string' },
    decisions: { type: 'string' },
    changelog: { type: 'boolean', default: false },
    since: { type: 'string' },
    prd: { type: 'string' },
    research: { type: 'string' },
  },
  // `--research` with no value: tolerate by pre-scanning argv below.
  strict: false,
});
if (values.since && !/^\d{4}-\d{2}-\d{2}$/.test(values.since)) {
  die(`invalid --since: ${values.since} (YYYY-MM-DD)`);
}

const root = projectRoot();
const out = {};
let asked = false;

if (values.tasks) {
  asked = true;
  out.tasks = filterTasks(readJsonl(recordPath(root, 'tasks.jsonl')), values.tasks);
}
if (values.decisions) {
  asked = true;
  out.decisions = filterDecisions(readJsonl(recordPath(root, 'decisions.jsonl')), values.decisions);
}
if (values.changelog) {
  asked = true;
  const prdPath = recordPath(root, 'PRD.md');
  out.changelog = existsSync(prdPath) ? changelogRows(readFileSync(prdPath, 'utf8'), values.since) : [];
}
if (values.prd) {
  asked = true;
  const prdPath = recordPath(root, 'PRD.md');
  out.prd = existsSync(prdPath) ? prdSection(readFileSync(prdPath, 'utf8'), values.prd) : null;
}
if (values.research !== undefined) {
  asked = true;
  const dir = recordPath(root, 'research');
  const files = existsSync(dir) ? readdirSync(dir).filter((f) => f.endsWith('.md')).sort() : [];
  const fragment = typeof values.research === 'string' ? values.research : '';
  if (fragment) {
    const matches = files.filter((f) => f.includes(fragment));
    out.research_file = matches.length === 1
      ? { name: matches[0], content: readFileSync(join(dir, matches[0]), 'utf8') }
      : null;
    if (matches.length !== 1) out.research = matches;
  } else {
    out.research = files;
  }
}

if (!asked) die('nothing to do: pass --tasks, --decisions, --changelog, --prd, or --research');
process.stdout.write(JSON.stringify(out, null, 2) + '\n');
