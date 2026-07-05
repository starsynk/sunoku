# Reshape mode

Input: the named change and which PRD part it touches (scope, core bet, architecture, target
segment, pricing — from the user directly or a sunoku:track handoff).

1. Read the current `.sunoku/PRD.md`; identify the exact sections affected. Small, surgical
   patches you write directly; a change rippling through 3+ sections goes to
   `sunoku:product-owner` (hat `reshape`, patch ONLY the named sections, same contract file).
2. Show the patch as a before/after diff of the affected sections. Checkpoint: approve
   (recommended) / adjust / drop.
3. On approval, in this order:
   - Apply the section edits.
   - Append one Change Log row: `| <today> | <what changed> | <why — the story-changing part> | <user|track|D-nnn> |`.
   - Resolve any decision row this answers (`decisions.mjs --resolve`).
   - `status-write.mjs --set one_liner="..."` if the one-liner changed.
4. If a task breakdown exists (`.sunoku/tasks.jsonl` non-empty), say in one line whether the
   reshape orphans or invalidates any epic and that `sunoku:plan` can re-plan it — do not
   re-plan unasked.
