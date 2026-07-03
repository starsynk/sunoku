# init — DEFINE phase

Preconditions: canon core read; canon sections for "init — any phase" loaded per the Disclosure map.

   Dispatch `sunoku:product-owner`, `sunoku:design-lead`, and `sunoku:feasibility-assessor`
   (DEFINE hat) — product-owner first or in parallel where their reads allow, each writing its PRD
   section file under `research/.fragments/` (e.g. `.fragments/define-product.md`,
   `.fragments/define-design.md`, `.fragments/define-architecture.md`) so parallel writers never
   share a file. design-lead's read list includes the product-owner's drafted Problem/Personas/
   Features sections. Then dispatch `sunoku:red-team` (DEFINE hat): read = the drafted PRD section
   fragments + `research/EVIDENCE.md`; write = `research/.fragments/define-critique.md`. Run the
   conflict loop (≤3). Then YOU assemble `PRD.md` from the section fragments into the template's
   section order (Problem, Personas, Features, Architecture, UX, Out of scope, Success metrics,
   Commercial, Change Log), leave the Change Log table empty, delete the PRD sentinel, and delete
   the section fragments after assembly — including `research/.fragments/define-critique.md`, not
   just the drafted PRD section fragments. **Checkpoint: approve the PRD** — surface ≥3 high-stakes
   assumptions inside it per canon if that many have accrued.
