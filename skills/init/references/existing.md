# init — Existing-code path

Preconditions: canon core read; canon sections for "init — any phase" loaded per the Disclosure map.

b. **RECONSTRUCT** (lifecycle `defining`). Dispatch `sunoku:codebase-analyst` (RECONSTRUCT hat):
   read list = the consumer repo source tree + existing docs/README; write = `research/as-built.md`
   + its evidence fragment `research/.fragments/reconstruct-analyst.md`; section list = Stack,
   Architecture, Modules, Data model, Entry points, What demonstrably works, Gaps & TODOs; every
   claim cited `file:line`; sentinel+summary closer. The **journal stays EMPTY** here — no git
   archaeology; pre-Sunoku history is out of scope. At the barrier, merge the one fragment onto
   `research/EVIDENCE.md` per canon Fragments (count == 1), delete the fragment.

c. **ACCURACY GATE.** YOU draft `PRD.md` from `research/as-built.md` — every section grounded in
   the `file:line` evidence, no aspirational claims — plus an explicit **GAP LIST** of must-have
   features not yet built (seeded from the analyst's Gaps & TODOs), written as a `## Gap List`
   section appended to the draft `PRD.md` — there is no separate gap-list file. Delete the PRD
   sentinel. Present it: "here is what I understood your product to be — correct me." Apply the
   user's corrections and re-present until they approve. Misreads die here; what the user
   approves becomes canon. This is the PRD-approve checkpoint for this flow.

d. **MEMORY FIRST.** Immediately on approval, arm — BEFORE the gap question. In one step: set
   `lifecycle` to `live`, `tracking` to `true`, `last_reconciled_sha` to current `git HEAD` (`""`
   if no commits), stamping the four summary fields (`one_liner`, `open_questions`,
   `high_stakes`, `last_entry` — canon statusfile.md) for the first time, canonical `status.json`;
   and open the journal with the armed entry
   (`## YYYY-MM-DD — track`, **What:** "Sunoku record armed", **Why/Refs** as above). The record is
   now tracking even if the next question is declined.

e. **Gap roadmap (exactly ONE optional question).** Ask once: "want a gap roadmap over the
   must-haves that aren't built yet?" Yes → scaffold `ROADMAP.md` + `TASKS.md`, dispatch
   `sunoku:delivery-planner` (gap-plan hat, reads the approved gap list — `PRD.md`'s `## Gap
   List` section — + `research/as-built.md`, writes `ROADMAP.md` + `TASKS.md`) →
   `sunoku:delivery-critic` (writes
   `research/.fragments/plan-critique.md`) → fix loop ≤3, then delete the critique fragment →
   **checkpoint: approve the roadmap**,
   all while `lifecycle` stays `live`. No → done; zero further ceremony. Either way, tell the user
   the three-command surface (`sunoku:log`, `sunoku:status`, and `sunoku:init` itself).
