# Canon — StatusFile

`status.json` lives at the `.sunoku/` root and is the single lifecycle source of truth. Only the
orchestrator writes it — agents never touch it — and every write goes through the plugin scripts
(`scripts/status-write.mjs`, or `scripts/scaffold.mjs` for the first write; `journal-append.mjs`
and `questions-flush.mjs` refresh it as a side effect), never a hand edit. A PreToolUse guard
hook enforces this mechanically: Edit/Write tool calls targeting the file are denied with a
pointer at the script. Canonical serialization (one key per line, two-space indent, exact key
order below) is mandatory — it keeps diffs deterministic and gives the contract exactly one
implementation. The scripts implement this contract:

```json
{
  "version": 1,
  "sunokuVersion": "1.7.0",
  "product": "<name>",
  "origin": "greenfield|existing",
  "lifecycle": "<lifecycle>",
  "tracking": true,
  "one_liner": "<first sentence of the PRD Problem section, or the product name while the PRD is a stub>",
  "open_questions": 0,
  "high_stakes": 0,
  "last_entry": "<YYYY-MM-DD — type — What line, or empty string>",
  "last_reconciled_sha": "<sha or empty>",
  "created": "<ISO8601>",
  "updated": "<ISO8601>"
}
```

Field semantics:

- `version` — schema version of the record itself (not the product, not the plugin); bumped only
  on a breaking record-shape change where shape-sniffing cannot work (see Record migrations).
- `sunokuVersion` — the plugin version that last wrote the record (not the product's version),
  read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` and re-stamped on every
  status.json write.
- `origin` — `greenfield` | `existing`.
- `lifecycle` — `validating` | `defining` | `planning` | `live` | `shelved`.
- `tracking` — whether TRACK/RESHAPE triage is active for this product.
- `one_liner` / `open_questions` / `high_stakes` / `last_entry` — the denormalized summary index;
  see the rule below for what refreshes them and what they're for.
- `last_reconciled_sha` — the consumer repo commit the journal was last reconciled against.

The four summary fields (`one_liner`, `open_questions`, `high_stakes`, `last_entry`) are a
denormalized index of the record. Every write that changes their source (journal append, PRD
Problem edit, QUESTIONS.md change) refreshes them in the same status.json write. They are
advisory for fast reporting; drill-in answers verify against the record files. `last_entry`
caps its What excerpt at 140 chars — the full text lives in the journal.

Lifecycle transitions:

```
validating -> defining -> planning -> live
defining -> live                        (existing/as-built products skip planning)
(any phase) -> shelved                  (on kill)
```

Every write to status.json updates `updated` to the current timestamp and re-stamps
`sunokuVersion` with the current plugin version; `created` never changes after the file's first
write.
