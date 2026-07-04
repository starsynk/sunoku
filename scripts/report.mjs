#!/usr/bin/env node
// One-shot record report for sunoku:status: every fact the step-2 report needs, as one JSON
// object on stdout. Read-only — never writes the record.
import { existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import {
  computeSummary, die, git, isStub, journalEntries, projectRoot, readRecordFile, readStatus,
} from './lib.mjs';

const root = projectRoot();
const status = readStatus(root);

const report = {
  product: status.product ?? null,
  origin: status.origin ?? null,
  lifecycle: status.lifecycle ?? null,
  tracking: status.tracking ?? null,
  one_liner: status.one_liner ?? null,
  last_entry: status.last_entry ?? null,
  open_questions: status.open_questions ?? null,
  high_stakes: status.high_stakes ?? null,
  // Pre-1.3.0 record — the skill should run migrate.mjs before reporting.
  summary_fields_missing: !('one_liner' in status),
};

const questions = readRecordFile(root, 'QUESTIONS.md');
report.high_stakes_titles = [];
if (questions !== null && !isStub(questions)) {
  for (const line of questions.split('\n')) {
    const m = line.match(/^## (.+?)\s+\(stakes: high, status: open\)/);
    if (m) report.high_stakes_titles.push(m[1]);
  }
}

report.drift = null;
report.dirty = null;
if (git(root, ['rev-parse', '--git-dir']) !== null) {
  const sha = status.last_reconciled_sha ?? '';
  // Empty sha: ""..HEAD is not a valid range — all history counts as unreconciled.
  const count = sha
    ? git(root, ['rev-list', '--count', `${sha}..HEAD`])
    : git(root, ['rev-list', '--count', 'HEAD']);
  report.drift = count === null ? null : Number(count);
  // Record-only dirt never warrants a reconcile offer — ignore .sunoku/ paths.
  const porcelain = git(root, ['status', '--porcelain']);
  report.dirty = porcelain === null
    ? null
    : porcelain.split('\n').some((l) => l && !l.slice(3).startsWith('.sunoku'));
}

const validationDir = join(root, '.sunoku', 'validation');
report.validation_reports = existsSync(validationDir)
  ? readdirSync(validationDir).filter((f) => /\d{4}-\d{2}/.test(f)).sort()
  : [];

const roadmap = readRecordFile(root, 'ROADMAP.md');
report.roadmap = roadmap === null ? 'absent' : isStub(roadmap) ? 'stub' : 'present';

const tasksFile = readRecordFile(root, 'TASKS.md');
report.tasks = null;
if (tasksFile !== null && !isStub(tasksFile)) {
  const counts = { todo: 0, doing: 0, done: 0, blocked: 0 };
  for (const line of tasksFile.split('\n')) {
    if (!line.startsWith('|')) continue;
    const cells = line.split('|').map((c) => c.trim()).filter(Boolean);
    const last = cells[cells.length - 1];
    if (last in counts) counts[last] += 1;
  }
  report.tasks = counts;
}

const journal = readRecordFile(root, 'JOURNAL.md');
report.journal_recent = [];
if (journal !== null && !isStub(journal)) {
  report.journal_recent = journalEntries(journal).entries.slice(-5).map((e) => `${e.date} — ${e.type}`);
}

// Advisory freshness check: does the denormalized index match its sources right now?
const live = computeSummary(root, status);
report.summary_stale = ['one_liner', 'open_questions', 'high_stakes', 'last_entry']
  .some((k) => k in status && status[k] !== live[k]);

process.stdout.write(JSON.stringify(report, null, 2) + '\n');
