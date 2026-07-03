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

exit $FAIL
