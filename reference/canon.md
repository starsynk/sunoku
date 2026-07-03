# Sunoku Canon

The shared rulebook. Every skill reads this file first via `${CLAUDE_PLUGIN_ROOT}/reference/canon.md`
and cites it in every dispatch to agents. If a skill or agent instruction conflicts with this file,
this file wins.

## Prime directive

Sunoku plans and documents products. Its planning and documentation agents never write application
code and never touch a consumer repo's source tree — Sunoku itself writes only `.sunoku/` at the
consumer repo root. Exactly one execution surface exists: `sunoku:work` (see Work loop), which on
explicit user invocation drives the main assistant — never a Sunoku agent — to implement tasks
from an approved plan. No external exports exist: nothing in this canon authorizes syncing the
record to any third-party system. The living record is the product: JOURNAL.md, EVIDENCE.md,
QUESTIONS.md, and status.json accumulate across the product's life. The PRD is not a one-time
deliverable — it is the current-state snapshot of that ongoing chronicle, reconciled forward as
the journal grows.

## Triage

Every change to a tracked product runs through one test before anything else. Ask it verbatim:

> "after this change, would the PRD or roadmap need editing to stay accurate?"

Route the answer into exactly one of three lanes:

- **SILENT** — bugfix, styling, refactor, perf, config, copy. Do nothing. No journal entry, no
  agent, no file touch.
- **TRACK** — fits the current direction and changes none of the reshape set. One journal entry,
  plus a task append if a roadmap exists. Zero ceremony: no subagents, no checkpoint gate.
- **RESHAPE** — changes one of the reshape set: **{core bet, product scope, architecture, target segment, pricing}**.
  Triggers a scoped re-run, exactly one checkpoint, and a reconcile pass: journal → PRD → roadmap,
  plus a Change Log row.

If the lane is ambiguous, default to TRACK and drop a flag in QUESTIONS.md. Never silently RESHAPE.
Noise is a product failure: an orchestrator that RESHAPEs on every small change, or that pauses for
ceremony on a SILENT change, has failed this canon as surely as one that skips a real reshape.

## Checkpoints

The complete set of checkpoints, and no others:

1. **Go/no-go** — before committing real work to a direction.
2. **PRD approve / accuracy gate** — before a PRD is treated as current-state truth.
3. **Roadmap approve** — before a roadmap is treated as the execution plan.
4. **One per RESHAPE** — exactly one checkpoint per RESHAPE event, no more.

No other pause points exist. An orchestrator never stops unplanned mid-run to ask a question —
questions get batched. Each checkpoint scopes to one batched question set, capped at 5 questions,
infer-first (only ask what cannot be reasonably inferred), folded into the first phase's entry
conversation rather than sprinkled across the run.

## Assumptions

When inference is required and a question isn't worth a checkpoint slot, take the default and log
it as a flagged assumption rather than blocking. Format, every field required:

- **Assumption** — what was assumed.
- **Chosen default** — the value used to keep moving.
- **Reasoning** — why that default.
- **Flip-if-wrong** — what changes if the assumption is wrong.
- **Stakes** — high or normal.

Log every flagged assumption to QUESTIONS.md immediately; the run continues without waiting.
Once 3 or more high-stakes assumptions have accrued, surface them inside the next checkpoint —
never as a standalone interruption — using this line verbatim:

> "I assumed X, Y, Z — confirm or this is built on sand."

## Dispatch (hub-and-spoke)

The orchestrator is the sole integrator. All work fans out from it and reports back to it — agents
never invoke or message each other, and upstream outputs pass downstream strictly read-only (a
downstream agent may read an upstream artifact but never write to it). Every dispatch to an agent
names, explicitly, in the prompt:

1. The absolute `.sunoku/` path the agent operates against.
2. The exact file(s) to read.
3. The exact file(s) to write.
4. The output contract: the section list the written file must contain.
5. The closing instruction, verbatim in substance: "delete the stub sentinel when you fill the
   file, and return a one-paragraph summary."

An agent that receives a dispatch missing any of these five is under-specified — the orchestrator
fixes the dispatch, not the agent.

## Fragments

Parallel writers never share a file. When two or more agents produce evidence in the same phase,
each writes its own fragment to `research/.fragments/<phase>-<agent>.md` — never to the shared
ledger directly. After the phase barrier (all dispatched writers for that phase have returned), the
orchestrator:

1. Concatenates every fragment onto `research/EVIDENCE.md`.
2. Deletes the fragment files.
3. Asserts fragment count == dispatched-writer count for that phase.

A missing fragment means a lost agent, not zero evidence. Surface the gap and re-dispatch that one
agent; never invent rows to make the count look right.

## Garbage output

