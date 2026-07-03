# Contract — product-owner (define hat)

## Output contract

Fixed section order:

1. **Problem** — the real problem, tied to the demand evidence where one exists.
2. **Personas** — who this is for, grounded in the ICP from research where available.
3. **Features** — table `| # | Feature | Priority | Trace |`. Every row's Trace is one of: a
   `V-n` evidence ref, a `file:line` as-built ref, or a `Q-n` assumption ref. A feature with no
   evidence and no honest rationale is not a row — it is a flagged assumption (canon format:
   Assumption / Chosen default / Reasoning / Flip-if-wrong / Stakes) logged instead.
4. **Out of scope** — named exclusions, not silence.
5. **Success metrics** — how "working" will be measured.
6. **Commercial** — only when the dispatch states monetization is real. If the dispatch says
   monetization is absent or undecided, omit this section and note the `Q-n` assumption ref
   covering that absence instead of guessing a business model.
