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

Last run: **2026-07-02** (model under test: sonnet; subagents: sonnet).

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

## Fixes made during this run

- None to plugin files. All three greenfield paths behaved correctly on the first exercised run;
  no plugin defect was found. (One assertion-script regex bug was fixed in the test harness only.)