If a dispatched agent returns output that is empty or violates its output contract (wrong sections,
missing file, wrote to the wrong path), the orchestrator issues exactly one corrective re-dispatch
that names the specific failure ("EVIDENCE.md fragment has no rows" / "architecture.md missing the
Rejected Alternative section"). If the re-dispatch still comes back bad, stop and surface the
failure to the user. Never invent the missing content to paper over a bad agent run.

## Conflict

When two agents' outputs disagree:

- **Evidence-resolvable** (a factual claim, a source discrepancy) — re-run the affected piece only.
  This retry loop is capped at 3 attempts total.
- **Judgment call** (a defensible difference of interpretation, not a fact) — resolve as a flagged
  assumption (see Assumptions) and continue; do not burn retries on taste.
- If the retry cap is hit and a blocking objection is still open, do not silently pick a side.
  Present the next checkpoint labeled **NON-CONVERGED** and let the user break the tie.

## Sentinels & resume

Every stub template ships with a sentinel as its literal first line: `<!-- sunoku:stub -->`. An
artifact is **done** when it exists, is non-empty, and the sentinel is absent (removing the
sentinel is the write-agent's explicit "I filled this in" signal — see Dispatch). Append-only
ledgers (JOURNAL.md, EVIDENCE.md) are done once they hold at least 1 entry row; an empty ledger
with the sentinel removed is not done.

Journal entries use a machine-scanned header: `## YYYY-MM-DD — <type>`, where `<type>` is one of
`track`, `reshape`, `decision`.

Resume is two-level, checked in order:

1. **status.json `lifecycle`** — tells the orchestrator which phase the product is broadly in.
2. **Per-artifact sentinel checks** — within that phase, which specific files are actually done.

A resumed run never restarts a phase from scratch and never clobbers an artifact that already
passed its done-check. It picks up at the first not-done artifact.

## StatusFile

`status.json` lives at the `.sunoku/` root and is the single lifecycle source of truth. Only the
orchestrator writes it — agents never touch it. Canonical serialization (one key per line, two-space
indent, exact key order below) is mandatory; hooks match on exact byte patterns like
`"tracking": true` and `"lifecycle": "live"`, so any other formatting breaks them:

```json
{
  "version": 1,
  "sunokuVersion": "<plugin version>",
  "product": "<display name>",
  "origin": "greenfield",
  "lifecycle": "defining",
  "tracking": false,
  "last_reconciled_sha": "",
  "created": "2026-07-02T09:00:00Z",
  "updated": "2026-07-02T09:00:00Z"
}
```

Field semantics:

- `version` — schema version of the record itself (not the product, not the plugin); bumped only
  on a breaking record-shape change where shape-sniffing cannot work (see Record migrations).
- `sunokuVersion` — the plugin version that last wrote the record (not the product's version),
  read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` and re-stamped on every
  status.json write.
- `origin` — `greenfield` | `existing`.
- `lifecycle` — `validating` | `defining` | `planning` | `live` | `shelved`.
- `tracking` — whether TRACK/RESHAPE triage is active for this product.
- `last_reconciled_sha` — the consumer repo commit the journal was last reconciled against.

Lifecycle transitions:

```
validating -> defining -> planning -> live
defining -> live                        (existing/as-built products skip planning)
(any phase) -> shelved                  (on kill)
```

Every write to status.json updates `updated` to the current timestamp and re-stamps
`sunokuVersion` with the current plugin version; `created` never changes after the file's first
write.

## Record migrations

Legacy record shapes upgrade in place, silently, applied by whichever skill touches the record
first. Before reading or writing any `.sunoku/` artifact, consult
`${CLAUDE_PLUGIN_ROOT}/reference/MIGRATIONS.md` and apply every row whose Detect shape matches,
before proceeding with the run's actual work.

- Migrations are mechanical: SILENT lane — no journal entry, no checkpoint; one line in the
  skill's output ("record migrated: <what>") is the only trace.
- Detection is shape-based (what the file actually contains), never version arithmetic.
  `sunokuVersion` exists for ambient skew *detection*, not as a migration trigger;
  `status.json.version` is reserved for a future breaking change where shape-sniffing cannot
  work.
- Hooks only detect version skew and nudge; they never write the record. Only skills migrate.

## Work loop

`sunoku:work` executes an approved plan, one task per loop iteration, on explicit user invocation
only — no hook nudges it, no skill triggers it proactively. It is the sole mutator of TASKS.md
`Status` values (the planner writes only the planning-time `todo`), and the main assistant under
its direction is the only sanctioned writer of consumer application code in a Sunoku flow.

- **States**: `todo → doing → done`, or `todo → doing → blocked`. At most one `doing` at a time
  across the whole file.
- **Eligibility**: the current milestone is the first milestone section containing any non-`done`
  task; the loop never picks from a later milestone. Within it, resume a `doing` task first
  (an interrupted run left it), else take the first `todo` whose every `Depends on` ID is `done`.
- **Done bar**: a task is `done` only when its changes pass the project's own verification — the
  test/build suite where one exists, plus any check the task text itself names. Three attempts per
  iteration, then `blocked`: reason and attempt count to the TASKS.md `Blocked` table, plus one
  flag row in QUESTIONS.md.
- **Never ask mid-iteration**: the loop runs unattended. Inferable decisions take the Assumptions
  default-and-flag path; non-inferable or high-stakes ones block the task instead. Everything
  accrued surfaces in the milestone-boundary report, never as a mid-run question.
- **Git**: task commits land on a `sunoku/m<n>` milestone branch — auto-created from the current
  HEAD at the milestone's first task, never the repo's default branch. One commit per completed
  task, message `T-<n>: <task title>`. Never push unattended: offering a push + PR happens only
  inside the milestone-boundary report with the user present. A branch of the user's own code is
  not an "external export" under the prime directive.
- **Journal**: one `track` entry per completed milestone, listing the tasks that landed and any
  still blocked. Task-level history lives in TASKS.md — per-task journal entries are noise, a
  silence-discipline violation.
- **Boundary**: milestone completion, or a backlog where every remaining task is blocked or
  depends on a blocked one, always ends the loop. The completion report checks the milestone's
  ROADMAP exit criteria one by one and surfaces accrued QUESTIONS flags; a fresh `sunoku:work`
  invocation after review is the approval that opens the next milestone.
