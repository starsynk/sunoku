#!/usr/bin/env node
// Fresh-init scaffold: create the minimal v2 record. Refuses if a record exists.
//
//   node scaffold.mjs --product "Name" [--lifecycle validating|defining]
import { existsSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import {
  die, LIFECYCLES, nowIso, projectRoot, statusPath, STUB_SENTINEL, writeFileAtomic, writeStatus,
} from '../../../scripts/lib.mjs';

const { values } = parseArgs({
  options: {
    product: { type: 'string' },
    lifecycle: { type: 'string', default: 'defining' },
  },
});
if (!values.product) die('--product is required');
if (!LIFECYCLES.includes(values.lifecycle) || values.lifecycle === 'live') {
  die(`invalid lifecycle: ${values.lifecycle} (validating|defining)`);
}

const root = projectRoot();
if (existsSync(statusPath(root))) {
  die(`record already exists: ${statusPath(root)} — sunoku:init hands off to sunoku:status instead`);
}

const sunoku = join(root, '.sunoku');
mkdirSync(join(sunoku, 'research'), { recursive: true });

writeFileAtomic(join(sunoku, 'PRD.md'), `${STUB_SENTINEL}\n# PRD — ${values.product}\n`);
writeFileAtomic(join(sunoku, '.gitignore'), '*.tmp-*\n');
writeFileAtomic(join(sunoku, '.gitattributes'), '*.jsonl merge=union\n');

const now = nowIso();
writeStatus(root, {
  product: values.product,
  one_liner: values.product,
  lifecycle: values.lifecycle,
  tracking: false,
  created: now,
  updated: now,
});

process.stdout.write(`scaffolded .sunoku/ (lifecycle ${values.lifecycle}): PRD.md, status.json, research/\n`);
