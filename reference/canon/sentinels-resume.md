# Canon — Sentinels & resume

Every stub template ships with a sentinel as its literal first line: `<!-- sunoku:stub -->`. An
artifact is **done** when it exists, is non-empty, and the sentinel is absent (removing the
sentinel is the write-agent's explicit "I filled this in" signal — see Dispatch). Append-only
ledgers (JOURNAL.md, EVIDENCE.md) are done once they hold at least 1 entry row; an empty ledger
with the sentinel removed is not done.

Journal entries use a machine-scanned header: `## YYYY-MM-DD — <type>`, where `<type>` is one of
`track`, `reshape`, `decision`.

Resume is two-level, checked in order:

1. **status.json `lifecycle`** — tells the orchestrator which phase the product is broadly in.
2. **Per-artifact sentinel checks** — within that phase, which specific files are actually done.
   `node "${CLAUDE_PLUGIN_ROOT}/scripts/sentinels.mjs"` prints the whole done-map as JSON in
   one call (done | stub | empty | empty-ledger | missing per artifact).

A resumed run never restarts a phase from scratch and never clobbers an artifact that already
passed its done-check. It picks up at the first not-done artifact.
