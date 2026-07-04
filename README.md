# Sunoku

A Claude Code plugin that keeps a living record of a software product — why it exists, what it
actually is right now, and what changed since the last time you looked.

## The living record

Most planning tools produce a document, then let it rot. Sunoku produces a record that keeps
being true. The record lives in `.sunoku/` at the root of your repo: a journal of what changed
and why, an evidence trail behind every research claim, an open-questions list, and a PRD.

The PRD is not the deliverable. It's a snapshot — the current-state view of an ongoing chronicle
that the journal keeps writing. Every time something reshapes the product (a scope change, a
pivot on the core bet, a new target segment, a different architecture, a pricing change), Sunoku
reconciles the PRD forward and leaves a journal entry explaining why. Every time something doesn't
reshape the product (a bugfix, a refactor, a style pass), Sunoku stays silent — the record doesn't
get noisier just because the repo did.

This is the test the whole plugin is built to pass: come back in six months and ask "what is this
product now, what changed since March, and why did we drop feature X?" A good record answers all
three with evidence — file:line citations, dated journal entries, an evidence ledger behind every
research claim — not with a stale doc and someone's fuzzy memory of a Slack thread.

## The four phases

**VALIDATE.** For a greenfield idea, Sunoku first asks whether it's worth building at all.
Research and feasibility agents work in parallel to build an evidence table, a red-team pass
stress-tests the claims, and the whole thing resolves to one checkpoint: go, no-go, or go-if. A
no-go is not a failure state — it's a shelved record with an immutable report explaining exactly
why the idea died, so nobody re-litigates it from scratch next year. VALIDATE is also optional: if
you tell Sunoku you're already committed to building this, it skips validation entirely and moves
straight to defining the product — that's a first-class path, not a shortcut you have to fight for.

**DEFINE.** Product, design, and architecture get drafted in parallel from the validated brief (or
the commitment, if VALIDATE was skipped), then red-teamed for gaps and contradictions. The output
is `PRD.md` — problem, personas, features, architecture, UX, out of scope, success metrics,
commercial, and a change log that starts empty and fills in over the product's life. Approving the
PRD is a checkpoint: nothing downstream treats it as current-state truth until you've signed off.

**PLAN** *(optional)*. Sunoku offers a build plan once — a milestone roadmap and task breakdown —
and takes no for an answer. Planning somewhere else (Linear, a whiteboard, your own head) is a
completely reasonable choice; skipping this phase costs you a roadmap, not your tracking. If you
accept, you get one more checkpoint: approve the roadmap before it's the plan of record.

