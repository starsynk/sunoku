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
