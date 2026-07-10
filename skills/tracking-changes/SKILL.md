---
name: tracking-changes
description: Internal — model-invoked consent gate, not a user command. Use when a work prompt would reshape the PRD (scope, core bet, architecture, target segment, pricing) on a live record, before doing that work
user-invocable: false
---

# Tracking Changes

## Overview

Detector + consent gate + handoff. This skill writes nothing, ever. Silent is the default —
a noisy tracker is a broken tracker.

## Fire or Stay Silent

```dot
digraph track_fire {
    "Record live AND tracking on?" [shape=diamond];
    "Can you NAME the reshaped part\n(scope, core bet, architecture,\ntarget segment, pricing)?" [shape=diamond];
    "Stay silent. Do the user's work." [shape=box];
    "Ask the ONE consent question" [shape=box];

    "Record live AND tracking on?" -> "Stay silent. Do the user's work." [label="no"];
    "Record live AND tracking on?" -> "Can you NAME the reshaped part\n(scope, core bet, architecture,\ntarget segment, pricing)?" [label="yes"];
    "Can you NAME the reshaped part\n(scope, core bet, architecture,\ntarget segment, pricing)?" -> "Stay silent. Do the user's work." [label="no — it's implementation work"];
    "Can you NAME the reshaped part\n(scope, core bet, architecture,\ntarget segment, pricing)?" -> "Ask the ONE consent question" [label="yes"];
}
```

## The Consent Question

Ask ONE question before any tracking, recommended option first:

> "This looks like it reshapes the PRD (<part>): <one-line what>. Update the PRD?
> (a) update — recommended (b) skip tracking"

- (a) → invoke sunoku:writing-the-prd (reshape mode) with the change and affected part; its
  Change Log row IS the tracking.
- (b) → proceed with the work; the record stays untouched.

Never ask twice for the same change in a session.

## Red Flags

| Thought | Reality |
|---------|---------|
| "It's clearly a scope change, I'll just log it" | NEVER auto-track. Consent first, every time. |
| "Bugfix touches the architecture section topic" | Bugfixes, styling, refactors, perf, config, copy, in-scope features: silent. |
| "I'll jot this in a journal for later" | This skill writes nothing, ever. There is no journal. |
| "I can't name which part changes, but it feels big" | Can't name the part = implementation work. Stay silent. |

## Integration

- **REQUIRED SUB-SKILL on consent:** sunoku:writing-the-prd (reshape mode).
