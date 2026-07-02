# Evidence Ledger — Sunoku

> Append-only. One row per claim. Kind: URL (validation research) or file:line (as-built).

| ID | Claim | Source | Kind | Strength | Phase |
|---|---|---|---|---|---|
| AB-1 | No compiled runtime or package manager manifest exists; tracked tree is 31 files, all `.md`/`.json`/`.sh`/LICENSE | git ls-files (repo root) | file:line | strong | RECONSTRUCT |
| AB-2 | Plugin manifest declares name `sunoku`, version `1.0.0`, license MIT | .claude-plugin/plugin.json:1-9 | file:line | strong | RECONSTRUCT |
| AB-3 | Marketplace manifest sources the one `sunoku` plugin from `./` (this repo's own root) | .claude-plugin/marketplace.json:5-7 | file:line | strong | RECONSTRUCT |
| AB-4 | Three skills are Markdown SKILL.md files with YAML frontmatter `name`/`description` | skills/init/SKILL.md:1-4 | file:line | strong | RECONSTRUCT |
| AB-5 | Eight subagents are Markdown files with frontmatter `name`, `description`, `tools`, `model` | agents/codebase-analyst.md:1-6 | file:line | strong | RECONSTRUCT |
| AB-6 | codebase-analyst is the only agent granted the Bash tool | agents/codebase-analyst.md:4 | file:line | strong | RECONSTRUCT |
| AB-7 | Agent model tiers: analyst/critic/planner/feasibility/red-team = best; design-lead/product-owner/researcher = sonnet | agents/codebase-analyst.md:5; agents/delivery-critic.md:5; agents/delivery-planner.md:5; agents/feasibility-assessor.md:5; agents/red-team.md:5; agents/design-lead.md:5; agents/product-owner.md:5; agents/researcher.md:5 | file:line | strong | RECONSTRUCT |
| AB-8 | Hooks are wired via hooks/hooks.json invoking two Bash scripts through CLAUDE_PLUGIN_ROOT | hooks/hooks.json:2-27 | file:line | strong | RECONSTRUCT |
| AB-9 | Both hook scripts declare `#!/usr/bin/env bash` and use only set -u/sed/grep/git/cksum/printf | hooks/scripts/session-start.sh:1,4; hooks/scripts/stop-nudge.sh:1,4 | file:line | strong | RECONSTRUCT |
| AB-10 | Canon (173 lines) plus 10 files under reference/templates/ form the shared rulebook and stub set | reference/canon.md:1-173 | file:line | strong | RECONSTRUCT |
| AB-11 | test-hooks.sh shells out to python3 -m json.tool for JSON-validity checking, the one non-Bash dependency in the test harness | tests/test-hooks.sh:94 | file:line | strong | RECONSTRUCT |
| AB-12 | Canon states the orchestrator is the sole integrator; agents never invoke or message each other | reference/canon.md:69-71 | file:line | strong | RECONSTRUCT |
| AB-13 | All three orchestrating skills mandate reading canon first before any other step | skills/init/SKILL.md:15; skills/log/SKILL.md:14; skills/status/SKILL.md:13 | file:line | strong | RECONSTRUCT |
| AB-14 | Several agents carry more than one "hat" selected by dispatch prompt within a single file | agents/codebase-analyst.md:14-16; agents/feasibility-assessor.md:13-18; agents/delivery-planner.md:14-18; agents/product-owner.md:19; agents/red-team.md:20 | file:line | strong | RECONSTRUCT |
| AB-15 | Fragments pattern: parallel writers use research/.fragments/<phase>-<agent>.md, merged and deleted after the phase barrier | reference/canon.md:84-96 | file:line | strong | RECONSTRUCT |
| AB-16 | status.json is the sole lifecycle source of truth, written only by the orchestrator | reference/canon.md:136-139 | file:line | strong | RECONSTRUCT |
| AB-17 | Lifecycle state machine: validating->defining->planning->live, defining->live for existing products, any->shelved | reference/canon.md:163-169 | file:line | strong | RECONSTRUCT |
| AB-18 | Hooks gate on exact byte-level grep of `"tracking": true` and `"lifecycle": "live"` | hooks/scripts/session-start.sh:17-18; hooks/scripts/stop-nudge.sh:15-16 | file:line | strong | RECONSTRUCT |
| AB-19 | Prime directive: never writes application code, never touches consumer repo source tree outside .sunoku/ | reference/canon.md:9-11 | file:line | strong | RECONSTRUCT |
| AB-20 | skills/init/SKILL.md is 190 lines with routing, scaffold, greenfield flow, existing-code flow sections | skills/init/SKILL.md:23-48,50-65,67-136,138-173 | file:line | strong | RECONSTRUCT |
| AB-21 | skills/log/SKILL.md (108 lines): guard, triage lanes, journal entry format, RESHAPE procedure | skills/log/SKILL.md:18-25,35-53,54-66,68-103 | file:line | strong | RECONSTRUCT |
| AB-22 | skills/status/SKILL.md (83 lines): report contract, history-answer rule, reconcile, mute/unmute | skills/status/SKILL.md:26-46,48-57,59-77,79-83 | file:line | strong | RECONSTRUCT |
| AB-23 | design-lead agent forbids mockups/wireframes/HTML/CSS/image generation; words only | agents/design-lead.md:47-49 | file:line | strong | RECONSTRUCT |
| AB-24 | red-team agent mandates a strongest-objection finding even against sound work | agents/red-team.md:12-13 | file:line | strong | RECONSTRUCT |
| AB-25 | status.json canonical field order: version, product, origin, lifecycle, tracking, last_reconciled_sha, created, updated | reference/canon.md:143-153; reference/templates/status.json.example:1-11 | file:line | strong | RECONSTRUCT |
| AB-26 | status.json field semantics: origin in {greenfield, existing}; lifecycle in 5 named values; tracking boolean; last_reconciled_sha | reference/canon.md:156-161 | file:line | strong | RECONSTRUCT |
| AB-27 | BRIEF.md template fixed sections: Segment, Wedge, Monetization stance, Constraints, Commitment | reference/templates/BRIEF.md:1-18 | file:line | strong | RECONSTRUCT |
| AB-28 | PRD.md template fixed sections incl. Features table Trace column and one Rejected alternative, plus append-only Change Log table | reference/templates/PRD.md:1-29 | file:line | strong | RECONSTRUCT |
| AB-29 | JOURNAL.md machine-scanned header pattern `## YYYY-MM-DD — <type>`, type in {track, reshape, decision} | reference/templates/JOURNAL.md:4-5; reference/canon.md:125-127 | file:line | strong | RECONSTRUCT |
| AB-30 | Journal entry body shape: **What:**, **Why:**, **Refs:** | skills/log/SKILL.md:57-62 | file:line | strong | RECONSTRUCT |
| AB-31 | QUESTIONS.md entry pattern with stakes/status and Assumption/Reasoning/Flip-if-wrong fields | reference/templates/QUESTIONS.md:4-7 | file:line | strong | RECONSTRUCT |
| AB-32 | Full canon assumption format adds Chosen default and Stakes as explicit fields | reference/canon.md:53-59 | file:line | strong | RECONSTRUCT |
| AB-33 | EVIDENCE.md ledger columns: ID, Claim, Source, Kind, Strength, Phase; Kind in {URL, file:line} | reference/templates/EVIDENCE.md:4-7 | file:line | strong | RECONSTRUCT |
| AB-34 | .gitignore for .sunoku excludes .cache/ and research/.fragments/ | reference/templates/sunoku.gitignore:1-2 | file:line | strong | RECONSTRUCT |
| AB-35 | ROADMAP.md M1 is literally titled "Walking skeleton", no calendar estimates | reference/templates/ROADMAP.md:6 | file:line | strong | RECONSTRUCT |
| AB-36 | TASKS.md columns: ID, Task, Size, Trace, Depends on | reference/templates/TASKS.md:7 | file:line | strong | RECONSTRUCT |
| AB-37 | validation-report.md is immutable once finalized; re-examination produces a new dated file | reference/templates/validation-report.md:1-3 | file:line | strong | RECONSTRUCT |
| AB-38 | Sentinel `<!-- sunoku:stub -->` is literal first line of every stub template | reference/templates/BRIEF.md:1; reference/templates/EVIDENCE.md:1; reference/templates/JOURNAL.md:1; reference/templates/PRD.md:1; reference/templates/QUESTIONS.md:1; reference/templates/ROADMAP.md:1; reference/templates/TASKS.md:1; reference/templates/validation-report.md:1 | file:line | strong | RECONSTRUCT |
| AB-39 | Sentinel/done-check rule: exists + non-empty + sentinel absent (ledgers need >=1 real row) | reference/canon.md:119-124 | file:line | strong | RECONSTRUCT |
| AB-40 | README frames sunoku:init as the only command a user must learn | README.md:96-100 | file:line | strong | RECONSTRUCT |
| AB-41 | sunoku:init refuses to re-initialize a live record and hands off to sunoku:status | skills/init/SKILL.md:26-28 | file:line | strong | RECONSTRUCT |
| AB-42 | sunoku:log is guarded on a live record before running any triage | skills/log/SKILL.md:18-25 | file:line | strong | RECONSTRUCT |
| AB-43 | SessionStart hook wired with matcher startup\|resume\|clear\|compact, 10s timeout | hooks/hooks.json:3-14 | file:line | strong | RECONSTRUCT |
| AB-44 | session-start.sh exits silently unless status.json shows tracking:true and lifecycle:live on a valid git repo | hooks/scripts/session-start.sh:16-19 | file:line | strong | RECONSTRUCT |
| AB-45 | session-start.sh emits hookSpecificOutput.additionalContext with standing triage rule and drift count | hooks/scripts/session-start.sh:33-40 | file:line | strong | RECONSTRUCT |
| AB-46 | Stop hook wired, invoking stop-nudge.sh | hooks/hooks.json:15-25 | file:line | strong | RECONSTRUCT |
| AB-47 | stop-nudge.sh fires at most once per session via a nudged-<session> marker file | hooks/scripts/stop-nudge.sh:20-21,33 | file:line | strong | RECONSTRUCT |
| AB-48 | stop-nudge.sh only nudges when code changed since snapshot and journal not updated after | hooks/scripts/stop-nudge.sh:24-31 | file:line | strong | RECONSTRUCT |
| AB-49 | README's Windows caveat: hooks require Git Bash on PATH or silently no-op | README.md:89-92 | file:line | strong | RECONSTRUCT |
| AB-50 | Both hooks hard-code the bash "${CLAUDE_PLUGIN_ROOT}/..." invocation form, no Windows-native fallback | hooks/hooks.json:9,20 | file:line | strong | RECONSTRUCT |
| AB-51 | Local dev entry bypasses marketplace via claude --plugin-dir | README.md:83-87 | file:line | strong | RECONSTRUCT |
| AB-52 | test-hooks.sh defines 10 assertions across both hook scripts (case list) | tests/test-hooks.sh:46-96 | file:line | strong | RECONSTRUCT |
| AB-53 | scenarios.md states its own verification method: exercising the flow, never reading the source | tests/scenarios.md:5 | file:line | strong | RECONSTRUCT |
| AB-54 | Scenario A (greenfield GO) self-reported PASS 14/14 | tests/scenarios.md:28-49 | file:line | weak | RECONSTRUCT |
| AB-55 | Scenario B (NO-GO -> shelved, revive-refusal) self-reported PASS both runs | tests/scenarios.md:52-73 | file:line | weak | RECONSTRUCT |
| AB-56 | Scenario C (skip-validate/committed) self-reported PASS 6/6 | tests/scenarios.md:77-91 | file:line | weak | RECONSTRUCT |
| AB-57 | Scenarios D1-D5 (existing-code lifecycle chained on one fixture repo) self-reported PASS each | tests/scenarios.md:105-197 | file:line | weak | RECONSTRUCT |
| AB-58 | D4's first attempt (sonnet) stalled at the reconcile offer; opus retry completed it — framed by maintainers as model-following weakness, not a plugin defect | tests/scenarios.md:174-179 | file:line | weak | RECONSTRUCT |
| AB-59 | No CI workflow exists in the tracked tree (no .github/workflows or other CI config) | git ls-files (repo root, full listing) | file:line | strong | RECONSTRUCT |
| AB-60 | No literal TODO/FIXME/XXX markers exist in Sunoku's own plugin source; all matches are prose describing the concept | agents/codebase-analyst.md:39-40; skills/init/SKILL.md:149,156 | file:line | strong | RECONSTRUCT |
| AB-61 | Gap list is explicitly scoped as candidate input for the orchestrator, not the final gap list itself | agents/codebase-analyst.md:39-40; skills/init/SKILL.md:156 | file:line | strong | RECONSTRUCT |
