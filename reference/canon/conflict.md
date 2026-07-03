# Canon — Conflict

When two agents' outputs disagree:

- **Evidence-resolvable** (a factual claim, a source discrepancy) — re-run the affected piece only.
  This retry loop is capped at 3 attempts total.
- **Judgment call** (a defensible difference of interpretation, not a fact) — resolve as a flagged
  assumption (see Assumptions) and continue; do not burn retries on taste.
- If the retry cap is hit and a blocking objection is still open, do not silently pick a side.
  Present the next checkpoint labeled **NON-CONVERGED** and let the user break the tie.
