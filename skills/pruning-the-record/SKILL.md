---
name: pruning-the-record
description: Use when the user explicitly asks to prune the record — "prune the record", "clear out done milestones", "clean up old decisions". User command only; never self-invoked, never suggested by other skills
disable-model-invocation: true
---

# Pruning the Record

## Overview

Prune clears what the record no longer needs to stay truthful: fully-done milestones,
resolved decisions whose answers already live in the PRD, superseded research files.
Milestones are archived in place — rows stay in `tasks.jsonl` flagged `archived`, drop
out of every list and status count, and appear in the record viewer's Archive tab;
`--unarchive-milestone` restores one. Decisions and research files are deleted — git
history is their archive. A row or file is prunable only when everything it asserts is
finished or represented elsewhere in the record. Prune never deletes the only copy of
an answer.

**Announce at start:** "I'm using the sunoku:pruning-the-record skill to prune the record."

## The Process

1. Guard: `.sunoku/status.json` exists; otherwise say there is no record and stop.
2. Guard: `git status --porcelain .sunoku` is clean. Git is the archive, so uncommitted
   record changes would be pruned without a recoverable snapshot. If dirty, ask the user
   to commit first (or get an explicit go-ahead to proceed anyway).
3. Build the candidate list — evidence attached to every item:
   - **Milestones:** `node "${CLAUDE_PLUGIN_ROOT}/scripts/tasks.mjs" --list all`. A milestone
     is a candidate when every task under it is `done`. Note cross-milestone deps: if a
     surviving task depends into a candidate, the script will refuse — order downstream
     milestones first or leave the upstream one for a later prune.
   - **Decisions:** `node "${CLAUDE_PLUGIN_ROOT}/scripts/decisions.mjs" --list resolved`.
     For each, search `PRD.md` (body and Change Log) for the answer. Candidate only with
     a quoted line proving absorption. Resolved decisions with no trace go in a separate
     "kept — answer not in PRD/Change Log" section, with an offer to route through
     sunoku:writing-the-prd to absorb first.
   - **Research:** read each `.sunoku/research/*.md` header. Candidate only when the
     direction is dead or the findings are folded into the PRD; say which.
4. Present ONE confirm list: every candidate with its evidence, the "kept" section, and a
   note that the PRD Change Log is never touched. User approves per item or per category;
   anything not approved survives.
5. Execute approved items only:
   - `node "${CLAUDE_PLUGIN_ROOT}/scripts/tasks.mjs" --prune-milestone <M-id>` per milestone
     (archives the rows; `--unarchive-milestone <M-id>` undoes a mistake)
   - `node "${CLAUDE_PLUGIN_ROOT}/scripts/decisions.mjs" --prune <D-id>` per decision
   - `rm` per approved research file
   If a script refuses, report its message verbatim and move on — never work around it.
6. Report what was archived (milestones) and deleted (decisions, research) — the scripts
   echo the affected rows — and suggest the user commit. An empty candidate list is a
   valid outcome: say "nothing prunable" and stop.

## Red Flags

| Thought | Reality |
|---------|---------|
| "The record looks bloated, I should suggest pruning" | Never. User command only — wait to be asked. |
| "The Change Log is huge, prune old entries" | The Change Log is the record's only history. Never pruned. |
| "This decision is resolved, that's enough" | Resolved is necessary, not sufficient. No PRD/Change Log trace = not prunable; offer absorb-first. |
| "Milestone is 9/10 done, close enough" | The script refuses partial milestones. Do not flip the last task or edit the file to force it. |
| "The guard hook blocked my edit, I'll write the JSONL another way" | Correct behavior. The prune/unarchive verbs are the only archive path. |

## Integration

- Routes to: sunoku:writing-the-prd (absorb an unabsorbed resolved decision before pruning it).
- Invoked by: the user only. sunoku:checking-status and the gateway never suggest it.
