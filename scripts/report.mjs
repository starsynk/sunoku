#!/usr/bin/env node
// One-shot record report for sunoku:status: every fact the step-2 report needs, as one JSON
// object on stdout. Read-only — never writes the record.
//
//   node report.mjs [--since YYYY-MM-DD] [--tag <tag>]   # either adds journal_matches
import { existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import {
  allJournalEntries, computeSummary, die, entryField, git, isStub, journalEntries, projectRoot,
  readRecordFile, readStatus, taskTables,
} from './lib.mjs';

const VALIDATION_STALE_DAYS = 180;

const { values } = parseArgs({
  options: { since: { type: 'string' }, tag: { type: 'string' } },
});
if (values.since && !/^\d{4}-\d{2}-\d{2}$/.test(values.since)) {
  die(`invalid --since: ${values.since} (YYYY-MM-DD)`);
}

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
report.questions_aging = [];
if (questions !== null && !isStub(questions)) {
  const qlines = questions.split('\n');
  for (let i = 0; i < qlines.length; i += 1) {
    const m = qlines[i].match(/^## (.+?)\s+\(stakes: (high|normal), status: open\)/);
    if (!m) continue;
    if (m[2] === 'high') report.high_stakes_titles.push(m[1]);
    // Aging needs an **Opened:** line inside the block; undated entries just don't age.
    for (let j = i + 1; j < qlines.length && !/^## /.test(qlines[j]); j += 1) {
      const o = qlines[j].match(/^\*\*Opened:\*\* (\d{4}-\d{2}-\d{2})/);
      if (!o) continue;
      const id = m[1].match(/^(Q-\d+)/)?.[1] ?? m[1];
      report.questions_aging.push({
        id,
        stakes: m[2],
        opened: o[1],
        days_open: Math.floor((Date.now() - new Date(o[1]).getTime()) / (24 * 60 * 60 * 1000)),
      });
      break;
    }
  }
  report.questions_aging.sort((a, b) => b.days_open - a.days_open);
}

report.drift = null;
report.dirty = null;
report.baseline_lost = false;
if (git(root, ['rev-parse', '--git-dir']) !== null) {
  const sha = status.last_reconciled_sha ?? '';
  // Rebase/squash/force-push can erase the reconcile baseline — flag it instead of a bogus 0.
  report.baseline_lost = Boolean(sha) && git(root, ['cat-file', '-e', `${sha}^{commit}`]) === null;
  // Empty sha: ""..HEAD is not a valid range — all history counts as unreconciled.
  const count = report.baseline_lost
    ? null
    : sha
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

// Evidence ages: past ~6 months the go decision deserves a fresh look (re-validate lane).
report.validation_stale = null;
if (report.validation_reports.length > 0) {
  const newest = report.validation_reports[report.validation_reports.length - 1];
  const dated = newest.match(/\d{4}-\d{2}(-\d{2})?/);
  if (dated) {
    const when = new Date(dated[1] ? dated[0] : `${dated[0]}-01`).getTime();
    report.validation_stale = Date.now() - when > VALIDATION_STALE_DAYS * 24 * 60 * 60 * 1000;
  }
}

const roadmap = readRecordFile(root, 'ROADMAP.md');
report.roadmap = roadmap === null ? 'absent' : isStub(roadmap) ? 'stub' : 'present';

const tasksFile = readRecordFile(root, 'TASKS.md');
report.tasks = null;
report.milestones = null;
if (tasksFile !== null && !isStub(tasksFile)) {
  const { counts, milestones } = taskTables(tasksFile);
  report.tasks = counts;
  report.milestones = milestones;
}

const journal = readRecordFile(root, 'JOURNAL.md');
report.journal_recent = [];
if (journal !== null && !isStub(journal)) {
  report.journal_recent = journalEntries(journal).entries.slice(-5).map((e) => `${e.date} — ${e.type}`);
}

// Windowed/tagged history scan across archives + live journal, only when asked.
if (values.since || values.tag) {
  report.journal_matches = allJournalEntries(root)
    .filter((e) => !values.since || e.date >= values.since)
    .filter((e) => {
      if (!values.tag) return true;
      const tags = entryField(e.text, 'Tags').split(',').map((t) => t.trim().toLowerCase()).filter(Boolean);
      return tags.includes(values.tag.toLowerCase());
    })
    .map((e) => ({
      date: e.date,
      type: e.type,
      what: entryField(e.text, 'What'),
      tags: entryField(e.text, 'Tags'),
      by: entryField(e.text, 'By'),
    }));
}

// Advisory freshness check: does the denormalized index match its sources right now?
const live = computeSummary(root, status);
report.summary_stale = ['one_liner', 'open_questions', 'high_stakes', 'last_entry']
  .some((k) => k in status && status[k] !== live[k]);

process.stdout.write(JSON.stringify(report, null, 2) + '\n');