**TRACK.** This is the phase that never ends. Once armed, Sunoku runs a standing triage on every
change: would the PRD or roadmap need editing to stay accurate? If no, it says nothing — silence
is correct, not a bug. If yes, it appends a journal entry (and a task row, if there's a roadmap).
If the change reshapes the product, it runs a scoped re-dispatch to the owning agents, presents
the full delta as one checkpoint, and reconciles the journal, PRD, and roadmap together. The
journal only earns entries that actually change the story — that's what keeps it worth reading
later.

## Onboarding both product types

**Greenfield.** Point Sunoku at an empty repo or a one-line idea and it runs the scoping →
VALIDATE → DEFINE → PLAN → TRACK sequence above, asking at most a handful of batched questions
along the way (segment, wedge, monetization, constraints, and whether you're already committed).

**Existing codebase.** Sunoku joins like a new tech lead. It reads the repo — source tree,
manifests, existing docs — and writes down what it learned as an as-built PRD, every claim cited
`file:line`. Then it hands that read back to you with one line: "here is what I understood your
product to be — correct me." That's the accuracy gate: a single checkpoint where misreads get
fixed before anything becomes canon. The moment you approve, Sunoku arms tracking immediately —
memory-first, before it even asks the next question. Only after tracking is live does it offer a
one-time extra: a gap roadmap over the must-have features it noticed aren't built yet. Say no and
you still walk away with a fully live, tracking record.

There's no separate "onboarding mode" to pick. Both paths run through the same command, and Sunoku
figures out which one you're in by looking at whether the repo has source code yet.

## Install

Add this repo as its own plugin marketplace, then install the plugin:

```
/plugin marketplace add starsynk/sunoku
/plugin install sunoku
```

(Substitute the actual path or URL you cloned/forked this repo to — the marketplace source is
just this repo's root.)

For local development, skip the marketplace and point Claude Code straight at your checkout:

```
claude --plugin-dir /path/to/sunoku
```

**Runtime note:** everything mechanical — the ambient hooks (session-start context, stop-time
nudge, the status.json write guard) and the record scripts — runs on Node ≥18, the same runtime
Claude Code itself needs. No shell dependency, no platform caveats.

**Upgrading:** nothing to migrate by hand. Records written by an older plugin self-migrate in
place the next time any Sunoku command touches them (the session-start hook flags the version
skew and points the way; running `sunoku:status` once migrates immediately). What changed per
release is in [CHANGELOG.md](CHANGELOG.md); the exact record fixes live in
[reference/MIGRATIONS.md](reference/MIGRATIONS.md).

## Layout

- `reference/canon.md` — always-read core rulebook; per-lane sections live in `reference/canon/`
  and load on demand (see the canon Disclosure map).
- `reference/contracts/` — per-hat output contracts for multi-hat agents, named in dispatches.
- `skills/*/references/` — lane and phase procedures loaded only when that branch runs.
- `scripts/` — zero-dependency Node (≥18) scripts that perform every mechanical record write:
  canonical status.json serialization, journal append + rollover, question flushes, task-status
  flips, scaffolding, resume done-maps, migrations, and the one-call status report. Skills
  decide *what* to record; these scripts make the bytes deterministic. Read-mostly extras:
  `doctor.mjs` (record integrity check, every finding names its fix), `digest.mjs` (a
  stakeholder one-pager under `.sunoku/digest/`, regenerate-anytime), and `release-notes.mjs`
  (journal window → changelog draft on stdout).

## The three commands

There's exactly one command to learn: **`sunoku:init`**. It creates the record if none exists,
resumes one that's mid-phase, or hands off to status if the record is already live. Everything
else is discovered from there — `sunoku:log` and `sunoku:status` get surfaced to you once
tracking is armed, and `sunoku:init` itself will refuse to re-initialize a live record and route
you to status instead.

- **`sunoku:init`** — start here, always. Validates and defines a new product, or reads an
  existing codebase and drafts its as-built PRD. Arms tracking when it's done. A freshly
  generated scaffold (create-next-app, rails new, any starter) counts as a new product, not an
  existing codebase — the scaffold becomes your recorded starting stack, and Sunoku confirms
  that reading during scoping.
- **`sunoku:log`** — record a change or decision. Usually you won't call this directly; the
  session-stop hook nudges you to run it when code changed but the journal didn't. Runs the
  SILENT / TRACK / RESHAPE triage and does exactly as much ceremony as the answer requires.
- **`sunoku:status`** — the ongoing surface. Current product state, recent journal entries, open
  questions, a drift check against the last reconciled commit (with a reconcile offer), and
  answers to history questions straight from the journal and PRD change log (tag- and
  window-scoped via `report.mjs --since/--tag`). Also on request: a record health check
  ("check the record"), a stakeholder digest ("digest"), and — when the newest validation
  report is over six months old — a re-validate pass that writes a fresh dated report beside
  the immutable old one.
Sample prompts:

- "is this worth building?" — kicks off VALIDATE on a new idea.
- "document this repo" — kicks off the existing-codebase flow on a repo that already has code.
- "what changed since May?" — asks `sunoku:status` to answer from the journal and change log.

To go quiet without losing history, mute tracking: ask `sunoku:status` to turn tracking off (it
flips `tracking: false` in `status.json`), and the ambient hooks stop nudging while the record
stays intact for whenever you turn it back on. Drift and reconcile work together: if commits land
without a matching journal entry, `sunoku:status` reports how many and offers to reconcile, which
reads the actual diff, groups it, and runs each group through the same triage as `sunoku:log`.

## Executing the backlog

Sunoku deliberately ships no executor. `TASKS.md` is an open contract — statuses
`todo / doing / done / blocked`, a `Blocked` table, dependency-ordered milestones with a
walking-skeleton M1 — that anything can work: you by hand, a plain Claude session, whatever
process plugins you already run (your TDD, your plan-execution discipline, your review gates), or
a loop you arm yourself (e.g. `/loop` with "work the next eligible task in `.sunoku/TASKS.md`").
Whatever executes, your other plugins stay fully live — canon's Coexistence rule: a Sunoku flow
settles product-design authority, which the approved PRD and roadmap already carry, and
suppresses nothing else.

Executors that update `Status` keep the record realtime. Executors that never touch it cost
nothing: the next reconcile reads the actual diff and flips landed tasks to `done`. Either way
the journal stays milestone-grained and the record stays true.

### With Claude Code's `/loop`

The built-in `/loop` skill re-fires a prompt until you stop it — pair it with a
one-task-per-iteration prompt and you get a hands-off executor whose state lives in `TASKS.md`,
not in the conversation:

```
/loop Work exactly one task from .sunoku/TASKS.md this iteration: resume the `doing` row if one
exists, else take the first `todo` in the current milestone whose "Depends on" IDs are all done.
Mark it doing first, implement it with tests on a work branch (never the default branch), verify
with the project's own test/build, then mark it done and commit as "T-<n>: <title>". If it won't
verify after 3 distinct attempts, mark it blocked with a reason in the Blocked table, flag what
would unblock it in .sunoku/QUESTIONS.md, and move on to a task that doesn't depend on it. Never
ask me questions mid-run — take the inferable default and flag it in QUESTIONS.md. When the
milestone has no eligible task left, report each ROADMAP exit criterion as met/unmet and stop
the loop.
```

Notes from running exactly this shape for a release:

- **Run it in a session that can edit and run git/tests without prompting** — one permission
  dialog stalls an unattended iteration until you come back. `acceptEdits` alone still prompts
  on `git` and test commands; pair it with an allowlist covering both, or use a fully
  pre-approved session.
- **One task per iteration** keeps every wakeup small and makes the file the loop's memory: the
  run can die or be interrupted at any point and the next invocation resumes from the `doing`
  row.
- **The milestone boundary is your review gate.** Let the loop stop there, review the branch,
  merge, re-arm for the next milestone.
- Your other plugins keep firing inside each iteration — TDD, systematic debugging,
  verification, house conventions. That's canon's Coexistence rule working as intended: the
  task's *design* is settled by the PRD trace; the *craft* is not.

### Other shapes

- **Attended, one task at a time** — the same prompt without `/loop`; you review between tasks.
- **Your own process end-to-end** — run whatever plan-execution discipline you already use
  against the task list, ignore `Status` entirely, and let the next reconcile
  (`sunoku:status`) flip landed tasks to `done` from the diff.

## License

MIT — see [LICENSE](LICENSE).
