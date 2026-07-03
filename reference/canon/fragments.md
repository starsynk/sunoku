# Canon — Fragments

Parallel writers never share a file. When two or more agents produce evidence in the same phase,
each writes its own fragment to `research/.fragments/<phase>-<agent>.md` — never to the shared
ledger directly. After the phase barrier (all dispatched writers for that phase have returned), the
orchestrator:

1. Concatenates every fragment onto `research/EVIDENCE.md`.
2. Deletes the fragment files.
3. Asserts fragment count == dispatched-writer count for that phase.

A missing fragment means a lost agent, not zero evidence. Surface the gap and re-dispatch that one
agent; never invent rows to make the count look right.
