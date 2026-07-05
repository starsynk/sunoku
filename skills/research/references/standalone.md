# Standalone mode

1. Scope the question in one line back to the user only if genuinely ambiguous; otherwise
   proceed.
2. If `.sunoku/research/` does not exist, create the directory (only it — no scaffold, no
   status.json).
3. Dispatch `sunoku:researcher` with the question, the contract file
   `${CLAUDE_PLUGIN_ROOT}/skills/research/references/researcher-contract.md`, and output
   `.sunoku/research/<topic-slug>.md`. For contested or high-stakes topics, also run the
   red-team pass (same shape as validation mode step 2).
4. Reply with a tight summary of the findings and the file path. The file is the deliverable;
   the reply is not a second copy of it.
