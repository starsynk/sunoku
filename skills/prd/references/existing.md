# Existing mode (reconstruct from code)

1. Dispatch `sunoku:codebase-analyst` with: the repo root to sweep; the file to write
   (`.sunoku/research/as-built.md`, absolute); and the contract
   `${CLAUDE_PLUGIN_ROOT}/skills/prd/references/codebase-analyst-contract.md`. Every claim is
   cited `file:line`.
2. Dispatch `sunoku:product-owner` with: hat `create`; files to read (the as-built file); file
   to write (`.sunoku/PRD.md`); the same product-owner contract. Features it cannot ground in
   the as-built become assumption-flagged rows, not silent inventions.
3. Checkpoint (accuracy gate): present the draft with its as-built citations and ask whether it
   matches reality; the user's corrections are applied before approval.
4. On approval: Change Log row `| <today> | Initial PRD (reconstructed) | <why> | existing |`;
   update `one_liner`.

This mode is also the refresh path: when the user judges the PRD has drifted from the code
(out-of-band commits, work done without tracking), re-run steps 1–4 — the diff against the old
PRD becomes reshape-style Change Log rows instead of the initial row. Only the user makes that
call; `sunoku:status` narrates staleness but never requests a refresh.
