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

---

## Scenario E — fresh scaffold routes to greenfield (boilerplate detection)

**Fixture:** fake `create-next-app` output — default `app/layout.tsx` + `app/page.tsx`, framework
README, deps = starter defaults, single commit "Initial commit from create-next-app". No domain
code. Prompt: habit-tracker idea ("Cadence"), already committed, approve PRD, skip PLAN, confirm
any scaffold reading.

**Assertions**

- [x] init applied the substance test and routed GREENFIELD (`"origin": "greenfield"`), not
      existing-code — transcript states: one generator commit, no domain code, defaults only,
      "nothing lost if regenerated"
- [x] no `research/as-built.md`, no RECONSTRUCT dispatch (fixture never documented as a product)
- [x] scaffold recorded as the given starting stack in `BRIEF.md` Constraints (Next.js 15.4.0,
      React 19, "not existing product code")
- [x] scaffold reading confirmed inside the scoping batch, not as a separate gate
- [x] committed skip honored: no `validation/`, journal `— decision` entry, ends `live` + tracking

**Result: PASS.** First run stalled awaiting a product display name (prompt gap, not plugin
defect — headless prompts must supply a name; scaffold's `my-app` is correctly not trusted).
Re-run with name supplied passed everything.

---

## Scenario F — work loop executes, blocks, and gates at milestone (2026-07-03)

**Fixture:** a throwaway "Greeter" repo with a **live record and a pre-built M1 backlog** — no
validate/define/plan phases, straight into execution. `greet.sh` (prints `hello`) + a `test.sh`
harness that conditionally asserts `farewell.sh`→`goodbye` and `shout.sh hello`→`HELLO!`.
`.sunoku/` holds `status.json` (live, tracking, greenfield), a two-milestone `ROADMAP.md`, and a
`TASKS.md` seeded T-1..T-4: **T-1** add farewell.sh, **T-2** add shout.sh (`Depends on: T-1`),
**T-3** an *intentionally impossible* task (greet.sh exit 0 while printing both "hello" and
nothing), **T-4** in M2. Fixture lives in scratch, never in the repo. Prompt: `/sunoku:work`,
invoked headless once per iteration (degraded one-task path — dynamic-loop wakeups don't fire
under `-p`), repeated until an `END —` signal. Model under test: **opus**; loop skill armed each
fresh invocation (arm attempt confirmed in run-1's transcript), then fell through to the
one-task-per-invocation degraded path as designed.

**Main run — 4 invocations (T-1 → T-2 → T-3 blocked → boundary idempotence)**

- [x] **T-1 done** — run 1 created `farewell.sh` (`goodbye`), flipped Status `todo→doing→done`,
      committed `T-1: …` on the milestone branch
- [x] **T-2 done, dependency honored** — T-2 only became eligible after T-1 was `done` (run 2);
      `shout.sh` landed, committed
- [x] **T-3 blocked after 3 attempts** — run 3 ran three distinct approaches on a scratch copy so
      `greet.sh` stayed pristine, all failed the done-bar; Status → `blocked`, **no code committed**
      (greet.sh unchanged), commit is record-files-only `T-3: blocked — …`
- [x] **Blocked table row** `| T-3 | 3 | … |` written (3 attempts, one-line reason)
- [x] **QUESTIONS.md flag** for T-3 in full canon Assumptions format (Assumption / Chosen default /
      Reasoning / Flip-if-wrong / Stakes: high), naming the human decision that unblocks it
- [x] **milestone branch** `sunoku/m1` exists, auto-created from HEAD at the first task
- [x] **≥2 task commits** on `sunoku/m1` — 3 present (T-1, T-2, T-3-blocked record)
- [x] **`bash test.sh` → PASS** on the branch (green M1 skeleton, minus the impossible task)
- [x] **main untouched** — 1 commit, no branch work leaked to the default branch
- [x] **no journal entry** while M1 incomplete — JOURNAL.md still holds only its stub sentinel
      (canon: a `track` entry is written *only* at milestone completion; M1 blocked out ≠ complete)
- [x] **blocked-out boundary + END** — run 3 reported the blocked chain (T-3 reason, its flag, that
      M2's T-4 does not depend on it) and what a human must decide; run 4 re-confirmed the boundary
      byte-for-byte (record + branch hash identical before/after — the loop parks idempotently at a
      blocked boundary, no churn) and emitted `END — M1 blocked out …`

**Variant F2 — milestone completion gates at the boundary (1 invocation)**

Human-unblock stand-in done the honest, internally-consistent way: the human **corrects** T-3's
impossible spec to a satisfiable one (`whisper.sh` lowercases `$1`), re-opens it `todo`, clears the
Blocked row, resolves the QUESTIONS flag, and extends `test.sh` — committed as a `human:` commit.
The loop then completes M1's last task *within the iteration* and must decide at the boundary.

- [x] **exit criteria checked one by one** — run reads ROADMAP M1 criteria and reports each met with
      evidence (`bash test.sh` → PASS ✓; farewell.sh + shout.sh exist ✓)
- [x] **exactly one `track` journal entry appended** — a single `## 2026-07-03 — track` for **M1**,
      listing the tasks that landed; status.json `updated` bumped (canonical serialization intact)
- [x] **END at the boundary, did NOT start T-4** — transcript states verbatim "That's a milestone
      boundary — the loop ends at milestone completion; M2 needs a fresh invocation"; `END — M1
      complete; re-run /sunoku:work to start M2.`; **no `sunoku/m2` branch created**
- [x] **M2 still untouched** — T-4 remains `todo`

**Result: PASS (main run 11/11; F2 8/8).** The work loop executed the approved plan one task per
invocation, honored a dependency, blocked an unsatisfiable task without vandalizing a green suite,
kept the default branch clean, journaled only at a completed milestone, and — the reviewer's flagged
concern — **routed cleanly through step 8's milestone-complete boundary to `END`, gating at the
milestone rather than auto-continuing into M2.** No plugin defect surfaced; the step-7-Pass →
step-9 path is empirically sound. Runtimes: run 1 ~1m24s, run 2 ~1m22s, run 3 ~2m22s, run 4 ~0m40s;
F2 ~1m40s (~7m30s total across the 5 counted invocations, plus discarded diagnostic re-runs).

**Fixes made during this run:** none to plugin files. All behavior was correct on the exercised
runs. Three test-harness (not plugin) adjustments, honestly noted:

- **Invocation flags.** The brief's `--permission-mode acceptEdits` is too tight for a skill whose
  core job is running `git` — under it the loop correctly armed, picked T-1, set it `doing`, then
  found `git checkout -b sunoku/m1` needs an approval a non-interactive `-p` session can't grant, so
  it truthfully reverted T-1 to `todo` and ENDed asking for git permission. Also, `canon.md` (a
  plugin file outside the fixture) was blocked by the working-dir sandbox. Switched to the
  documented house harness `--permission-mode bypassPermissions` and added
  `--add-dir <plugin-root>` so canon is readable. Both are RUN-PROMPT/harness fixes, not plugin
  edits; the skill's degraded-path reasoning under the tight harness was itself correct.
- **Assertion regex.** The brief's task-commit count `grep -c "^.\{8\} T-"` assumes an 8-char
  abbreviated SHA; `git log --oneline` abbreviates to 7 here, so it under-counted to 0. The real
  count is 3 (width-agnostic `^[0-9a-f]+ T-`), well over the `>=2` bar. Same class of harness-only
  regex fix noted for the A–C run; no assertion was weakened.
- **F2 fixture setup.** The brief's F2 python flips only the T-3 Status cell. Run verbatim, that
  leaves the Blocked table row and QUESTIONS flag still asserting T-3 is unsatisfiable — an
  internally-contradictory record. The loop (correctly, and more rigorously than the brief assumed)
  **refused to honor the half-edit as a fake pass** and re-emitted the blocked-out boundary,
  writing nothing. Recorded as a finding; F2 was then run the faithful way (human corrects the spec,
  re-opens todo, clears the block — all committed), which is what exercises the completion-gate path
  above. A pre-completing manual flip (M1 already fully `done` before invocation) was also tried and
  showed the loop then legitimately treats M2 as the current milestone and works T-4 — expected per
  the eligibility rule, not a boundary breach; the gate is only exercised when the loop completes a
  milestone's last task *within* an iteration, which F2-faithful does.
