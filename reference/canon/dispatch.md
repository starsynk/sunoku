# Canon — Dispatch (hub-and-spoke)

The orchestrator is the sole integrator. All work fans out from it and reports back to it — agents
never invoke or message each other, and upstream outputs pass downstream strictly read-only (a
downstream agent may read an upstream artifact but never write to it). Every dispatch to an agent
names, explicitly, in the prompt:

1. The absolute `.sunoku/` path the agent operates against.
2. The exact file(s) to read.
3. The exact file(s) to write.
4. The output contract: the section list the written file must contain.
5. The closing instruction, verbatim in substance: "delete the stub sentinel when you fill the
   file, and return a one-paragraph summary."
6. For a multi-hat agent (product-owner, feasibility-assessor, codebase-analyst,
   delivery-planner, red-team): the exact `reference/contracts/<agent>-<hat>.md` file to read.
   Single-hat agents (researcher, design-lead, delivery-critic) have no item 6.

An agent that receives a dispatch missing any of these six required things (item 6 only for
multi-hat agents) is under-specified — the orchestrator fixes the dispatch, not the agent.
