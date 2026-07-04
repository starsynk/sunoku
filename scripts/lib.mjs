// Shared internals for the record scripts. Not a command — every entry point imports from here
// so the canonical status.json serialization has exactly one implementation.
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

export const PLUGIN_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

export const STUB_SENTINEL = '<!-- sunoku:stub -->';

// Canon statusfile.md: exact key order, one key per line, two-space indent. Hooks grep the
// serialized bytes, so this array is the single source of truth for the file's shape.
export const KEY_ORDER = [
  'version', 'sunokuVersion', 'product', 'origin', 'lifecycle', 'tracking',
  'one_liner', 'open_questions', 'high_stakes', 'last_entry',
  'last_reconciled_sha', 'created', 'updated',
];

export const LIFECYCLES = ['validating', 'defining', 'planning', 'live', 'shelved'];
export const ORIGINS = ['greenfield', 'existing'];

export function projectRoot() {
  return process.env.CLAUDE_PROJECT_DIR || process.cwd();
}

export function statusPath(root) {
  return join(root, '.sunoku', 'status.json');
}

export function readStatus(root) {
  const p = statusPath(root);
  if (!existsSync(p)) die(`no record: ${p} does not exist — run sunoku:init`);
  try {
    return JSON.parse(readFileSync(p, 'utf8'));
  } catch (e) {
    die(`unreadable record: ${p} is not valid JSON (${e.message})`);
  }
}

export function writeStatus(root, status) {
  const ordered = {};
  for (const k of KEY_ORDER) if (k in status) ordered[k] = status[k];
  for (const k of Object.keys(status)) if (!(k in ordered)) ordered[k] = status[k];
  writeFileSync(statusPath(root), JSON.stringify(ordered, null, 2) + '\n');
  return ordered;
}

export function pluginVersion() {
  const p = join(PLUGIN_ROOT, '.claude-plugin', 'plugin.json');
  return JSON.parse(readFileSync(p, 'utf8')).version;
}

// ISO8601 without milliseconds, matching the timestamps skills have always written.
export function nowIso() {
  return new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
}

export function todayLocal() {
  const d = new Date();
  return [
    d.getFullYear(),
    String(d.getMonth() + 1).padStart(2, '0'),
    String(d.getDate()).padStart(2, '0'),
  ].join('-');
}

export function readRecordFile(root, rel) {
  const p = join(root, '.sunoku', rel);
  return existsSync(p) ? readFileSync(p, 'utf8') : null;
}

export function isStub(content) {
  return content !== null && content.split('\n', 1)[0].trim() === STUB_SENTINEL;
}

const ENTRY_HEADER = /^## (\d{4}-\d{2}-\d{2}) — (track|reshape|decision)\s*$/;

export function journalEntries(content) {
  // Returns { header, entries } where header is everything before the first entry and each
  // entry is the whole block from its `## YYYY-MM-DD — <type>` line to the next one.
  const lines = content.split('\n');
  const starts = [];
  lines.forEach((l, i) => { if (ENTRY_HEADER.test(l)) starts.push(i); });
  if (starts.length === 0) return { header: content, entries: [] };
  const header = lines.slice(0, starts[0]).join('\n');
  const entries = starts.map((s, idx) => {
    const end = idx + 1 < starts.length ? starts[idx + 1] : lines.length;
    const m = lines[s].match(ENTRY_HEADER);
    return { date: m[1], type: m[2], text: lines.slice(s, end).join('\n') };
  });
  return { header, entries };
}

// The four denormalized summary fields, recomputed from their source files (canon statusfile.md).
export function computeSummary(root, status) {
  const summary = {};

  const prd = readRecordFile(root, 'PRD.md');
  summary.one_liner = status.product ?? '';
  if (prd !== null && !isStub(prd)) {
    const lines = prd.split('\n');
    const start = lines.findIndex((l) => /^## Problem\b/.test(l));
    if (start !== -1) {
      const body = [];
      for (let i = start + 1; i < lines.length && !/^#{1,6} /.test(lines[i]); i += 1) body.push(lines[i]);
      const paragraph = body.join('\n').split(/\n\s*\n/)
        .map((p) => p.replace(/\s+/g, ' ').trim())
        .find((p) => p && !p.startsWith('>') && !p.startsWith('<!--'));
      if (paragraph) {
        const sentence = paragraph.match(/^(.*?\.)(\s|$)/);
        summary.one_liner = sentence ? sentence[1] : paragraph;
      }
    }
  }

  const questions = readRecordFile(root, 'QUESTIONS.md');
  summary.open_questions = 0;
  summary.high_stakes = 0;
  if (questions !== null && !isStub(questions)) {
    for (const line of questions.split('\n')) {
      if (/^## .*status: open\)/.test(line)) {
        summary.open_questions += 1;
        if (/stakes: high, status: open\)/.test(line)) summary.high_stakes += 1;
      }
    }
  }

  const journal = readRecordFile(root, 'JOURNAL.md');
  summary.last_entry = '';
  if (journal !== null && !isStub(journal)) {
    const { entries } = journalEntries(journal);
    const last = entries[entries.length - 1];
    if (last) {
      const what = last.text.match(/^\*\*What:\*\* (.*)$/m);
      summary.last_entry = `${last.date} — ${last.type} — ${what ? what[1].trim() : ''}`.trimEnd();
    }
  }

  return summary;
}

// Every status.json write restamps `updated` and `sunokuVersion` (canon statusfile.md).
export function stampAndWrite(root, status, changes = {}) {
  const next = { ...status, ...changes, sunokuVersion: pluginVersion(), updated: nowIso() };
  return writeStatus(root, next);
}

export function git(root, args) {
  try {
    return execFileSync('git', ['-C', root, ...args], { encoding: 'utf8' }).trim();
  } catch {
    return null;
  }
}

export function die(message) {
  process.stderr.write(`${message}\n`);
  process.exit(1);
}
