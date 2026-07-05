#!/usr/bin/env bash
# Behavior tests for the v2 record scripts. Temp-dir fixtures, PASS/FAIL counters, exit 1 on FAIL.
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
S="$HERE/scripts"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1${2:+ ($2)}"; FAIL=$((FAIL+1)); }
assert_grepf()  { grep -qF -- "$2" "$1" 2>/dev/null && pass "$3" || fail "$3" "literal '$2' not in $1"; }
assert_nogrepf(){ grep -qF -- "$2" "$1" 2>/dev/null && fail "$3" "literal '$2' still in $1" || pass "$3"; }
assert_exit0()  { [ "$1" -eq 0 ] && pass "$2" || fail "$2" "exit=$1"; }
assert_exitn()  { [ "$1" -ne 0 ] && pass "$2" || fail "$2" "expected nonzero exit"; }
assert_eq()     { [ "$1" = "$2" ] && pass "$3" || fail "$3" "got '$1' want '$2'"; }

mkrecord() { # $1 = dir; minimal live v2 record
  mkdir -p "$1/.sunoku/research"
  cat > "$1/.sunoku/status.json" <<'EOF'
{
  "product": "Testo",
  "one_liner": "Testo does things.",
  "lifecycle": "live",
  "tracking": true,
  "created": "2026-07-01T00:00:00Z",
  "updated": "2026-07-01T00:00:00Z"
}
EOF
  cat > "$1/.sunoku/PRD.md" <<'EOF'
# PRD — Testo

## Problem

Planning artifacts rot and teams forget why.

## Features

| id | feature | priority | trace |
|---|---|---|---|
| F-1 | Fast capture | P0 | D-001 |

## Change Log

| date | change | why | trigger |
|---|---|---|---|
| 2026-06-01 | Dropped teams tier | no demand evidence | reshape |
| 2026-07-01 | Added fast capture | top user ask | reshape |
EOF
}

# --- status-write ---
D="$(mktemp -d)"; mkrecord "$D"
OUT="$(cd "$D" && CLAUDE_PROJECT_DIR="$D" node "$S/status-write.mjs" --set lifecycle=defining --set one_liner="New line.")"
assert_exit0 $? "status-write: set exits 0"
assert_grepf "$D/.sunoku/status.json" '"lifecycle": "defining"' "status-write: lifecycle written"
assert_grepf "$D/.sunoku/status.json" '"one_liner": "New line."' "status-write: one_liner written"
assert_grepf "$D/.sunoku/status.json" '"created": "2026-07-01T00:00:00Z"' "status-write: created preserved"
assert_nogrepf "$D/.sunoku/status.json" '"updated": "2026-07-01T00:00:00Z"' "status-write: updated restamped"

CLAUDE_PROJECT_DIR="$D" node "$S/status-write.mjs" --set lifecycle=shelved >/dev/null 2>&1
assert_exitn $? "status-write: invalid lifecycle rejected"
CLAUDE_PROJECT_DIR="$D" node "$S/status-write.mjs" --set origin=existing >/dev/null 2>&1
assert_exitn $? "status-write: unknown key rejected"
CLAUDE_PROJECT_DIR="$(mktemp -d)" node "$S/status-write.mjs" --set tracking=false >/dev/null 2>&1
assert_exitn $? "status-write: no record dies"

# key order canonical: product first line after brace
head -2 "$D/.sunoku/status.json" | tail -1 | grep -qF '"product"' && pass "status-write: key order" || fail "status-write: key order"

echo; echo "test-scripts: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
