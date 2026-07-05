# Create mode (greenfield)

1. Gather inputs: the scoping answers (product, one-liner) and `.sunoku/research/*.md` if
   validation ran.
2. Dispatch `sunoku:product-owner` with: hat `create`; files to read (the research files, by
   absolute path); the file to write (`.sunoku/PRD.md`, absolute); and the contract
   `${CLAUDE_PLUGIN_ROOT}/skills/prd/references/product-owner-contract.md`. It fills every
   template section and deletes the stub sentinel.
3. Review the draft yourself for template-section completeness and feature traceability before
   showing it. Garbage output → one corrective re-dispatch naming the failure.
4. Checkpoint: present the draft summary (problem, top features, out-of-scope) and ask for
   approval, "approve (recommended)" first. Patch on feedback, re-present once.
5. On approval: first Change Log row is `| <today> | Initial PRD | <one-line why now> | create |`.
   Update `one_liner` via status-write.
