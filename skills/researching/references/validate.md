# Validation mode

Input: the product one-liner and scoping answers (from init's onboarding).

1. **Dispatch a researcher subagent** per the template in
   `${CLAUDE_PLUGIN_ROOT}/skills/researching/references/researcher-prompt.md`, with: the idea
   one-liner as the question; output file `.sunoku/research/validation-<YYYY-MM-DD>.md`
   (absolute path). It covers demand signals, ICP, competitors + pricing, trends — every claim
   sourced.

2. **Dispatch a red-team subagent** per the template in
   `${CLAUDE_PLUGIN_ROOT}/skills/researching/references/red-team-prompt.md`, with: the
   researcher's output file to read; it appends its critique to that same file under
   `## Red team`. It attacks the strongest claims, flags every unsourced one, and steelmans
   NOT building.

3. **Synthesize** a recommendation yourself from both parts: GO / GO-IF / NO-GO with the three
   strongest evidence points and the strongest objection. GO-IF conditions become high-stakes
   decision rows (`decisions.mjs --add`, `"by":"research"`).

4. **Return** the recommendation + file path to the invoker (init presents the checkpoint; a
   direct user invocation presents it directly). Garbage subagent output gets exactly one
   corrective re-dispatch naming the specific failure; then surface the failure plainly.
