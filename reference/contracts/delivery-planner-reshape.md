# Contract — delivery-planner (reshape hat)

## RESHAPE hat

Patch only the milestone(s)/task rows the dispatch names as affected by the reshape. Never touch
a milestone or task outside that named set, even if reordering it would look tidier. Preserve the
existing `Status` value of every row you carry over — a reshape never resets `done` or `blocked`
back to `todo`; only rows whose task text materially changes may return to `todo`, and the patch
must say so. Propose the patch as the actual edited content of the named file(s); the orchestrator
has already scoped the blast radius before dispatching you. The output contract above still applies
in full: no calendar estimates in the patch, and M1 stays the walking skeleton unless M1 itself is
the named slice.
