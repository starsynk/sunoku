---
name: starting-a-product
description: Use when the user wants to set up Sunoku, asks "is this idea worth building?", wants to validate or plan a new product, or wants an existing repo documented as a product record
disable-model-invocation: true
---

# Starting a Product

## Overview

User-only orchestrator: route by origin, chain the working skills, hold exactly three
checkpoints — go/no-go, PRD approval, and the task-breakdown offer. Sunoku never writes
application code and never touches anything outside `.sunoku/`.

**Announce at start:** "I'm using the sunoku:starting-a-product skill to set up the record."

## Checklist

Create a todo for each item:

1. Route on the record (existing record → hand off, stop)
2. Scope and scaffold (references/onboarding.md)
3. Run the origin's flow to an approved PRD
4. Offer the task breakdown (fresh-idea path only)
5. Go live

## Process Flow

```dot
digraph starting_a_product {
    "Record exists (.sunoku/status.json)?" [shape=diamond];
    "Hand off to sunoku:checking-status. STOP." [shape=box];
    "Scope + scaffold (references/onboarding.md)" [shape=box];
    "Origin?" [shape=diamond];
    "sunoku:writing-the-prd (existing mode)" [shape=box];
    "Validate the bet first?" [shape=diamond];
    "sunoku:researching (validation mode)" [shape=box];
    "Go / no-go checkpoint" [shape=diamond];
    "rm -rf .sunoku — nothing kept. STOP." [shape=box];
    "status-write --set lifecycle=defining" [shape=box];
    "sunoku:writing-the-prd (create mode)" [shape=box];
    "Offer sunoku:planning-the-work once" [shape=box];
    "Go live" [shape=doublecircle];

    "Record exists (.sunoku/status.json)?" -> "Hand off to sunoku:checking-status. STOP." [label="yes"];
    "Record exists (.sunoku/status.json)?" -> "Scope + scaffold (references/onboarding.md)" [label="no"];
    "Scope + scaffold (references/onboarding.md)" -> "Origin?";
    "Origin?" -> "sunoku:writing-the-prd (existing mode)" [label="existing codebase"];
    "Origin?" -> "Validate the bet first?" [label="new idea"];
    "Validate the bet first?" -> "sunoku:researching (validation mode)" [label="validate"];
    "Validate the bet first?" -> "sunoku:writing-the-prd (create mode)" [label="committed"];
    "sunoku:researching (validation mode)" -> "Go / no-go checkpoint";
    "Go / no-go checkpoint" -> "rm -rf .sunoku — nothing kept. STOP." [label="NO-GO accepted"];
    "Go / no-go checkpoint" -> "status-write --set lifecycle=defining" [label="GO"];
    "status-write --set lifecycle=defining" -> "sunoku:writing-the-prd (create mode)";
    "sunoku:writing-the-prd (create mode)" -> "Offer sunoku:planning-the-work once";
    "sunoku:writing-the-prd (existing mode)" -> "Go live";
    "Offer sunoku:planning-the-work once" -> "Go live";
}
```

Notes on the boxes:

- **Route on the record**: if `.sunoku/status.json` exists, say so in one line (product,
  lifecycle) and hand off to sunoku:checking-status. No re-init, no writes.
- **Scope + scaffold**: read
  `${CLAUDE_PLUGIN_ROOT}/skills/starting-a-product/references/onboarding.md` and follow it —
  it collects product name, one-liner, origin, and for new ideas the validate-or-committed
  choice, then scaffolds.
- **Go/no-go checkpoint**: present sunoku:researching's recommendation, recommended option
  first. NO-GO accepted → delete `.sunoku/` entirely (`rm -rf .sunoku`), tell the user nothing
  is kept and why that is fine (re-pitching means fresh validation). GO →
  `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --set lifecycle=defining`.
- **Breakdown offer**: fresh-idea path only, offered ONCE after PRD approval: "want a task
  breakdown (milestones, epics, parallel-ready tasks)?" Existing-codebase records get
  planning on demand later, not an init offer.
- **Go live**:
  `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --set lifecycle=live --set tracking=true`,
  then close by naming the surface: sunoku:checking-status for state and next action,
  sunoku:writing-the-prd for PRD changes, sunoku:planning-the-work for breakdown,
  sunoku:researching for deep dives; record questions are answered automatically
  (sunoku:querying-the-record), reshapes are detected with consent
  (sunoku:tracking-changes).

## Discipline

- **Three checkpoints only** (go/no-go, PRD approval, breakdown offer). Anything else a run
  wants to ask becomes a `decisions.jsonl` row with a recommended default — the fired skill
  logs it and continues.
- `status.json` is script-written only: `scaffold.mjs` creates it, `status-write.mjs` mutates
  it.

## Integration

- **REQUIRED SUB-SKILL:** sunoku:researching (validation mode) on the validate path
- **REQUIRED SUB-SKILL:** sunoku:writing-the-prd (create or existing mode)
- Offered once after PRD approval: sunoku:planning-the-work
