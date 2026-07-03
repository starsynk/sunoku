# Journal — Sunoku

> Append-only. Entry types: track | reshape | decision. Newest at the bottom.
> Entry header pattern (machine-scanned): `## YYYY-MM-DD — <type>`

## 2026-07-02 — track
**What:** Sunoku record armed (existing-code onboarding; as-built PRD approved at accuracy gate).
**Why:** Established the living record for the Sunoku plugin repo itself. As-built PRD reconstructed from source with every claim cited file:line; accuracy-gate scrutiny corrected 6 line-range citations before approval. Gap roadmap declined — gap list holds only hardening/ops items, no missing must-have features.
**Refs:** 76789887ed1553c40d068f573af7d0634ab138cd

## 2026-07-03 — track
**What:** `sunoku:init` product-type detection replaced a naive source-files check with a framework-agnostic substance test — "if the repo were deleted and its generator re-run, would anything of substance be lost?" — scored across four signals (git history shape, domain vocabulary, generator divergence, wiring). Fresh scaffolds (e.g. `create-next-app`) now route to greenfield, with the scaffold recorded as the starting stack in BRIEF constraints.
**Why:** Robustness fix to existing-vs-greenfield routing, not a scope change — both onboarding paths (existing-code, greenfield) stay as documented; only the detector's accuracy improved. Verified by scenario E (fake create-next-app fixture → origin greenfield, stack captured in BRIEF constraints).
**Refs:** 6bbd6d7, tests/scenarios.md scenario E

## 2026-07-03 — reshape
**What:** Added `sunoku:work` — a loop-armed execution skill that works TASKS.md one task per iteration, blocks failures after 3 attempts, and gates at milestone boundaries.
**Why:** The record could plan builds it couldn't drive; scope now includes executing the approved plan. Planning agents still never write code — the work skill drives the main assistant, on explicit invocation only.
**Refs:** dbda593 f3b3995 03fd0d4 bc891da 45de720 e1e6ce4 dc24069 6aeb33f

## 2026-07-03 — track
**What:** Self-migrating record schema: `reference/MIGRATIONS.md` registry applied via a new canon "Record migrations" rule, `sunokuVersion` stamped on every record write, version-skew nudge in the SessionStart hook (read-only), CHANGELOG.md added.
**Why:** 1.0.0-written records lack the new TASKS.md Status column — upgrades must not strand existing records. Legacy shapes now upgrade silently on the first skill touch; hooks detect skew but never write.
**Refs:** e84d637

## 2026-07-03 — track
**What:** Added a `Coexistence` principle to `reference/canon.md` (new top-level section, after Prime directive): a Sunoku flow narrows exactly one thing in the assistant's behavior — product design authority, already settled upstream in PRD/roadmap/task trace — and suppresses no other applicable skill from any plugin or source. Stated as a hard rule with a named failure mode ("suppressing an applicable skill because a Sunoku flow is driving is a Sunoku failure, as much as pausing on a SILENT change is").
**Why:** A work-loop run let the assistant over-generalize "you never redesign" into "no skills fire at all," silently dropping execution-lane skills (house coding conventions, TDD, systematic debugging, verification) the flow never governed. Placing the guarantee in the shared rulebook — plugin-agnostic, naming no specific plugin or skill — means every skill, including the work loop when v2 re-adds it, inherits it without per-skill wiring. Chosen over an enumerate-what-Sunoku-owns approach (over-specifies) and a two-lane model (reifies the flawed "process lane" metaphor that caused the misread). Design record: docs/superpowers/specs/2026-07-03-sunoku-coexistence-design.md (git-excluded).
**Refs:** conversation; reference/canon.md `## Coexistence`
