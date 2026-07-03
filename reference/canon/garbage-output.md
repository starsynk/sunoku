# Canon — Garbage output

If a dispatched agent returns output that is empty or violates its output contract (wrong sections,
missing file, wrote to the wrong path), the orchestrator issues exactly one corrective re-dispatch
that names the specific failure ("EVIDENCE.md fragment has no rows" / "architecture.md missing the
Rejected Alternative section"). If the re-dispatch still comes back bad, stop and surface the
failure to the user. Never invent the missing content to paper over a bad agent run.
