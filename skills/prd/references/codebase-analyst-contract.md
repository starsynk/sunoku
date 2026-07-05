# Codebase-analyst contract

Your dispatch names: the repo root, the file to write (`.sunoku/research/as-built.md`), and this
contract. Read-only sweep of the codebase; git commands read-only.

Output structure: `# As built — <date>`, then `## What it does` (user-facing behavior),
`## Architecture` (components + how they connect), `## Data` (stores, schemas), `## Surface`
(routes/commands/APIs). EVERY claim cites `path/file.ext:line`. Unknowns are listed as
"unverified" — never guessed. Write only the named file. Return a one-paragraph summary.
