# init — PLAN phase

Preconditions: canon core read; canon sections for "init — any phase" loaded per the Disclosure map.

e. **PLAN (optional).** Offer it once: "want a build plan here? Planning elsewhere is fine —
   skipping keeps full tracking." Accepted → scaffold `ROADMAP.md` + `TASKS.md` stubs, set
   `lifecycle` to `planning`, dispatch `sunoku:delivery-planner` (full-plan hat, reads `PRD.md`,
   writes `ROADMAP.md` + `TASKS.md`) → then `sunoku:delivery-critic` (reads `ROADMAP.md` +
   `TASKS.md` + `PRD.md`, writes `research/.fragments/plan-critique.md`) → fix loop ≤3
   (re-dispatch delivery-planner for any blocking finding, never edit the plan yourself), then
   delete the critique fragment → **checkpoint: approve the roadmap.** Declined → skip planning
   entirely; go to arming.
