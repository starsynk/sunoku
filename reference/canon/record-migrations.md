# Canon — Record migrations

Legacy record shapes upgrade in place, silently, applied by whichever skill touches the record
first. Before reading or writing any `.sunoku/` artifact, consult
`${CLAUDE_PLUGIN_ROOT}/reference/MIGRATIONS.md` and apply every row whose Detect shape matches,
before proceeding with the run's actual work.

- Migrations are mechanical: SILENT lane — no journal entry, no checkpoint; one line in the
  skill's output ("record migrated: <what>") is the only trace.
- Detection is shape-based (what the file actually contains), never version arithmetic.
  `sunokuVersion` exists for ambient skew *detection*, not as a migration trigger;
  `status.json.version` is reserved for a future breaking change where shape-sniffing cannot
  work.
- Hooks only detect version skew and nudge; they never write the record. Only skills migrate.
