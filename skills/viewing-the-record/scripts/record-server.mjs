#!/usr/bin/env node
// Serves the record live at http://127.0.0.1:<port>/?key=… — the page reloads
// itself (SSE) whenever tasks.jsonl / decisions.jsonl / status.json change.
// READ-ONLY over the record. Replaces the record.html snapshot.
//
//   node record-server.mjs [--no-open]     launcher: reuse or start, print info JSON
//   (--serve is internal: runs the actual server in the detached child)
import { execFile, spawn } from 'node:child_process';
import { createHash, randomBytes, timingSafeEqual } from 'node:crypto';
import { existsSync, readFileSync, unlinkSync, watch, writeFileSync } from 'node:fs';
import http from 'node:http';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';
import { die, projectRoot, readStatus, recordPath, statusPath } from '../../../scripts/lib.mjs';
import { renderHtml, renderNoRecord } from './render.mjs';

const { values } = parseArgs({ options: { 'no-open': { type: 'boolean' }, serve: { type: 'boolean' } } });

const root = projectRoot();
const IDLE_MS = Number(process.env.SUNOKU_VIEWER_IDLE_MS) || 15 * 60 * 1000;
const infoPath = join(tmpdir(),
  `sunoku-record-server-${createHash('sha256').update(root).digest('hex').slice(0, 12)}.json`);

function openBrowser(url) {
  if (values['no-open'] || process.env.CI) return;
  const opener = process.platform === 'darwin' ? ['open', [url]]
    : process.platform === 'win32' ? ['cmd', ['/c', 'start', '', url]]
    : ['xdg-open', [url]];
  execFile(opener[0], opener[1], () => {}).unref();
}

function liveInfo() {
  try {
    const info = JSON.parse(readFileSync(infoPath, 'utf8'));
    process.kill(info.pid, 0); // throws if dead
    return info.root === root ? info : null;
  } catch {
    return null;
  }
}

if (!values.serve) {
  // Launcher. One server per project: reuse a live one, else spawn and wait for it.
  readStatus(root); // dies if no record
  const existing = liveInfo();
  if (existing) {
    process.stdout.write(JSON.stringify({ ...existing, reused: true }) + '\n');
    openBrowser(existing.url);
    process.exit(0);
  }
  const child = spawn(process.execPath, [fileURLToPath(import.meta.url), '--serve'],
    { detached: true, stdio: 'ignore', env: process.env });
  child.unref();
  const deadline = Date.now() + 5000;
  const poll = () => {
    const info = liveInfo();
    if (info && info.pid === child.pid) {
      process.stdout.write(JSON.stringify(info) + '\n');
      openBrowser(info.url);
      process.exit(0);
    }
    if (Date.now() > deadline) die('record server failed to start');
    setTimeout(poll, 50);
  };
  poll();
} else {
  // Server (detached child).
  const key = randomBytes(16).toString('hex');
  const keyBuf = Buffer.from(key);
  const keyOk = (v) => {
    const b = Buffer.from(String(v ?? ''));
    return b.length === keyBuf.length && timingSafeEqual(b, keyBuf);
  };
  let lastActivity = Date.now();
  const sseClients = new Set();

  // lib's readStatus/readJsonl die() on missing/corrupt files — fatal for a
  // long-lived server. Tolerant read instead: any failure renders the
  // no-record page rather than exiting.
  function readRecord() {
    try {
      const status = JSON.parse(readFileSync(statusPath(root), 'utf8'));
      const jsonl = (p) => !existsSync(p) ? [] : readFileSync(p, 'utf8')
        .split('\n').filter((l) => l.trim()).map((l) => JSON.parse(l));
      return {
        status,
        tasks: jsonl(recordPath(root, 'tasks.jsonl')),
        decisions: jsonl(recordPath(root, 'decisions.jsonl')),
      };
    } catch {
      return null;
    }
  }

  const WATCHED = new Set(['tasks.jsonl', 'decisions.jsonl', 'status.json']);
  let watcher = null;
  let debounce = null;
  function armWatch() {
    if (watcher) return;
    try {
      watcher = watch(recordPath(root), (event, file) => {
        if (!file || !WATCHED.has(file)) return;
        clearTimeout(debounce);
        debounce = setTimeout(() => {
          for (const c of sseClients) c.write('data: change\n\n');
        }, 150);
      });
      watcher.on('error', () => { watcher.close(); watcher = null; });
    } catch {
      watcher = null; // .sunoku gone; re-armed on the next request
    }
  }

  const server = http.createServer((req, res) => {
    lastActivity = Date.now();
    const url = new URL(req.url, 'http://127.0.0.1');
    if (!keyOk(url.searchParams.get('key'))) {
      res.writeHead(403, { 'content-type': 'text/plain' });
      res.end('forbidden');
      return;
    }
    if (url.pathname === '/') {
      armWatch();
      const record = readRecord();
      const html = record
        ? renderHtml(record.status, record.tasks, record.decisions)
        : renderNoRecord(recordPath(root));
      res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
      res.end(html);
    } else if (url.pathname === '/events') {
      res.writeHead(200, {
        'content-type': 'text/event-stream',
        'cache-control': 'no-cache',
        connection: 'keep-alive',
      });
      res.write(': connected\n\n');
      sseClients.add(res);
      req.on('close', () => sseClients.delete(res));
    } else {
      res.writeHead(404, { 'content-type': 'text/plain' });
      res.end('not found');
    }
  });

  function shutdown() {
    try { unlinkSync(infoPath); } catch { /* already gone */ }
    process.exit(0);
  }

  // Idle watchdog: an open SSE connection counts as activity.
  setInterval(() => {
    if (sseClients.size > 0) { lastActivity = Date.now(); return; }
    if (Date.now() - lastActivity > IDLE_MS) shutdown();
  }, Math.min(IDLE_MS, 60000));

  // Heartbeat keeps proxies/browsers from closing quiet SSE sockets.
  setInterval(() => {
    for (const c of sseClients) c.write(': hb\n\n');
  }, 30000).unref();

  server.listen(0, '127.0.0.1', () => {
    const { port } = server.address();
    const info = {
      pid: process.pid, port, key, root,
      url: `http://127.0.0.1:${port}/?key=${key}`,
      started: new Date().toISOString(),
    };
    writeFileSync(infoPath, JSON.stringify(info) + '\n');
    armWatch();
  });
}
