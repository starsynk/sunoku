# Sunoku exercised-verification scenarios

Regression checklist for the greenfield paths. Each scenario is run by invoking the plugin headless
against a throwaway git repo and asserting on the resulting `.sunoku/` files — behaviour is verified
by exercising the flow, never by reading the source.

## How to run

From inside a fresh scratch repo (`git init` + one commit):

```
export CLAUDE_CODE_SUBAGENT_MODEL=sonnet
claude -p "<scenario prompt>" \
  --plugin-dir <path-to-sunoku> \
  --model sonnet --permission-mode bypassPermissions --max-turns 100
```

Headless runs cannot be asked questions, so each prompt pre-supplies the checkpoint answers
(scoping batch, go/no-go verdict, PRD approve). Assertions are plain `grep`/`find` checks on the
written files. Never weaken an assertion to make a run pass — fix the plugin at the source.

Last run: **2026-07-02** (model under test: sonnet, one opus retry on D4; subagents: sonnet).
Scenarios A–C cover the greenfield paths; D1–D5 cover the existing-code lifecycle
(onboard → track → reshape → reconcile → history/refuse).

---

## Scenario A — greenfield GO path

**Idea:** CLI tool that turns Figma tokens into a Tailwind config. Scoping: design-systems
engineers / zero-config sync / monetization undecided / solo dev evenings / not yet committed.
Prompt accepts the verdict, approves the PRD, skips PLAN.

**Assertions**

- [x] `status.json` → `"lifecycle": "live"` and `"tracking": true`
- [x] `validation/<date>-validation.md` exists, sentinel-free first line, has a `## Verdict` with a
      populated GO/GO-IF/NO-GO verdict
- [x] validation evidence table rows carry URL-shaped sources; full `https://` URLs live in
      `research/EVIDENCE.md` (≥1 row)
- [x] `PRD.md` sentinel-free; Features table every row has a Trace (`V-n` / `Q-n` / `file:line` /
      explicit assumption); exactly one `### Rejected alternative`
- [x] `JOURNAL.md` ≥1 machine-scanned entry header
- [x] `research/.fragments/` empty or absent (fragments merged + deleted at the barrier)

**Result: PASS (14/14).** Verdict was a real GO-IF with two evidence-backed conditions (Figma
Variables API is Enterprise-gated; no evidenced paid axis). 25 evidence rows, all with URLs. Run
took ~28 min.

---

## Scenario B — greenfield NO-GO → shelved (two runs)

**Idea (doomed):** paid RSS reader themed around MySpace nostalgia, no budget, no time. Prompt
instructs: if the verdict is NO-GO, accept it and do not argue for building.

**Run 1 assertions**

- [x] `status.json` → `"lifecycle": "shelved"`
- [x] `JOURNAL.md` has a `— decision` entry recording the kill and why
- [x] validation report present with a NO-GO verdict
- [x] `PRD.md` absent or still stubbed (DEFINE never ran)

**Run 2 — re-invoke with "keep it shelved"**

- [x] refuses to restart / revive (validation report count stays 1, PRD stays stubbed)
- [x] `.sunoku/` files unchanged (content hash identical before/after — verified `18fadd84…`)
- [x] `status.json` still `shelved`

**Result: PASS (run 1: 5/5; run 2: unchanged-hash + still-shelved).** NO-GO verdict cited three
compounding blocking findings (literal "no time", SpaceHey precedent skews Gen-Z, subscription
rejected by precedent). Keep-shelved run presented the rationale and made zero writes. Runs took
~9 min (run 1) + ~30 s (run 2).

---

## Scenario C — greenfield skip-validate (already committed)

**Idea:** Markdown-based note-taking CLI for developers. Scoping answers the commitment question
"already committed". Prompt approves the PRD, skips PLAN.

**Assertions**

- [x] `validation/` empty or absent (no report is ever produced for a committed record)
- [x] `JOURNAL.md` has a `— decision` entry recording the VALIDATE skip and its reason
- [x] flow went straight to DEFINE — `PRD.md` present, sentinel-free
- [x] `status.json` ends `"lifecycle": "live"` and `"tracking": true`

**Result: PASS (6/6).** Journal decision entry: "Skipped VALIDATE… user already committed." No
`validation/` directory created. PRD assembled with Trace refs and one Rejected alternative. Run
took ~17 min.

---

## Existing-code lifecycle run (2026-07-02)

Scenarios D1–D5 exercise the full existing-code path against one throwaway fixture repo: a ~12-file
Node CLI (`taskvault`: `bin/` entry, `src/commands/{list,add,done,remove}.js`, `src/lib/{args,store,
render}.js`, README, CHANGELOG, a passing test). The README documents a `--format` flag for `list`
while the code implements it as `--output` (proven: `taskvault list --output json` prints JSON;
`--format json` is silently ignored → table default) — a deliberate doc/code disagreement for the
accuracy gate. `git init` + one commit before D1. D1→D5 run in sequence against the same repo, so
each step builds on the record the previous one left.

## Scenario D1 — onboard existing codebase (accuracy-gate correction)

**Prompt:** run `sunoku:init`; scoping = name "taskvault" / solo-dev segment / no monetization; at
the accuracy gate **correct the `--format`→`--output` disagreement (code is authority)** then
approve; **decline** the gap roadmap.

**Assertions**

