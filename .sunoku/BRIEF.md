# Brief — Sunoku

## Segment
Developers and small product teams working inside Claude Code who need a single, trustworthy record
of what a software product is and why — spanning pre-commitment validation, a living PRD, an
optional build plan, and a permanent change journal. Targets people burned by planning docs that
rot: they want an answer to "what is this product now, what changed, and why" months later, backed
by evidence rather than memory.

## Wedge
One command (`sunoku:init`) that produces a *living* record instead of a static deliverable. The PRD
is a reconciled current-state snapshot over an append-only journal, with a triage (SILENT / TRACK /
RESHAPE) that keeps the record quiet on noise and honest on real change. Delivered as a Claude Code
plugin that reads the repo and arms tracking automatically — memory-first for existing codebases.

## Monetization stance
Internal / open-source. Licensed MIT, distributed as a free Claude Code plugin via its own
marketplace. No commercial section in the PRD. (See flagged assumption Q-1.)

## Constraints
- Claude Code plugin architecture: skills (`skills/`), subagents (`agents/`), ambient hooks
  (`hooks/`), shared canon + templates (`reference/`).
- Hard boundary: never writes application code, never touches anything outside `.sunoku/` at the
  consumer repo root.
- Ambient hooks are Bash scripts — require Git Bash on PATH on Windows or they silently no-op.
- Orchestration is strictly hub-and-spoke: the skill orchestrator is the sole integrator and sole
  writer of `status.json`; agents never message each other.

## Commitment
Existing codebase — validation not applicable (`origin: existing`). Onboarded as-built via the
RECONSTRUCT → accuracy-gate flow.
