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

## 2026-07-03 — reshape
**What:** Dropped `sunoku:work` (feature 18) in 1.2.0 — the command, canon's Work loop section, and the four-command surface are gone; Sunoku is plans-and-documents-only again. The TASKS.md Status/Blocked schema survives as canon "Execution contract": an open contract any executor may work, with reconcile flipping diff-proven tasks to `done`.
**Why:** One release of owning execution showed the cost: to run unattended the loop had to pre-satisfy other plugins' design gates and forbid mid-run questions, displacing exactly the process discipline (TDD, plan execution, review checkpoints) users install other plugins for — the Coexistence misread was the symptom, this is the cure at the root. Record-keeping is Sunoku's product; execution is commodity. Decided, approved, and removed the same day the feature shipped; scenario F/F2 retired in place as the dated run log.
**Refs:** f2589f2 (drop), 89213b7 (canon Coexistence), CHANGELOG.md 1.2.0

## 2026-07-04 — track
**What:** 1.3.0 progressive disclosure: canon split into an always-read core (Prime directive, Coexistence, Triage, new Disclosure map) plus per-lane section files; RESHAPE/reconcile/init-phase/first-run-onboarding procedures and multi-hat agent contracts load on demand; guards precede canon reads; hook CTX compressed with a direction-aware version-skew nudge; skill/agent descriptions trimmed to routing triggers; status.json gained a four-field summary index (one_liner, open_questions, high_stakes, last_entry) with a 1.2.x→1.3.0 self-migration; JOURNAL.md rolls entries past 30KB into .sunoku/journal/<year>.md.
**Why:** Token cost, not behavior: the common-path log triage drops ~5k→~1.5k tokens, the status report reads the status.json index instead of the whole record and stays bounded as the journal grows, init resume drops ~4.4k→~2.3k. Record semantics are frozen — triage lanes, checkpoint ceremony, and the Execution contract are unchanged; the schema change is additive and self-migrating on first touch, mirroring the 1.1.0→1.2.0 migration precedent. Every extraction was verified byte-identical and gated by a structure test suite (tests/test-structure.sh) plus adversarial task reviews; a final whole-branch review caught and closed one real dead end (the gap-plan hat had no contract file after the split).
**Refs:** 5a8e5b6..84fdd3e (24 commits, branch claude/magical-lamarr-ee8a06), CHANGELOG.md 1.3.0

## 2026-07-04 — track
**What:** Reconciled the PRD to as-built through commit `a728727` (46 commits unreconciled since `76789887`; 47-commit reconcile range). Rewrote the Architecture "Shared rulebook" bullet for the canon always-read core + ten `reference/canon/` section files + Disclosure map (and the guard-before-canon load order); corrected `git ls-files` 40→70 and canon 238→70 lines; re-pointed moved traces to the `reference/canon/` section files and `skills/*/references/` phase files across the features table, UX, out-of-scope, and success metrics; folded journal 30KB rollover into feature 9; refreshed feature 10 (12-key summary-index schema), 15 (split hat contracts), 16 (16 hook assertions), and 19 (record-migrations path). Added a Change Log row.
**Why:** The 1.3.0 work was correctly TRACK-lane and already journaled (the 2026-07-04 — track entry above), but TRACK does not touch the PRD, so the current-state snapshot drifted — the Architecture section still described a 238-line single-file canon that no longer exists. Reconcile-forward per the canon Prime directive: catch the PRD up to the journal without RESHAPE ceremony, because product-architecture substance (living-record model, hub-and-spoke topology, triage lanes) is unchanged — only canon packaging moved (same lane logic as Q-3).
**Refs:** `76789887..a728727` (47 commits); analysis `.sunoku/research/reconcile-2026-07-04.md`; 2 code-side flags surfaced for follow-up (`reference/templates/status.json.example` missing the four summary fields; scenarios G1-G6 unrun)

## 2026-07-04 — decision
**What:** Q-3 (Coexistence canon addition triaged TRACK, not RESHAPE) answered and flushed — the lane call stands.
**Why:** Assumption: the `## Coexistence` canon section was a TRACK-lane articulation of existing direction, not an architecture RESHAPE. Answer (recorded 2026-07-03, flushed today under the new Answering lifecycle): confirmed — the feature-18-drop RESHAPE mooted the question by refreshing the PRD Architecture "Shared rulebook" bullet wholesale; the principle itself stayed TRACK-grade. No doc ripple: the PRD staleness the flip-if-wrong flagged was closed by the f2589f2 reconcile and the 2026-07-04 PRD reconcile.
**Refs:** journal `2026-07-03 — reshape`; f2589f2

## 2026-07-04 — track
**What:** QUESTIONS.md answer-and-flush lifecycle: canon assumptions gained an `## Answering` section (journal `decision` entry first, triage the flip, delete the block, status refresh), Disclosure map row, log/status skill hooks, template header now "open questions only". No record migration — stale answered entries in old records are inert.
**Why:** The template promised "answering triggers an appropriately scoped update" but no canon or skill defined it; answered entries were dead weight (tooling greps `status: open` only). Flush relocates rather than deletes: the chronicle lives in the journal, where history queries already read — lean file, zero history loss, doc propagation via existing triage lanes instead of new machinery.
**Refs:** e142efb; docs/superpowers/specs/2026-07-04-questions-flush-design.md (git-excluded)

## 2026-07-04 — track
**What:** Deterministic scripts layer (v1.5.0): nine zero-dependency Node scripts under scripts/ now perform every mechanical record write — canonical status.json (status-write, scaffold), journal append + rollover (journal-append), question flushes (questions-flush), task-status flips (tasks-set), resume done-map (sentinels), migrations applier (migrate), and the one-call status report (report) — with skills and canon rewired to run them instead of hand-editing. 100-assertion test suite (tests/test-scripts.sh); stale status.json.example template fixed (a 2026-07-04 reconcile flag).
**Why:** Hand-written status.json risked byte-format drift that silently breaks the ambient hooks (they grep exact patterns), and the live record already exhibited the failure mode: last_entry held a paraphrase of the journal's What line instead of a copy. Judgment stays with the orchestrator (triage lanes, blast radius, entry prose); serialization, counts, timestamps, shas, and rollovers are now computed. TRACK not RESHAPE by the canon-split precedent: mechanism/packaging changed, product substance (living-record model, triage lanes, three-command surface) did not; the PRD Architecture section catches up at the next reconcile.
**Refs:** conversation (uncommitted working tree at time of entry)
