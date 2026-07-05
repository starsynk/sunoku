#!/usr/bin/env bash
# Structure invariants for the Sunoku plugin. Pure grep/stat checks, no side effects.
set -u
cd "$(dirname "$0")/.."
FAIL=0
ok()   { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; FAIL=1; }
assert_file()      { [ -f "$1" ] && ok "exists: $1" || fail "missing: $1"; }
assert_contains()  { grep -qF -- "$2" "$1" 2>/dev/null && ok "$1 contains: $2" || fail "$1 missing: $2"; }
assert_absent()    { grep -qF -- "$2" "$1" 2>/dev/null && fail "$1 still contains: $2" || ok "$1 clean of: $2"; }
assert_max_bytes() { [ "$(wc -c < "$1" | tr -d ' ')" -le "$2" ] && ok "$1 <= $2 bytes" || fail "$1 exceeds $2 bytes"; }

# --- baseline invariants ---
assert_file reference/canon.md
assert_contains reference/canon.md "## Prime directive"
assert_contains reference/canon.md "## Coexistence"
assert_contains reference/canon.md "## Triage"
assert_file skills/log/SKILL.md
assert_file skills/status/SKILL.md
assert_file skills/init/SKILL.md

# --- task assertions appended below this line ---

# Task 2: guard precedes canon read
awk '/^## Flow/{f=1} f && /canon.md/{print NR; exit}' skills/log/SKILL.md > /tmp/sun_canon_line
awk '/^## Flow/{f=1} f && /status.json/{print NR; exit}' skills/log/SKILL.md > /tmp/sun_guard_line
[ "$(cat /tmp/sun_guard_line)" -lt "$(cat /tmp/sun_canon_line)" ] && ok "log: guard before canon" || fail "log: canon read precedes guard"
awk '/^## Flow/{f=1} f && /canon.md/{print NR; exit}' skills/status/SKILL.md > /tmp/sun_canon_line
awk '/^## Flow/{f=1} f && /status.json/{print NR; exit}' skills/status/SKILL.md > /tmp/sun_guard_line
[ "$(cat /tmp/sun_guard_line)" -lt "$(cat /tmp/sun_canon_line)" ] && ok "status: guard before canon" || fail "status: canon read precedes guard"

# Task 3: canon core + section files
for f in checkpoints assumptions dispatch fragments garbage-output conflict sentinels-resume statusfile record-migrations execution-contract; do
  assert_file "reference/canon/$f.md"
done
assert_contains reference/canon.md "## Disclosure map"
assert_absent reference/canon.md "## Dispatch (hub-and-spoke)"
assert_absent reference/canon.md "## StatusFile"
assert_max_bytes reference/canon.md 4608 # bumped 1.7.0: re-validate disclosure row

# Task 4: skills point at core + disclosure map, not full-file section reads
assert_contains skills/log/SKILL.md "Disclosure map"
assert_contains skills/status/SKILL.md "Disclosure map"
assert_contains skills/init/SKILL.md "Disclosure map"
assert_absent skills/log/SKILL.md "Obey its Triage, Checkpoints, Dispatch, and StatusFile sections"

# Task 5: lane files exist; hot bodies shrank
assert_file skills/log/references/reshape.md
assert_file skills/status/references/reconcile.md
assert_max_bytes skills/log/SKILL.md 6656 # bumped 2026-07-05: SILENT task-flip lane + journal grain bound
assert_max_bytes skills/status/SKILL.md 8192 # bumped 1.7.0: doctor/digest/re-validate surfaces
assert_contains skills/log/SKILL.md "references/reshape.md"
assert_contains skills/status/SKILL.md "references/reconcile.md"

# Task 6: no whole-file reads on the report path (report script + drill-in only)
assert_contains skills/status/SKILL.md "report.mjs"
assert_contains skills/status/SKILL.md "tail"

