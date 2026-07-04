#!/usr/bin/env node
// The only sanctioned way to write .sunoku/status.json. Always restamps `updated` and
// `sunokuVersion`; never touches `created`. Serialization is canonical byte-for-byte
// (hooks grep exact patterns like `"tracking": true`).
//
//   node status-write.mjs --set lifecycle=live --set tracking=true
//   node status-write.mjs --refresh            # recompute the four summary fields
//   node status-write.mjs --sha-head           # last_reconciled_sha = git HEAD ("" if no commits)
// Flags combine; the result is printed to stdout.
import { parseArgs } from 'node:util';
import {
  computeSummary, die, git, LIFECYCLES, ORIGINS, projectRoot, readStatus, stampAndWrite,
} from './lib.mjs';

const { values } = parseArgs({
  options: {
    set: { type: 'string', multiple: true, default: [] },
    refresh: { type: 'boolean', default: false },
    'sha-head': { type: 'boolean', default: false },
  },
});

const SETTABLE = {
  product: (v) => v,
  origin: (v) => (ORIGINS.includes(v) ? v : die(`invalid origin: ${v} (${ORIGINS.join('|')})`)),
  lifecycle: (v) => (LIFECYCLES.includes(v) ? v : die(`invalid lifecycle: ${v} (${LIFECYCLES.join('|')})`)),
  tracking: (v) => (v === 'true' || v === 'false' ? v === 'true' : die(`invalid tracking: ${v} (true|false)`)),
  one_liner: (v) => v,
  open_questions: toCount,
  high_stakes: toCount,
  last_entry: (v) => v,
  last_reconciled_sha: (v) => v,
};

function toCount(v) {
  const n = Number(v);
  if (!Number.isInteger(n) || n < 0) die(`invalid count: ${v}`);
  return n;
}

const root = projectRoot();
const status = readStatus(root);
const changes = {};

for (const pair of values.set) {
  const eq = pair.indexOf('=');
  if (eq === -1) die(`--set expects key=value, got: ${pair}`);
  const key = pair.slice(0, eq);
  const coerce = SETTABLE[key];
  if (!coerce) die(`not a settable status.json key: ${key} (${Object.keys(SETTABLE).join(', ')})`);
  changes[key] = coerce(pair.slice(eq + 1));
}

if (values.refresh) Object.assign(changes, computeSummary(root, { ...status, ...changes }));

if (values['sha-head']) changes.last_reconciled_sha = git(root, ['rev-parse', 'HEAD']) ?? '';

const written = stampAndWrite(root, status, changes);
process.stdout.write(JSON.stringify(written, null, 2) + '\n');
