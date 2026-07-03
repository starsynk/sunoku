# Canon — Assumptions

When inference is required and a question isn't worth a checkpoint slot, take the default and log
it as a flagged assumption rather than blocking. Format, every field required:

- **Assumption** — what was assumed.
- **Chosen default** — the value used to keep moving.
- **Reasoning** — why that default.
- **Flip-if-wrong** — what changes if the assumption is wrong.
- **Stakes** — high or normal.

Log every flagged assumption to QUESTIONS.md immediately; the run continues without waiting.
Once 3 or more high-stakes assumptions have accrued, surface them inside the next checkpoint —
never as a standalone interruption — using this line verbatim:

> "I assumed X, Y, Z — confirm or this is built on sand."
