---
name: init
description: Create or resume the Sunoku living record — the only command a user must learn. Use for "is this idea worth building?", "validate this idea", "plan/define this new product", "document this repo/codebase", "set up sunoku", "onboard this project". If a record is already live, hands off to sunoku:status.
---

## Mission

You are the orchestrator and the sole integrator. This skill creates the Sunoku living record for a
repo, or resumes one that a previous run left half-built. You never write application code and never
touch anything outside `.sunoku/`. You are the only writer of `status.json`. Every unit of real work
fans out to a subagent and reports back to you; agents never message each other.

## Flow

1. **Read canon first.** Read `${CLAUDE_PLUGIN_ROOT}/reference/canon.md` (core) in full, then load
   exactly the `reference/canon/` files the Disclosure map names for "init — any phase". Obey them
   verbatim. This skill invokes those rules in order below and does not restate them. Every
   dispatch you issue names the five required things from canon Dispatch (absolute `.sunoku/` path,
   exact files to read, exact files to write, the section list
   the output must contain, and the closing "delete the stub sentinel and return a one-paragraph
   summary" instruction). Templates you scaffold live under `${CLAUDE_PLUGIN_ROOT}/reference/templates/`.

2. **Route on `.sunoku/status.json`.** Read it (if present) and branch on `lifecycle`, in this
   order — the first match wins and you do exactly that branch, nothing else:

   - **`live`** → refuse to re-initialize. The record already exists and is tracking. Give the user
     one line of state (product name, `lifecycle: live`, tracking on/off from the file) and hand off
     to `sunoku:status` by name for the ongoing surface. Make no writes. Stop.
   - **`shelved`** → read `.sunoku/JOURNAL.md`, find the `decision` entry (or entries) that recorded
     the kill, and present that shelving rationale in the user's terms. Then ask one question: revive
     or keep it shelved. Default is to respect the kill — if the user does not clearly ask to revive,
     keep it shelved and stop. On revive, re-enter at the phase the shelving interrupted (read the
     journal + sentinels to see how far the interrupted run got). A greenfield NO-GO revive re-enters
     VALIDATE fresh and produces a NEW dated report beside the old one (the old report is immutable —
     never edit or delete it); set `lifecycle` back to `validating` and resume step 4's VALIDATE.
   - **`validating` / `defining` / `planning`** (phase-in-progress) → resume. Do not restart the
     phase and never clobber an artifact that passes its done-check (canon Sentinels: exists +
     non-empty + sentinel absent; ledgers need ≥1 real row). Within the phase named by `lifecycle`,
     walk the phase's ordered steps, find the furthest step whose artifacts are all done, and
     continue from the first not-done step. Announce in one line exactly what you are resuming (e.g.
     "Resuming DEFINE: PRD Problem/Personas/Features done, picking up at the UX section"). Then
     proceed into the matching flow (step 4 greenfield / step 5 existing) at that step, loading the
     phase file this table names:

     | lifecycle at resume | origin | phase file to load |
     |---|---|---|
     | validating | greenfield | references/validate.md |
     | defining | greenfield | references/define.md |
     | defining | existing | references/existing.md |
     | planning | any | references/plan.md |
   - **absent** → fresh init. Detect the product type: run `git ls-files` (fall back to a directory
     listing if the repo is not initialized). Empty or docs-only → greenfield flow (step 4). Source
     present → do NOT assume existing-code yet; source can be a freshly generated scaffold
     (create-next-app, cargo new, rails new, a starter template — any generator, any stack). Apply
     the substance test: **"if this repo were deleted and its generator re-run, would anything of
     substance be lost?"** Judge it from signals, not a framework list:
       - git history shape — one or two generator-style commits ("Initial commit") vs real history
         with domain-specific messages;
       - domain vocabulary — files/identifiers named after a business domain (invoices, workouts,
         listings) vs only framework-generic names (app, page, layout, index, home, example, demo);
       - divergence from generator output — framework-default README, sample assets and demo pages
         still in place, dependencies ≈ the starter's defaults vs added domain libraries;
       - wiring — real user-facing routes/commands/endpoints beyond the starter's default page.
     Nothing of substance would be lost → **greenfield flow** (step 4): the scaffold is the chosen
     starting stack, not the product — record it in BRIEF.md Constraints and pass it to
     feasibility-assessor as an architecture given; confirm inside the scoping batch ("this repo
     holds a fresh <stack> scaffold with no product code — treating this as a new product to
     define on that stack; correct?"). Any real domain work present, however thin → existing-code
     flow (step 5); a thin product just yields a short as-built PRD and a longer gap list, which
     the accuracy gate handles. Signals genuinely conflicting → do NOT ask separately; fold the
     type question into the scoping batch of whichever flow you lean toward, and let the answer
     confirm or switch. Then scaffold (step 3) and run the chosen flow.

3. **Scaffold (fresh init only).** Create `.sunoku/` and its `research/` and `research/.fragments/`
   subdirectories. Copy `sunoku.gitignore` → `.sunoku/.gitignore` (verbatim). Copy the template
   stubs the chosen flow needs, sentinel line (`<!-- sunoku:stub -->`) intact — never strip it here;
   only the filling agent removes it:
   - **Both flows:** `BRIEF.md`, `PRD.md`, `JOURNAL.md`, `QUESTIONS.md`, `research/EVIDENCE.md`.
   - **Greenfield adds:** the `validation/` directory (empty — the dated report is composed later,
     not scaffolded from a stub in place).
   - `ROADMAP.md` / `TASKS.md` are scaffolded only if and when PLAN runs — a record without a roadmap
     is valid, so do not pre-scaffold them.
   Then write `status.json` in the canonical serialization (canon StatusFile: one key per line,
   two-space indent, exact key order `version` / `product` / `origin` / `lifecycle` / `tracking` /
   `last_reconciled_sha` / `created` / `updated`). Set `product` to a display name (inferred or
   asked in scoping), `origin` to the flow (`greenfield` or `existing`), `lifecycle` to the first
   phase (`validating` for greenfield that will validate, `defining` for existing or a committed
   greenfield skip), `tracking` to `false`, `last_reconciled_sha` to `""`, and `created` / `updated`
   to the current UTC timestamp. You are the only writer of this file for the whole run.

4. **Greenfield flow.** (canon Checkpoints bind you: only go/no-go, PRD approve, roadmap approve.)

   a. **Scoping.** Read anything already present (README, notes, scratch docs). Then ask ONE batched
      set of at most 5 genuinely-unanswerable questions — infer-first, only what you cannot
      reasonably derive: segment, wedge, monetization stance, hard constraints (team/stack/budget/
      deadline), and the commitment question ("are you already committed to building this?"). Do not
      sprinkle questions across the run; this is the only ask before the first checkpoint. Write
      `BRIEF.md` from the template's sections (Segment, Wedge, Monetization stance, Constraints,
      Commitment) and delete its sentinel. Log any inference you had to make as a flagged assumption
      in `QUESTIONS.md` (canon Assumptions format) rather than blocking on it.

   b. **Committed-already branch.** If the user says they are already committed to building it, VALIDATE
      is a first-class skip. Append a `decision` journal entry (canon header `## YYYY-MM-DD — decision`
      + **What/Why/Refs**) recording the skip and its reason; record "validation skipped — user
      already committed" in the BRIEF Commitment section. Set `lifecycle` to `defining` and go
      straight to step 4d (DEFINE). No validation report is ever produced for this record.

   c. **VALIDATE** (lifecycle `validating`).

      Run this phase from `${CLAUDE_PLUGIN_ROOT}/skills/init/references/validate.md` — read it now and
      follow it exactly.

   d. **On the verdict.** NO-GO accepted → append a `decision` journal entry (why), set `lifecycle`
      to `shelved`, and stop. The shelved record and its immutable report are the deliverable — this
      is a successful outcome, not a failure. GO or GO-IF accepted → each GO-IF condition becomes a
      high-stakes `Q-n` entry in `QUESTIONS.md`. Proceed to DEFINE: set `lifecycle` to `defining`.

      Run this phase from `${CLAUDE_PLUGIN_ROOT}/skills/init/references/define.md` — read it now and
      follow it exactly.

   e. **PLAN (optional).**

      Run this phase from `${CLAUDE_PLUGIN_ROOT}/skills/init/references/plan.md` — read it now and
      follow it exactly.

   f. **Arm TRACK** (one step, in this exact order): set `lifecycle` to `live`, `tracking` to `true`,
      and `last_reconciled_sha` to the current `git HEAD` (empty string `""` if the repo has no
      commits yet), writing the canonical `status.json`. Append a journal entry (`## YYYY-MM-DD —
      track`, **What:** "Sunoku record armed", **Why:** short arming note, **Refs:** the HEAD sha or
      "conversation"). Then tell the user the three-command surface: `sunoku:log` to record changes,
      `sunoku:status` for state and drift, and that `sunoku:init` will now hand off to status. If
      a roadmap was planned, add that `TASKS.md` is an open contract worked by any executor the
      user prefers (canon Execution contract) — Sunoku records outcomes, it never executes.

5. **Existing-code flow.** (`origin: existing`; VALIDATE is never offered.)

   a. **Scoping.** Infer-first from README, docs, and manifests (package.json, pyproject, go.mod,
      Cargo.toml, etc.). Ask at most 5 questions, only the genuinely-unanswerable ones (e.g. product
      display name, intended segment if the code doesn't reveal it, monetization stance). Write
      `BRIEF.md` (delete sentinel); log inferences as flagged assumptions in `QUESTIONS.md`. Ensure
      `status.json` has `origin: existing` and `lifecycle: defining`.

   b. **RECONSTRUCT** (lifecycle `defining`) through the gap-roadmap step.

      Run this phase from `${CLAUDE_PLUGIN_ROOT}/skills/init/references/existing.md` — read it now and
      follow it exactly.

## Discipline reminders

- **Checkpoints only.** The only pauses are go/no-go, PRD approve / accuracy gate, and roadmap
  approve (canon Checkpoints). Never stop mid-run for an unplanned question — batch it or make it a
  flagged assumption.
- **Assumptions flow to QUESTIONS.md.** When inference is required and it isn't worth a checkpoint
  slot, take the default and log it in `QUESTIONS.md` (canon Assumptions format); the run continues
  without waiting.
- **status.json is orchestrator-only.** You are its sole writer, always in the canonical
  serialization — hooks grep it byte-for-byte (`"tracking": true`, `"lifecycle": "live"`), so any
  reformatting breaks them even if the JSON stays valid. Every write updates `updated`; `created`
  never changes after the first write.
- **Garbage output → one corrective re-dispatch** that names the specific failure (canon Garbage
  output), then surface to the user if it comes back bad again. Never invent an agent's missing
  content to paper over a bad run.
