# Open Questions — Sunoku

> Flagged assumptions and open questions. Answering one triggers an appropriately scoped update (see canon).
> Format per entry:
> ## Q-<n> — <title>  (stakes: high|normal, status: open|answered)
> **Assumption taken:** … **Reasoning:** … **Flip if wrong:** …

## Q-1 — Monetization stance is non-commercial  (stakes: normal, status: open)
**Assumption taken:** Sunoku is a free, MIT-licensed open-source plugin with no commercial model, so
the PRD carries no Commercial section.
**Reasoning:** `LICENSE` is MIT and `.claude-plugin/plugin.json` declares `"license": "MIT"`; no
pricing, billing, or paid-tier artifacts exist anywhere in the repo.
**Flip if wrong:** If a paid/hosted offering is planned, add a Commercial section and revisit segment
framing around buyers vs. users.

## Q-2 — Target segment inferred from positioning, not stated  (stakes: normal, status: open)
**Assumption taken:** Segment is individual developers and small teams already using Claude Code.
**Reasoning:** Distribution is a Claude Code plugin; README voice addresses a solo/small-team "you"
who owns a repo. No enterprise/admin surfaces exist.
**Flip if wrong:** If the target is larger orgs, expect needs around multi-repo, roles, and
governance that the current single-repo `.sunoku/` model does not address.

## Q-3 — Coexistence canon addition triaged TRACK, not RESHAPE  (stakes: normal, status: answered)
**Assumption taken:** The new `## Coexistence` section in `reference/canon.md` is a TRACK-lane
change — an in-scope articulation of Sunoku's existing narrow-orchestrator direction — not a RESHAPE
of the architecture.
**Reasoning:** It changes none of the reshape set in substance — core bet, product scope, structure,
target segment, and pricing are all unchanged; it hardens the Prime directive's narrowness rather
than redirecting the product. Full RESHAPE ceremony (checkpoint + PRD reconcile) for a ~14-line canon
principle is the over-ceremony canon's Triage explicitly warns against.
**Flip if wrong:** If this counts as an architecture change — it adds a foundational principle
sibling to the Prime directive, which the PRD Architecture section documents — it flips to RESHAPE,
requiring a PRD Change Log row plus refreshed canon citations. Regardless of lane, this change leaves
the PRD Architecture "Shared rulebook" bullet (PRD.md:75) stale in two ways: the canon line count
("207 lines"; canon is now 245) and the owned-section enumeration (omits Coexistence). That
enumeration is already incomplete from the prior reconcile — it also omits Work loop and Record
migrations — so the next `sunoku:status` reconcile should refresh the whole bullet, not just this item.
**Answered (2026-07-03):** Mooted by the feature-18-drop RESHAPE (journal `2026-07-03 — reshape`,
commit f2589f2): the Architecture "Shared rulebook" bullet was refreshed wholesale — line count
(238) and the full section enumeration including Coexistence and the new Execution contract. The
lane call stands as made: the Coexistence principle itself was TRACK-grade; the RESHAPE that
reconciled the PRD was the `sunoku:work` drop, not the principle.
