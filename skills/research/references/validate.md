# Validation mode

Input: the product one-liner and scoping answers (from init's onboarding).

1. **Dispatch `sunoku:researcher`** with: the idea one-liner; instruction to read the contract
   `${CLAUDE_PLUGIN_ROOT}/skills/research/references/researcher-contract.md`; output file
   `.sunoku/research/validation-<YYYY-MM-DD>.md` (absolute path). It covers demand signals, ICP,
   competitors + pricing, trends — every claim sourced.

2. **Dispatch `sunoku:red-team`** with: instruction to read
   `${CLAUDE_PLUGIN_ROOT}/skills/research/references/red-team-contract.md`; the researcher's
   output file to read; append its critique to that same file under `## Red team`. It attacks the
   strongest claims, flags every unsourced one, and steelmans NOT building.

3. **Synthesize** a recommendation yourself from both parts: GO / GO-IF / NO-GO with the three
   strongest evidence points and the strongest objection. GO-IF conditions become high-stakes
   decision rows (`decisions.mjs --add`, `"by":"research"`).

4. **Return** the recommendation + file path to the invoker (init presents the checkpoint; a
   direct user invocation presents it directly). Garbage agent output gets exactly one corrective
   re-dispatch naming the specific failure; then surface the failure plainly.
