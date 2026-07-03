# init — First-run onboarding (origin detection + BRIEF)

Preconditions: canon core read; canon sections for "init — any phase" loaded per the Disclosure map. This file is first-run only — a resume (status.json exists) never loads it (one exception: a resume that finds BRIEF.md still stub-sentineled loads the scoping section).

## Origin detection (step 2, absent branch)

- **absent** → fresh init. Detect the product type: run `git ls-files` (fall back to a directory
  listing if the repo is not initialized). Empty or docs-only → greenfield flow (step 4). Source
  present → do NOT assume existing-code yet; source can be a freshly generated scaffold
  (create-next-app, cargo new, rails new, a starter template — any generator, any stack). Apply
  the substance test: **"if this repo were deleted and its generator re-run, would anything of
  substance be lost?"** Judge it from signals, not a framework list:
    - git history shape — one or two generator-style commits ("Initial commit") vs real history
      with domain-specific messages;
    - domain vocabulary — files/identifiers named after a business domain (invoices, workouts,
      listings) vs only framework-generic names (app, page, layout, index, home, example, demo);
    - divergence from generator output — framework-default README, sample assets and demo pages
      still in place, dependencies ≈ the starter's defaults vs added domain libraries;
    - wiring — real user-facing routes/commands/endpoints beyond the starter's default page.
  Nothing of substance would be lost → **greenfield flow** (step 4): the scaffold is the chosen
  starting stack, not the product — record it in BRIEF.md Constraints and pass it to
  feasibility-assessor as an architecture given; confirm inside the scoping batch ("this repo
  holds a fresh <stack> scaffold with no product code — treating this as a new product to
  define on that stack; correct?"). Any real domain work present, however thin → existing-code
  flow (step 5); a thin product just yields a short as-built PRD and a longer gap list, which
  the accuracy gate handles. Signals genuinely conflicting → do NOT ask separately; fold the
  type question into the scoping batch of whichever flow you lean toward, and let the answer
  confirm or switch. Then scaffold (step 3) and run the chosen flow.

## Greenfield scoping (step 4a)

a. **Scoping.** Read anything already present (README, notes, scratch docs). Then ask ONE batched
   set of at most 5 genuinely-unanswerable questions — infer-first, only what you cannot
   reasonably derive: segment, wedge, monetization stance, hard constraints (team/stack/budget/
   deadline), and the commitment question ("are you already committed to building this?"). Do not
   sprinkle questions across the run; this is the only ask before the first checkpoint. Write
   `BRIEF.md` from the template's sections (Segment, Wedge, Monetization stance, Constraints,
   Commitment) and delete its sentinel. Log any inference you had to make as a flagged assumption
   in `QUESTIONS.md` (canon Assumptions format) rather than blocking on it.

## Existing-code scoping (step 5a)

a. **Scoping.** Infer-first from README, docs, and manifests (package.json, pyproject, go.mod,
   Cargo.toml, etc.). Ask at most 5 questions, only the genuinely-unanswerable ones (e.g. product
   display name, intended segment if the code doesn't reveal it, monetization stance). Write
   `BRIEF.md` (delete sentinel); log inferences as flagged assumptions in `QUESTIONS.md`. Ensure
   `status.json` has `origin: existing` and `lifecycle: defining`.

Done here — return to the router: scaffold (step 3), then run the chosen flow.
