#!/usr/bin/env node
// The only sanctioned way to write .sunoku/status.json. Restamps `updated`, never `created`.
//
//   node status-write.mjs --set lifecycle=live --set tracking=true
//   node status-write.mjs --touch   (restamp `updated` only — marks the record as freshly reviewed)
import { parseArgs } from 'node:util';
import { die, LIFECYCLES, projectRoot, readStatus, stampAndWrite } from './lib.mjs';

const { values } = parseArgs({
  options: {
    set: { type: 'string', multiple: true, default: [] },
    touch: { type: 'boolean', default: false },
  },
});
if (values.set.length === 0 && !values.touch) die('nothing to do: pass --set key=value or --touch');

const SETTABLE = {
  product: (v) => v,
  one_liner: (v) => v,
  lifecycle: (v) => (LIFECYCLES.includes(v) ? v : die(`invalid lifecycle: ${v} (${LIFECYCLES.join('|')})`)),
  tracking: (v) => (v === 'true' || v === 'false' ? v === 'true' : die(`invalid tracking: ${v} (true|false)`)),
};

const root = projectRoot();
const status = readStatus(root);
const changes = {};
for (const pair of values.set) {
  const eq = pair.indexOf('=');
  if (eq === -1) die(`--set expects key=value, got: ${pair}`);
  const key = pair.slice(0, eq);
  const coerce = SETTABLE[key];
  if (!coerce) die(`not a settable key: ${key} (${Object.keys(SETTABLE).join(', ')})`);
  changes[key] = coerce(pair.slice(eq + 1));
}

process.stdout.write(JSON.stringify(stampAndWrite(root, status, changes), null, 2) + '\n');
