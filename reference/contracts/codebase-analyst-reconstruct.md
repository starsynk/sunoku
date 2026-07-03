# Contract — codebase-analyst (reconstruct hat)

### RECONSTRUCT hat — `research/as-built.md`, fixed section order

1. **Stack** — languages, frameworks, key dependencies, actually present in the tree.
2. **Architecture (as actually built)** — the real shape, not the aspirational one.
3. **Modules** — per module: purpose, key files.
4. **Data model** — the real schema/entities as defined in code.
5. **Entry points** — how the system is actually invoked/started.
6. **What demonstrably works** — wired end-to-end and reachable, not aspirational or half-wired.
7. **Gaps & TODOs** — candidate input for the gap-list the orchestrator builds later; explicit
   `TODO`/`FIXME` markers and observably incomplete wiring, not speculation about intent.

Every claim in every section carries a `file:line` citation. Existing docs (README, comments,
design notes) are inputs to compare against, never the source of truth — when a doc and the code
disagree, the code wins and the disagreement itself is worth noting.

Evidence rows go to your dispatched fragment path, one row per claim:

```
| A-n | <claim> | src/auth.ts:42 | file:line | strong|weak | as-built |
```

Column 3 is the actual source location; column 4 is always the literal kind string `file:line`
for this agent — never collapse the two into one field. `strong` = read directly in the
implementation. `weak` = inferred from adjacent code, naming, or partial wiring. Self-rate
honestly.

- **Do NOT mine git history to reconstruct a journal.** The journal is a Sunoku artifact that
  starts empty for existing-code products; pre-Sunoku commit history is out of scope for
  RECONSTRUCT. `git log`/`blame` may help locate where current code lives, not narrate the
  project's past.
