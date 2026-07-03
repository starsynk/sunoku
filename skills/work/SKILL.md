---
name: work
description: Execute the Sunoku task backlog — arms a continuous loop that works .sunoku/TASKS.md one task per iteration until the current milestone completes. Use ONLY when the user explicitly invokes /sunoku:work or explicitly asks to execute/work the sunoku backlog. Never trigger proactively, never from a hook nudge, never because tasks merely exist. Requires a live record with a non-stub TASKS.md.
---

## Mission

You are the foreman, not the builder. Each iteration: pick exactly one eligible task, drive the
implementation to a verified finish, record the outcome in the living record, and tell the loop
whether to continue. The plan is already approved — PRD, roadmap, and task trace carry the design
authority — so you execute it; you never redesign it mid-run.

## Flow

1. **Read canon first.** Read `${CLAUDE_PLUGIN_ROOT}/reference/canon.md` in full before doing
   anything else. Obey its Work loop, Assumptions, and StatusFile sections verbatim — this skill
   does not restate their rules, only sequences them.

2. **Guards** — check in order; on any failure report the reason in one line, name the skill that
   fixes it, and END (step 9) without arming:
   - `.sunoku/status.json` exists and `lifecycle` is `live` — else route to `sunoku:init`.
   - `.sunoku/TASKS.md` exists, is non-empty, and its first line is not `<!-- sunoku:stub -->` —
     else report "no task backlog" and route to `sunoku:status` (it offers the PLAN pass or gap
     roadmap that creates one).

3. **Arm (fresh user invocations only).** A loop wakeup re-firing `/sunoku:work` skips this step
   entirely — re-arming from inside the loop is forbidden, and loops never nest. On a fresh user
   invocation with no loop active: invoke the built-in `loop` skill with `/sunoku:work` as its
   payload (dynamic pacing, no interval), then continue into step 4 as the first iteration. If
   this client has no loop skill, say so in one line and continue — each invocation then
   completes one task, and the closing signal (step 9) tells the user to re-invoke.

4. **Pick one task.** Read `.sunoku/TASKS.md` fresh from disk — the file, not memory, is the
   loop's state. Identify the current milestone and the one task to work per canon Work loop
   eligibility (resume `doing` first, else first dependency-clear `todo`; never a later
   milestone). If nothing qualifies, jump to step 8. Set the chosen task's Status to `doing` and
   write TASKS.md before touching anything else.

5. **Branch.** All work lands on the milestone branch `sunoku/m<n>` (n = current milestone
   number). If it does not exist, create it from the current HEAD; if it exists, check it out.
   Never work on the repo's default branch. If the working tree is dirty with changes you did not
   make, note it for the report and leave those files strictly alone. If the user asked for
   isolation when arming ("run this in a worktree"), do the run in an isolated worktree on this
   branch — the harness's native worktree mechanism if it has one, else `git worktree add` — and
   say once that `.sunoku/` updates ride the branch until merge; default is the current checkout.

6. **Execute.** Implement the task in the consumer repo — you, the main assistant, write this
   code; never dispatch a Sunoku agent to write it. Ground rules:
   - The task text plus its PRD trace define scope. Design-approval-style gates from other
     plugins are already satisfied by the approved PRD → roadmap → task chain; execution-side
     practices (test-first, systematic debugging, verification before completion) are welcome.
   - Write or extend tests where the task is testable; run the project's own test/build
     verification (canon done bar).
   - Up to three attempts this iteration. An attempt = a distinct implementation approach that
     ends in failed verification, not a syntax retry.
   - Never ask the user anything mid-iteration: inferable → canon Assumptions default-and-flag
     (QUESTIONS.md); non-inferable or high-stakes → give up the attempts and treat as failed.

7. **Record the outcome**, then commit:
   - **Pass** — Status → `done` in TASKS.md. Stage the task's changes plus TASKS.md and commit
     on the milestone branch: `T-<n>: <task title>`.
   - **Fail after 3** — Status → `blocked`; add a row `| T-<n> | 3 | <one-line reason> |` to the
     `## Blocked` table; append a canon-format flag to QUESTIONS.md naming what decision or fix
     would unblock it. Commit only the record files: `T-<n>: blocked — <reason>`. Code from
     failed attempts is reverted, not committed.

8. **Boundary (reached when step 4 found nothing eligible):**
   - **Milestone complete** (every task `done`): read the milestone's exit criteria from
     `.sunoku/ROADMAP.md` and report each as met/unmet with one line of evidence. Append one
     `track` journal entry to `.sunoku/JOURNAL.md` (canon journal format): what landed, what's
     blocked. Update status.json `updated` (canonical serialization). Then offer, interactively
     and only now: push `sunoku/m<n>` and open a PR whose body is this report (skip the offer if
     no remote or no `gh`). END.
   - **Blocked out** (remaining tasks all blocked or downstream of blocked): report the chain —
     each blocked task, its reason, its QUESTIONS.md flag — and what a human must decide. No
     journal entry (the milestone did not complete). END.
   - **Backlog empty** (no milestone has a non-`done` task): report the whole plan finished. END.

9. **Signal — the last line of every iteration, exactly one of:**
   - `CONTINUE — <k> eligible task(s) remain in M<n>.` → the loop schedules the next iteration.
   - `END — <boundary reason>.` → the loop stops; nothing re-arms it without a fresh
     user invocation. When the loop skill was unavailable (step 3), phrase it as
     `END — <reason>; re-run /sunoku:work to continue.` if eligible tasks remain.

## Mid-run conversation

The user talking to the session while the loop is armed is normal: answer from TASKS.md state,
change nothing, and let the next wakeup proceed. If the user says stop, stop — leave the `doing`
task as-is (the next run resumes it) and END on the spot. If Sunoku's own stop-time nudge fires
mid-run (code changed, journal didn't), acknowledge and defer it: milestone-level journaling is
the sanctioned discipline during an active loop, and the boundary entry satisfies the nudge.
