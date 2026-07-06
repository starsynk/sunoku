---
name: track
description: Internal — model-invoked consent gate, not a user command. Fires when a work prompt would reshape the PRD (scope, core bet, architecture, target segment, pricing) on a live record. Asks the user before any tracking; on consent hands off to sunoku:prd reshape mode.
user-invocable: false
---

## Mission

Detector + consent gate + handoff. This skill writes nothing, ever.

## Flow

1. Guard: `.sunoku/status.json` has `lifecycle: live` and `tracking: true`; otherwise do
   nothing and continue with the user's actual request.
2. You detected that the prompt's work would change the product story — name which part:
   scope, core bet, architecture, target segment, or pricing. If you cannot name the part, it
   is implementation work: stop here, stay silent, do the work.
3. Ask ONE question before any tracking, recommended option first:
   "This looks like it reshapes the PRD (<part>): <one-line what>. Update the PRD?
   (a) update — recommended (b) skip tracking".
   Never auto-track. Never ask twice for the same change in a session.
4. (a) → invoke `sunoku:prd` (reshape mode) with the change and affected part; its Change Log
   row IS the tracking. (b) → proceed with the work; the record stays untouched.

## Never

- Never fire for bugfixes, styling, refactors, perf, config, copy, or feature work already
  inside the PRD's scope — silent is the default; a noisy tracker is a broken tracker.
- Never journal, log, or write any file — v2 has no journal.