- [x] `research/as-built.md` cites `file:line` evidence (54 `.js`/`.json:NN` citations)
- [x] PRD reflects the corrected reality: `--output` present (×2), `--format` absent (×0); PRD
      sentinel-free
- [x] a **GAP LIST** was presented (transcript shows the "Gap List — must-haves not yet built"
      section with named items) and is captured in `PRD.md` (`## Gap List` section, 4 must-haves)
- [x] `status.json` → `"lifecycle": "live"` + `"tracking": true` immediately at gate approval,
      `origin: existing`, `last_reconciled_sha` = HEAD; canonical serialization intact
- [x] `JOURNAL.md` has ONLY the armed `track` entry (count == 1) — no synthetic pre-Sunoku history
- [x] `research/.fragments/` absent (analyst fragment merged onto EVIDENCE.md — 55 rows — + deleted)

**Result: PASS.** Armed entry records the `--format`→`--output` correction and cites the HEAD sha;
accuracy gate and the gap-list presentation both confirmed in the transcript. Run ~22 min.

## Scenario D2 — TRACK entry (standing-rule triage)

**Prompt:** "Add a `--json` output flag to the `list` command (edit the code), then do whatever
Sunoku's standing rule requires." (Model edits `src/commands/list.js`, then self-triages.)

**Assertions**

- [x] transcript shows the **SessionStart hook injected the standing rule** verbatim ("Sunoku living
      record is ACTIVE… Standing rule: after completing any substantive change, apply the triage
      test…")
- [x] `JOURNAL.md` gained **exactly one** `track` entry (count 1→2)
- [x] `PRD.md` **unchanged** (sha identical before/after — `b7685e8…`)
- [x] the code change is real (`options.json ? 'json' : options.output` in list.js)

**Result: PASS.** Correctly triaged a new in-scope convenience flag as TRACK (one journal line, no
PRD edit, no roadmap → no task row). Run ~3 min.

## Scenario D3 — RESHAPE (CLI → web dashboard pivot)

**Prompt:** "We are pivoting from CLI to a web dashboard — run `sunoku:log` to capture this. When
the reshape checkpoint is presented, approve it."

**Assertions**

- [x] `JOURNAL.md` gained a `— reshape` entry (count 1)
- [x] PRD Architecture/scope patched (Architecture rewritten for hosted web dashboard; 14
      dashboard/web mentions across Problem/Personas/Features/Architecture/UX/Out-of-scope)
- [x] PRD **Change Log** gained ≥1 row (1 row, pointing at the reshape entry)
- [x] **exactly one** checkpoint in the transcript (one "RESHAPE checkpoint" turn presenting the
      full delta as a single unit; verified assistant-authored, not skill text)

**Result: PASS.** Resolved a 2-of-3 agent conflict on auth as a judgment call (kept auth, patched
the UX draft) and surfaced 4 high-stakes assumptions inside the one checkpoint per canon. Run
~15 min.

## Scenario D4 — out-of-band drift + reconcile

**Setup:** 2 direct `git commit`s (no Claude) touching `src` — `--json` flag, then a new `count`
command wired into `bin/`. HEAD moves; `last_reconciled_sha` still points at the D1 commit.

**Prompt:** "Run `sunoku:status`; accept the reconcile offer; approve any checkpoint."

**Assertions**

- [x] status output mentioned the drift count ("2 commits since last reconcile", both shas named)
- [x] after the run, `last_reconciled_sha` == new HEAD (`1a65cc8…`)
- [x] journal entries written for substantive groups: `count` command → one `track` entry (refs the
      HEAD sha); the `--json` group correctly **skipped** (already journaled in D2 — no double-log)

**Result: PASS on retry.** First pass (sonnet) reported drift correctly but stopped at the offer
("Reconcile now?") instead of acting on the pre-supplied acceptance — weak model-following, not a
plugin defect. Retried once with `--model opus` and a prompt that pre-accepts the offer explicitly;
opus carried the full reconcile through, triaged both groups (skip already-logged / TRACK the new
command), and advanced the sha to HEAD. Runs ~4 min + ~6 min.

## Scenario D5 — history answer + live re-init refusal

**Prompt A:** "What changed in this project recently, and why? Answer from the Sunoku record."

**Prompt B:** "Run `sunoku:init`" (on a live record).

**Assertions**

- [x] history answer **cites journal entries** — 4 dated entries with types, including the reshape
      with its "why" (CLI framing retired for a browser-based per-user product); no git-log invention
- [x] re-init **refuses to re-initialize**: reports one line of live state and hands off to
      `sunoku:status` (full status report), asks zero scoping questions, re-runs no phase
- [x] `.sunoku/` **unchanged** by the re-init (content hash `593f7811…` identical before/after; same
      8-file set)

**Result: PASS.** Both history and re-init routed through the status surface exactly as specified;
the live guard made zero writes. Runs ~1 min each.

---

## Fixes made during this run

- **Greenfield run (A–C):** none to plugin files. (One assertion-script regex bug fixed in the test
  harness only.)
- **Existing-code run (D1–D5):** none to plugin files. All five steps behaved correctly on the
  exercised run; no plugin defect was found. The only non-pass was D4's first attempt, which was
  weak model-following (sonnet paused at the reconcile offer) resolved by the sanctioned one-retry
  with `--model opus` — an assertion was never weakened.
