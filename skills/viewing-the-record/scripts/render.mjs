// Pure renderer for the live record view. No file I/O — record-server.mjs reads
// the record and calls these per request.

// JSON inlined into a <script> block: escape "<" so "</script>" in data can't break out.
const inline = (v) => JSON.stringify(v).replace(/</g, '\\u003c');
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

// Reload the page whenever the server signals a record change; the session key
// rides along from the page URL.
const LIVE_SCRIPT = "new EventSource('/events' + location.search).onmessage = () => location.reload();";

export function renderNoRecord(path) {
  return `<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Sunoku record</title></head>
<body style="font:15px/1.5 system-ui,sans-serif;padding:2rem">
<p>No record at <code>${esc(path)}</code>. It may have been moved or deleted;
this page reloads automatically if it comes back.</p>
<script>${LIVE_SCRIPT}</script>
</body>
</html>
`;
}

export function renderHtml(status, tasks, decisions) {
  const generated = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(status.product)} — Sunoku record</title>
<style>
  :root { --fg:#1a1a1a; --muted:#6b7280; --bg:#fff; --card:#f6f7f8; --line:#e5e7eb;
          --todo:#6b7280; --doing:#2563eb; --done:#16a34a; --blocked:#dc2626;
          --high:#dc2626; --low:#6b7280; --open:#b45309; }
  @media (prefers-color-scheme: dark) {
    :root { --fg:#e5e7eb; --muted:#9ca3af; --bg:#111827; --card:#1f2937; --line:#374151; }
  }
  body { margin:0 auto; max-width:60rem; padding:1.5rem; font:15px/1.5 system-ui,sans-serif;
         color:var(--fg); background:var(--bg); }
  h1 { font-size:1.4rem; } h2 { font-size:1.1rem; margin-top:2rem; }
  .muted { color:var(--muted); }
  .milestone { border:1px solid var(--line); border-radius:8px; padding:1rem; margin:1rem 0; }
  .epic { margin:.75rem 0 .75rem 1rem; }
  .task { background:var(--card); border-radius:6px; padding:.6rem .8rem; margin:.4rem 0 .4rem 1rem; }
  .task p { margin:.3rem 0 0; }
  .badge { display:inline-block; padding:0 .5em; border-radius:999px; color:#fff;
           font-size:.75rem; line-height:1.6; margin-left:.4em; vertical-align:middle; }
  .chip { display:inline-block; border:1px solid var(--line); border-radius:4px;
          padding:0 .4em; font-size:.75rem; margin-left:.3em; color:var(--muted); }
  .s-todo{background:var(--todo)} .s-doing{background:var(--doing)}
  .s-done{background:var(--done)} .s-blocked{background:var(--blocked)}
  .s-open{background:var(--open)} .s-resolved{background:var(--done)}
  .k-high{background:var(--high)} .k-low{background:var(--low)}
  .filters button { margin-right:.4em; padding:.2em .7em; border:1px solid var(--line);
                    border-radius:6px; background:var(--card); color:var(--fg); cursor:pointer; }
  .filters button.on { border-color:var(--doing); font-weight:600; }
  .decision { background:var(--card); border-radius:6px; padding:.6rem .8rem; margin:.4rem 0; }
  footer { margin-top:2rem; font-size:.8rem; color:var(--muted); }
</style>
</head>
<body>
<h1>${esc(status.product)} <span class="muted">— ${esc(status.one_liner ?? '')}</span></h1>

<h2>Tasks</h2>
<div class="filters" id="task-filters"></div>
<div id="tasks"></div>

<section id="decisions-section" hidden>
<h2>Decisions</h2>
<div class="filters" id="decision-filters"></div>
<div id="decisions"></div>
</section>

<footer>Live view rendered ${generated} — reloads when the record changes. Read-only;
flip status via <code>tasks.mjs</code>. The server stops itself ~15 min after the last
tab closes.</footer>

<script>
const ROWS = ${inline(tasks)};
const DECISIONS = ${inline(decisions)};

const esc = s => String(s ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const badge = (v, kind) => '<span class="badge ' + kind + '-' + esc(v) + '">' + esc(v) + '</span>';

function taskHtml(t) {
  const deps = (t.deps ?? []).map(d => '<span class="chip">' + esc(d) + '</span>').join('');
  return '<div class="task" data-status="' + esc(t.status) + '">'
    + '<strong>' + esc(t.id) + '</strong> ' + esc(t.title) + badge(t.status, 's')
    + '<span class="chip">' + esc(t.discipline ?? '') + '</span>'
    + '<span class="chip">' + esc(t.size ?? '') + '</span>'
    + (t.spike ? '<span class="chip">spike</span>' : '') + deps
    + (t.description ? '<p class="muted">' + esc(t.description) + '</p>' : '')
    + '</div>';
}

function render() {
  const milestones = ROWS.filter(r => r.type === 'milestone');
  const epics = ROWS.filter(r => r.type === 'epic');
  const tasks = ROWS.filter(r => r.type === 'task');
  const used = new Set();
  let out = '';
  for (const m of milestones) {
    out += '<div class="milestone"><strong>' + esc(m.id) + '</strong> ' + esc(m.title);
    for (const e of epics.filter(e => e.milestone === m.id)) {
      out += '<div class="epic"><strong>' + esc(e.id) + '</strong> ' + esc(e.title);
      for (const t of tasks.filter(t => t.epic === e.id)) { used.add(t.id); out += taskHtml(t); }
      out += '</div>';
    }
    out += '</div>';
  }
  const loose = tasks.filter(t => !used.has(t.id));
  if (loose.length) out += '<div class="milestone">Ungrouped' + loose.map(taskHtml).join('') + '</div>';
  document.getElementById('tasks').innerHTML = out || '<p class="muted">No tasks yet.</p>';
}

function filters(el, values, apply, countOf) {
  el.innerHTML = values.map(v =>
    '<button data-v="' + v + '">' + v + ' (' + countOf(v) + ')</button>').join('');
  const set = v => {
    el.querySelectorAll('button').forEach(b => b.classList.toggle('on', b.dataset.v === v));
    apply(v);
  };
  el.addEventListener('click', e => e.target.dataset.v && set(e.target.dataset.v));
  set('all');
}

render();
filters(document.getElementById('task-filters'),
  ['all', 'todo', 'doing', 'done', 'blocked'],
  v => document.querySelectorAll('.task').forEach(t =>
    t.hidden = v !== 'all' && t.dataset.status !== v),
  v => v === 'all' ? ROWS.filter(r => r.type === 'task').length
    : ROWS.filter(r => r.type === 'task' && r.status === v).length);

if (DECISIONS.length) {
  document.getElementById('decisions-section').hidden = false;
  document.getElementById('decisions').innerHTML = DECISIONS.map(d =>
    '<div class="decision" data-status="' + esc(d.status) + '">'
    + '<strong>' + esc(d.id) + '</strong> ' + esc(d.question)
    + badge(d.stakes, 'k') + badge(d.status, 's')
    + '<span class="chip">by ' + esc(d.by) + '</span>'
    + '<span class="chip">asked ' + esc(d.asked) + '</span>'
    + (d.status === 'resolved'
        ? '<p class="muted">' + esc(d.answer) + ' <span class="chip">' + esc(d.resolved) + '</span></p>'
        : (d.default ? '<p class="muted">default: ' + esc(d.default) + '</p>' : ''))
    + '</div>').join('');
  filters(document.getElementById('decision-filters'),
    ['all', 'open', 'resolved'],
    v => document.querySelectorAll('.decision').forEach(d =>
      d.hidden = v !== 'all' && d.dataset.status !== v),
    v => v === 'all' ? DECISIONS.length : DECISIONS.filter(d => d.status === v).length);
}
${LIVE_SCRIPT}
</script>
</body>
</html>
`;
}
