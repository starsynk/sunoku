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
assert_max_bytes reference/canon.md 4096

# Task 4: skills point at core + disclosure map, not full-file section reads
assert_contains skills/log/SKILL.md "Disclosure map"
assert_contains skills/status/SKILL.md "Disclosure map"
assert_contains skills/init/SKILL.md "Disclosure map"
assert_absent skills/log/SKILL.md "Obey its Triage, Checkpoints, Dispatch, and StatusFile sections"

# Task 5: lane files exist; hot bodies shrank
assert_file skills/log/references/reshape.md
assert_file skills/status/references/reconcile.md
assert_max_bytes skills/log/SKILL.md 6144
assert_max_bytes skills/status/SKILL.md 6144
assert_contains skills/log/SKILL.md "references/reshape.md"
assert_contains skills/status/SKILL.md "references/reconcile.md"

# Task 6: no whole-file reads on the report path
assert_contains skills/status/SKILL.md "grep -c"
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
assert_contains .claude-plugin/plugin.json '"version": "1.3.0"'
assert_contains CHANGELOG.md "## 1.3.0"

exit $FAIL
