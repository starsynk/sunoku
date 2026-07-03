# Canon — StatusFile

`status.json` lives at the `.sunoku/` root and is the single lifecycle source of truth. Only the
orchestrator writes it — agents never touch it. Canonical serialization (one key per line, two-space
indent, exact key order below) is mandatory; hooks match on exact byte patterns like
`"tracking": true` and `"lifecycle": "live"`, so any other formatting breaks them:

```json
{
  "version": 1,
  "sunokuVersion": "<plugin version>",
  "product": "<display name>",
  "origin": "greenfield",
  "lifecycle": "defining",
  "tracking": false,
  "last_reconciled_sha": "",
  "created": "2026-07-02T09:00:00Z",
  "updated": "2026-07-02T09:00:00Z"
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
- `last_reconciled_sha` — the consumer repo commit the journal was last reconciled against.

Lifecycle transitions:

```
validating -> defining -> planning -> live
defining -> live                        (existing/as-built products skip planning)
(any phase) -> shelved                  (on kill)
```

Every write to status.json updates `updated` to the current timestamp and re-stamps
`sunokuVersion` with the current plugin version; `created` never changes after the file's first
write.
