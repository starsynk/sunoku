# Onboarding — first run scoping

Goal: one short exchange, then scaffold. Batch the questions; do not drip them one per message
unless answers conflict.

1. **Ask** (one message, recommended defaults where guessable from the repo):
   - Product name (default: repo directory name).
   - One-liner: what it does, for whom (used as `one_liner` until the PRD refines it).
   - Origin: brand-new idea, or existing codebase to document?
   - New idea only: validate the bet first (market research, go/no-go), or already committed?

2. **Scaffold** once answered:

   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/skills/init/scripts/scaffold.mjs" --product "<name>" --lifecycle <x>
   ```

   `--lifecycle validating` when the user chose validation; `defining` otherwise (committed or
   existing codebase). Then set the one-liner:

   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/scripts/status-write.mjs" --set one_liner="<one-liner>"
   ```

3. **Route** back to SKILL.md: existing → prd existing mode; validate → research validation
   mode; committed → prd create mode.