# Task 8: descriptions trimmed but trigger phrases intact
assert_contains skills/init/SKILL.md 'is this idea worth building?'
assert_contains skills/log/SKILL.md 'record that'
assert_contains skills/status/SKILL.md 'what changed since May?'
for f in skills/init/SKILL.md skills/log/SKILL.md skills/status/SKILL.md agents/*.md; do
  [ "$(awk -F'description: ' '/^description:/{print length($2); exit}' "$f")" -le 320 ] \
    && ok "desc <=320 chars: $f" || fail "desc too long: $f"
done

# Task 9: init is a router
for f in validate define plan existing; do assert_file "skills/init/references/$f.md"; done
assert_file "skills/init/references/onboarding.md"
assert_max_bytes skills/init/SKILL.md 9472
assert_contains skills/init/SKILL.md "references/validate.md"

# Task 10: hat contracts exist; dispatch names six things
for f in product-owner-define product-owner-reshape feasibility-assessor-validate feasibility-assessor-define codebase-analyst-reconstruct codebase-analyst-reconcile delivery-planner-full-plan delivery-planner-reshape red-team-validate red-team-define; do
  assert_file "reference/contracts/$f.md"
done
assert_contains reference/canon/dispatch.md "reference/contracts/"
if grep -rqF "five required things" skills/; then fail "stale five-things phrasing"; else ok "dispatch phrasing updated"; fi

# Task 11: statusfile defines summary fields; skills use them
assert_contains reference/canon/statusfile.md '"one_liner"'
assert_contains reference/canon/statusfile.md '"last_entry"'
assert_contains reference/MIGRATIONS.md "1.3.0"
assert_contains skills/status/SKILL.md "one_liner"

# Task 12: rollover rule present
assert_contains skills/log/SKILL.md ".sunoku/journal/"

# Task 13: version aligned
assert_contains .claude-plugin/plugin.json '"version": "1.8.1"'
assert_contains CHANGELOG.md "## 1.8.1"

# Scripts layer: deterministic record writes live in scripts/, docs point at them
for f in lib status-write report journal-append questions-flush tasks-set scaffold sentinels migrate; do
  assert_file "scripts/$f.mjs"
done
assert_contains skills/log/SKILL.md "journal-append.mjs"
assert_contains skills/log/SKILL.md "status-write.mjs"
assert_contains skills/log/references/reshape.md "status-write.mjs"
assert_contains skills/status/SKILL.md "status-write.mjs"
assert_contains skills/status/SKILL.md "migrate.mjs"
assert_contains skills/status/references/reconcile.md "tasks-set.mjs"
assert_contains skills/status/references/reconcile.md "sha-head"
assert_contains skills/init/SKILL.md "scaffold.mjs"
assert_contains skills/init/SKILL.md "sentinels.mjs"
assert_contains reference/canon/statusfile.md "status-write.mjs"
assert_contains reference/canon/record-migrations.md "migrate.mjs"
assert_contains reference/canon/assumptions.md "questions-flush.mjs"
assert_contains reference/canon/sentinels-resume.md "sentinels.mjs"
assert_contains reference/MIGRATIONS.md "migrate.mjs"

# QUESTIONS answer-and-flush lifecycle
assert_contains reference/canon/assumptions.md "## Answering"
assert_contains reference/canon.md "answering a QUESTIONS.md entry"
assert_contains skills/log/SKILL.md "Question answer"
assert_contains skills/status/SKILL.md "answers route through"
assert_contains reference/templates/QUESTIONS.md "status: open)"
assert_absent reference/templates/QUESTIONS.md "status: open|answered"

# 1.6.0: agent model values are documented ones (best is not)
for f in agents/*.md; do
  grep -qE '^model: (sonnet|opus|haiku|fable|inherit)$' "$f" && ok "valid model: $f" || fail "invalid model value: $f"
done

# 1.6.0: Node hooks (no bash runtime), guard wired, cross-platform README
assert_file hooks/scripts/session-start.mjs
assert_file hooks/scripts/stop-nudge.mjs
assert_file hooks/scripts/guard-record-writes.mjs
assert_contains hooks/hooks.json "session-start.mjs"
assert_contains hooks/hooks.json "PreToolUse"
assert_absent hooks/hooks.json "session-start.sh"
assert_absent README.md "Git Bash"

# 1.6.0: merge=union ledger template + migration row
assert_file reference/templates/sunoku.gitattributes
assert_contains reference/templates/sunoku.gitattributes "merge=union"
assert_contains reference/MIGRATIONS.md "1.6.0"

# 1.6.0: CI wired
assert_file .github/workflows/test.yml
assert_contains .github/workflows/test.yml "test-scripts.sh"

# 1.7.0: doctor + digest scripts, wired into the status surface
assert_file scripts/doctor.mjs
assert_file scripts/digest.mjs
assert_contains skills/status/SKILL.md "doctor.mjs"
assert_contains skills/status/SKILL.md "digest.mjs"

# 1.7.0: validation staleness + re-validate lane
assert_contains skills/status/SKILL.md "validation_stale"
assert_file skills/status/references/revalidate.md
assert_contains skills/status/SKILL.md "references/revalidate.md"
assert_contains reference/canon.md "re-validate"

# 1.7.0: journal tags + record queries
assert_contains reference/templates/JOURNAL.md "Tags:"
assert_contains skills/status/SKILL.md "--since"

# 1.8.0: aging, attribution, journal guard, escalation, release notes
assert_contains reference/canon/assumptions.md "Opened"
assert_contains reference/templates/QUESTIONS.md "Opened:"
assert_contains skills/status/SKILL.md "questions_aging"
assert_contains reference/templates/JOURNAL.md "By:"
assert_contains skills/log/SKILL.md "--by"
assert_contains hooks/scripts/guard-record-writes.mjs "journal-append.mjs"
assert_contains hooks/scripts/session-start.mjs "falling behind"
assert_file scripts/release-notes.mjs
assert_contains README.md "release-notes.mjs"

# 1.8.1: recommended answer leads question prompts
assert_contains reference/canon/assumptions.md "## Asking"
assert_contains reference/canon/assumptions.md "(Recommended)"
assert_contains reference/canon/checkpoints.md "(Recommended)"
assert_contains skills/status/SKILL.md "(Recommended)"

exit $FAIL
