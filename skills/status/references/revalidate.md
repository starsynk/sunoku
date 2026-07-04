# status — Re-validate procedure (stale validation)

Preconditions: canon core read; canon sections dispatch, fragments, garbage-output, conflict,
checkpoints, statusfile loaded per the Disclosure map ("status — re-validate").

- Trigger: the user accepts the stale-validation offer (report `validation_stale` true) or asks
  directly. A record with no validation reports has nothing to re-validate — offer nothing;
  its commitment never rested on a validation verdict.
- `lifecycle` stays `live`, `tracking` stays on. This re-answers "is the bet still sound with
  today's market," never "start the product over."
- Run the VALIDATE dispatch shape from `${CLAUDE_PLUGIN_ROOT}/skills/init/references/validate.md`
  with one delta: every read list includes the current `PRD.md` alongside `BRIEF.md` — agents
  assess the product as it is now, not the original sketch. Same parallel dispatch, same
  fragments barrier (count == 2), same red-team pass, same conflict loop (≤3).
- Compose a NEW `validation/<YYYY-MM-DD>-validation.md` from the template, beside the old
  report(s). Older reports are immutable — never edit or delete them.
- Checkpoint (go/no-go class): present the verdict.
  - GO → append a `decision` journal entry (what was re-checked, verdict, key evidence refs).
  - GO-IF → the decision entry, plus each condition becomes a high-stakes Q-n entry.
  - NO-GO → the user chooses: shelve (decision entry with the kill rationale, then
    `status-write.mjs --set lifecycle=shelved`) or continue anyway (decision entry recording
    the override and its reasoning — the record must show the verdict was seen, not ignored).
- Close with `node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --refresh`.
