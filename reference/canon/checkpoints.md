# Canon — Checkpoints

The complete set of checkpoints, and no others:

1. **Go/no-go** — before committing real work to a direction.
2. **PRD approve / accuracy gate** — before a PRD is treated as current-state truth.
3. **Roadmap approve** — before a roadmap is treated as the execution plan.
4. **One per RESHAPE** — exactly one checkpoint per RESHAPE event, no more.

No other pause points exist. An orchestrator never stops unplanned mid-run to ask a question —
questions get batched. Each checkpoint scopes to one batched question set, capped at 5 questions,
infer-first (only ask what cannot be reasonably inferred), folded into the first phase's entry
conversation rather than sprinkled across the run.

When a batched question has a defensible default, lead with it: the recommended answer is always
the **first** option, its label suffixed with "(Recommended)". In a multiple-choice questionnaire
(AskUserQuestion), that recommended option is option one — never buried mid-list.
