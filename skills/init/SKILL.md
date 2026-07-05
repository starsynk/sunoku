---
name: init
description: Set up Sunoku for a project — the one command to learn. Use for "set up sunoku", "is this idea worth building?", "validate this idea", "plan this new product", "document this repo". If a record already exists, hands off to sunoku:status.
disable-model-invocation: true
---

## Mission

User-only orchestrator. Route to the right flow, fire the skills that do the work, keep exactly
three checkpoints: go/no-go, PRD approval, and the task-breakdown offer. Sunoku never writes
application code and never touches anything outside `.sunoku/`.

## Flow

1. **Route on the record.** If `.sunoku/status.json` exists, say so in one line (product,
   lifecycle) and hand off to `sunoku:status`. No re-init, no writes. Stop.

2. **Scope.** No record: read `${CLAUDE_PLUGIN_ROOT}/skills/init/references/onboarding.md` and
   follow it — it collects product name, one-liner, origin (new idea vs existing codebase), and
   for new ideas the validate-or-committed choice, then scaffolds.

3. **Existing codebase** → invoke `sunoku:prd` (existing mode). After PRD approval, go to step 6.

4. **New idea, validate first** → invoke `sunoku:research` (validation mode). Present its
   go/no-go recommendation as the checkpoint, recommended option first:
   - **NO-GO accepted** → delete the `.sunoku/` directory entirely (`rm -rf .sunoku`), tell the
     user nothing is kept and why that is fine (re-pitching means fresh validation), and stop.
   - **GO** → run `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --set lifecycle=defining`,
     then invoke `sunoku:prd` (create mode).

5. **New idea, already committed** → skip validation, invoke `sunoku:prd` (create mode).

6. **Offer breakdown (fresh idea only).** After PRD approval on the new-idea path, offer
   `sunoku:plan` once: "want a task breakdown (milestones, epics, parallel-ready tasks)?" Run it
   if accepted. Existing-codebase records get plan on demand later, not an init offer.

7. **Go live.** Run
   `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --set lifecycle=live --set tracking=true`.
   Close by naming the surface: `sunoku:status` for state and next action, `sunoku:prd` for PRD
   changes, `sunoku:plan` for breakdown, `sunoku:research` for deep dives; questions about the
   record are answered automatically (sunoku:read), and reshapes are detected with consent
   (sunoku:track).

## Discipline

- Three checkpoints only (go/no-go, PRD approval, breakdown offer). Anything else a run wants to
  ask becomes a `decisions.jsonl` row with a recommended default — the fired skill logs it and
  continues.
- `status.json` is script-written only: `scaffold.mjs` creates it, `status-write.mjs` mutates it.
