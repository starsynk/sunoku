---
name: using-sunoku
description: Use when starting any conversation in a project with a .sunoku/ record — establishes how Sunoku skills route product work, before any response or action
---

# Using Sunoku

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

## Overview

This project keeps a living product record in `.sunoku/`: `PRD.md` (current truth; its Change
Log table is the ONLY history), `status.json`, `tasks.jsonl`, `decisions.jsonl` (all three
script-written only — a hook denies hand edits), and `research/*.md`. Sunoku plans and
documents; it NEVER writes application code, never executes tasks.

**The rule:** before responding to any product-shaped prompt — scope, features, market,
priorities, "what's next", "why did we..." — check the routing table and invoke the matching
skill FIRST. Implementation work (bugfixes, styling, refactors, perf, config, copy, in-scope
features) is silent: no record write, no mention of Sunoku.

## Routing

| Prompt looks like | Skill |
|---|---|
| "status", "what's next", "where are we", mute/unmute tracking | sunoku:checking-status |
| "show tasks", "task board", "open the backlog in a browser", "show decisions visually" | sunoku:viewing-the-record |
| "what does the PRD say", "why did we drop X", "what changed since May", task state | sunoku:querying-the-record |
| "write/update the PRD", "we're adding/dropping X", "refresh PRD from code" | sunoku:writing-the-prd |
| "break this into tasks", "plan the build", "re-plan" | sunoku:planning-the-work |
| "deep research X", "who are the competitors", "validate demand" | sunoku:researching |
| Work prompt that would reshape the PRD (scope, core bet, architecture, target segment, pricing) on a live record | sunoku:tracking-changes |
| "set up sunoku" in a project that already has a record | sunoku:checking-status (never re-init) |

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll just answer from the PRD I remember" | Records change. sunoku:querying-the-record cites current rows. |
| "This scope change is small, I'll track it silently" | NEVER auto-track. sunoku:tracking-changes asks first, always. |
| "I'll update status.json/tasks.jsonl directly" | Machine files are script-written only. The guard hook will deny you. |
| "The backlog task is right there, I'll build it as Sunoku" | Sunoku never executes. Any executor works tasks; Sunoku records. |
| "Staleness means the PRD drifted — I should refresh it" | Commits landing = executors working the plan. Only the user calls drift. |

## User Instructions

User instructions (CLAUDE.md, direct requests) take precedence over Sunoku skills. Only skip a
skill's workflow when your human partner explicitly says so.
