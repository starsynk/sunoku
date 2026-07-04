#!/usr/bin/env node
// Apply every reference/MIGRATIONS.md row whose Detect shape matches, in place (canon Record
// migrations: shape-sniffed, idempotent, SILENT lane). Prints one line per applied fix, or
// "record up to date" when nothing matched.
import { copyFileSync, existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  computeSummary, isStub, nowIso, PLUGIN_ROOT, pluginVersion, projectRoot, readRecordFile,
  readStatus, writeFileAtomic, writeStatus,
} from './lib.mjs';

const root = projectRoot();
const status = readStatus(root);
const applied = [];

// --- status.json shapes ---

const statusChanges = {};
if (!('sunokuVersion' in status)) {
  statusChanges.sunokuVersion = pluginVersion();
  applied.push('status.json: sunokuVersion inserted (1.1.0)');
}
if (!('one_liner' in status)) {
  Object.assign(statusChanges, computeSummary(root, status));
  statusChanges.sunokuVersion = pluginVersion();
  applied.push('status.json: summary fields computed (1.3.0)');
}
if (Object.keys(statusChanges).length > 0) {
  writeStatus(root, { ...status, ...statusChanges, updated: nowIso() });
}

// --- TASKS.md shapes ---

const tasksPath = join(root, '.sunoku', 'TASKS.md');
const tasks = readRecordFile(root, 'TASKS.md');
if (tasks !== null && !isStub(tasks)) {
  const template = readFileSync(join(PLUGIN_ROOT, 'reference', 'templates', 'TASKS.md'), 'utf8').split('\n');
  const legendStart = template.findIndex((l) => l.startsWith('> Status:'));
  const legend = [template[legendStart]];
  for (let i = legendStart + 1; i < template.length && template[i].startsWith('> '); i += 1) {
    legend.push(template[i]);
  }

  const lines = tasks.split('\n');
  let changed = false;

  // 1.1.0: task-table header lacks a Status column.
  const missingStatus = lines.some((l) => /^\| ID \| Task \|/.test(l) && !/\|\s*Status\s*\|\s*$/.test(l));
  if (missingStatus) {
    for (let i = 0; i < lines.length; i += 1) {
      if (!/^\| ID \| Task \|/.test(lines[i]) || /\|\s*Status\s*\|\s*$/.test(lines[i])) continue;
      lines[i] = lines[i].replace(/\|\s*$/, '| Status |');
      if (/^\|[\s:|-]+\|\s*$/.test(lines[i + 1] ?? '')) {
        lines[i + 1] = lines[i + 1].replace(/\|\s*$/, '|---|');
      }
      for (let j = i + 2; j < lines.length && /^\|/.test(lines[j]); j += 1) {
        lines[j] = lines[j].replace(/\|\s*$/, '| todo |');
      }
    }
    if (!lines.some((l) => l.startsWith('> Status:'))) {
      const introStart = lines.findIndex((l) => l.startsWith('> '));
      if (introStart !== -1) {
        let introEnd = introStart;
        while (lines[introEnd + 1]?.startsWith('> ')) introEnd += 1;
        lines.splice(introEnd + 1, 0, ...legend);
      }
    }
    if (!lines.some((l) => /^## Blocked\s*$/.test(l))) {
      const blockedStart = template.findIndex((l) => /^## Blocked\s*$/.test(l));
      while (lines[lines.length - 1] === '') lines.pop();
      lines.push('', template[blockedStart], template[blockedStart + 1]);
    }
    changed = true;
    applied.push('TASKS.md: Status column, legend, Blocked section (1.1.0)');
  }

  // 1.2.0: Status legend still references the removed sunoku:work executor.
  const staleLegend = lines.findIndex((l) => /^> Status:.*sunoku:work/.test(l));
  if (staleLegend !== -1) {
    lines.splice(staleLegend, 1, ...legend);
    changed = true;
    applied.push('TASKS.md: executor-agnostic Status legend (1.2.0)');
  }

  if (changed) writeFileAtomic(tasksPath, `${lines.join('\n').replace(/\n*$/, '')}\n`);
}

// --- 1.6.0: union-merge ledgers ---

const gitattributesPath = join(root, '.sunoku', '.gitattributes');
if (!existsSync(gitattributesPath)) {
  copyFileSync(join(PLUGIN_ROOT, 'reference', 'templates', 'sunoku.gitattributes'), gitattributesPath);
  applied.push('.gitattributes: union-merge ledgers created (1.6.0)');
}

if (applied.length === 0) {
  process.stdout.write('record up to date\n');
} else {
  for (const line of applied) process.stdout.write(`record migrated: ${line}\n`);
}
