# Changelog

## 2.1.0 — 2026-07-06

- `read` and `track` are now hidden from the `/` menu via `user-invocable: false` — model-only
  invocation is enforced by frontmatter, not just prose. `init` stays user-only via
  `disable-model-invocation`.
- README: new `## Loop` section documents `/loop` with Sunoku — self-paced backlog drain,
  fixed-interval watch, and three `superpowers` build-loop variants (in-place, one-PR,
  PR-per-task).

## 2.0.0 — 2026-07-05

Breaking rewrite. History before 2.0.0 is intentionally cleared.

- Seven self-contained skills: `init` (user-only setup), `research`, `prd`, `plan`, `track`
  (model-only, consent-gated), `status`, `read` (model-only retrieval). Every skill owns its
  references, templates, and scripts — the shared canon rulebook is gone.
- Record is now `PRD.md` + `status.json` + `tasks.jsonl` + `decisions.jsonl` + `research/*.md`.
  The PRD Change Log table is the only history.
- Removed: canon.md and disclosure machinery, JOURNAL.md and the log skill's triage lanes, the
  shelved lifecycle (a NO-GO wipes `.sunoku/`), reconcile ceremony, record migrations, the Stop
  nudge hook, and four agents (design-lead, feasibility-assessor, delivery-planner,
  delivery-critic).
- No migration path: delete any v1 `.sunoku/` and re-run `sunoku:init`.
