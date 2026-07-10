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

D2="$(mktemp -d)"; mkrecord "$D2"
CLAUDE_PROJECT_DIR="$D2" node "$S/status-write.mjs" --touch >/dev/null
assert_exit0 $? "status-write: touch exits 0"
assert_nogrepf "$D2/.sunoku/status.json" '"updated": "2026-07-01T00:00:00Z"' "status-write: touch restamps updated"
assert_grepf "$D2/.sunoku/status.json" '"one_liner": "Testo does things."' "status-write: touch preserves fields"
assert_grepf "$D2/.sunoku/status.json" '"created": "2026-07-01T00:00:00Z"' "status-write: touch preserves created"

# key order canonical: product first line after brace
head -2 "$D/.sunoku/status.json" | tail -1 | grep -qF '"product"' && pass "status-write: key order" || fail "status-write: key order"

# --- tasks.mjs ---
D="$(mktemp -d)"; mkrecord "$D"; export CLAUDE_PROJECT_DIR="$D"
node "$S/tasks.mjs" --add '{"type":"milestone","title":"Walking skeleton"}' >/dev/null
assert_exit0 $? "tasks: add milestone"
assert_grepf "$D/.sunoku/tasks.jsonl" '"id":"M1"' "tasks: milestone id M1"
node "$S/tasks.mjs" --add '{"type":"epic","milestone":"M1","title":"Auth","prd":["F-1"]}' >/dev/null
assert_grepf "$D/.sunoku/tasks.jsonl" '"id":"E-01"' "tasks: epic id E-01"
node "$S/tasks.mjs" --add '{"type":"task","epic":"E-01","title":"API contract","description":"Define the auth API contract: endpoints, request/response shapes, error codes. Done when the OpenAPI stub is agreed.","discipline":"backend","size":"S"}' >/dev/null
node "$S/tasks.mjs" --add '{"type":"task","epic":"E-01","title":"Frontend","description":"Build the login form against the mocked contract. Done when submit round-trips against the mock.","discipline":"frontend","size":"M","deps":["T-001"]}' >/dev/null
assert_grepf "$D/.sunoku/tasks.jsonl" '"id":"T-002"' "tasks: task ids sequence"
assert_grepf "$D/.sunoku/tasks.jsonl" '"status":"todo"' "tasks: default status todo"

OUT="$(node "$S/tasks.mjs" --list ready)"
echo "$OUT" | grep -qF '"T-001"' && pass "tasks: T-001 ready" || fail "tasks: T-001 ready" "$OUT"
echo "$OUT" | grep -qF '"T-002"' && fail "tasks: dep-blocked not ready" || pass "tasks: dep-blocked not ready"

node "$S/tasks.mjs" --set T-001 status=done >/dev/null
assert_exit0 $? "tasks: set status"
OUT="$(node "$S/tasks.mjs" --list ready)"
echo "$OUT" | grep -qF '"T-002"' && pass "tasks: dep done unlocks" || fail "tasks: dep done unlocks" "$OUT"

OUT="$(node "$S/tasks.mjs" --list milestone=M1)"
echo "$OUT" | grep -qF '"T-002"' && pass "tasks: milestone join filter" || fail "tasks: milestone join filter" "$OUT"

node "$S/tasks.mjs" --set T-001 status=bogus >/dev/null 2>&1
assert_exitn $? "tasks: invalid status rejected"

node "$S/tasks.mjs" --add '{"type":"task","epic":"E-01","title":"No desc","discipline":"backend","size":"S"}' >/dev/null 2>&1
assert_exitn $? "tasks: task without description rejected"
node "$S/tasks.mjs" --add '{"type":"task","epic":"E-01","title":"Empty desc","description":"","discipline":"backend","size":"S"}' >/dev/null 2>&1
assert_exitn $? "tasks: task with empty description rejected"
node "$S/tasks.mjs" --add '{"type":"milestone","title":"No-desc milestone"}' >/dev/null 2>&1
assert_exit0 $? "tasks: milestone without description still fine"
node "$S/tasks.mjs" --set T-001 description="Updated: also cover refresh tokens." >/dev/null
assert_exit0 $? "tasks: set description"
assert_grepf "$D/.sunoku/tasks.jsonl" 'also cover refresh tokens' "tasks: description updated"

node "$S/tasks.mjs" --add '{"type":"task","title":"x","discipline":"ops"}' >/dev/null 2>&1
assert_exitn $? "tasks: invalid discipline rejected"
node "$S/tasks.mjs" --add '{"type":"phase","title":"x"}' >/dev/null 2>&1
assert_exitn $? "tasks: invalid type rejected"
while IFS= read -r line; do echo "$line" | node -e 'JSON.parse(require("fs").readFileSync(0,"utf8"))' 2>/dev/null || { fail "tasks: jsonl valid"; break; }; done < "$D/.sunoku/tasks.jsonl" && pass "tasks: jsonl valid"
unset CLAUDE_PROJECT_DIR

# --- prune: tasks ---
D="$(mktemp -d)"; mkrecord "$D"; export CLAUDE_PROJECT_DIR="$D"
node "$S/tasks.mjs" --add '{"type":"milestone","title":"Skeleton"}' >/dev/null            # M1
node "$S/tasks.mjs" --add '{"type":"epic","milestone":"M1","title":"Auth"}' >/dev/null    # E-01
node "$S/tasks.mjs" --add '{"type":"task","epic":"E-01","title":"Contract","description":"Define the contract. Done when agreed.","discipline":"backend","size":"S"}' >/dev/null   # T-001
node "$S/tasks.mjs" --add '{"type":"task","epic":"E-01","title":"Form","description":"Build the form. Done when it round-trips.","discipline":"frontend","size":"S"}' >/dev/null    # T-002
node "$S/tasks.mjs" --set T-001 status=done >/dev/null

node "$S/tasks.mjs" --prune-milestone M9 >/dev/null 2>&1
assert_exitn $? "prune: unknown milestone dies"
node "$S/tasks.mjs" --prune-milestone M1 >/dev/null 2>&1
assert_exitn $? "prune: partial milestone refused"
assert_grepf "$D/.sunoku/tasks.jsonl" '"id":"T-001"' "prune: refusal leaves rows intact"

node "$S/tasks.mjs" --set T-002 status=done >/dev/null
node "$S/tasks.mjs" --add '{"type":"milestone","title":"Growth"}' >/dev/null              # M2
node "$S/tasks.mjs" --add '{"type":"epic","milestone":"M2","title":"Billing"}' >/dev/null # E-02
node "$S/tasks.mjs" --add '{"type":"task","epic":"E-02","title":"Plans","description":"Model plans on the contract. Done when priced.","discipline":"backend","size":"S","deps":["T-001"]}' >/dev/null  # T-003

node "$S/tasks.mjs" --prune-milestone M1 >/dev/null 2>&1
assert_exitn $? "prune: live cross-milestone dep refused"

node "$S/tasks.mjs" --set T-003 status=done >/dev/null
OUT="$(node "$S/tasks.mjs" --prune-milestone M2)"
assert_exit0 $? "prune: fully-done milestone prunes"
echo "$OUT" | grep -qF '"T-003"' && pass "prune: deleted rows echoed" || fail "prune: deleted rows echoed" "$OUT"
assert_nogrepf "$D/.sunoku/tasks.jsonl" '"id":"M2"' "prune: milestone row gone"
assert_nogrepf "$D/.sunoku/tasks.jsonl" '"id":"E-02"' "prune: epic row gone"
assert_nogrepf "$D/.sunoku/tasks.jsonl" '"id":"T-003"' "prune: task row gone"
assert_grepf "$D/.sunoku/tasks.jsonl" '"id":"M1"' "prune: survivors untouched"

node "$S/tasks.mjs" --prune-milestone M1 >/dev/null
assert_exit0 $? "prune: upstream prunable after downstream pruned"
assert_nogrepf "$D/.sunoku/tasks.jsonl" '"id":"T-001"' "prune: upstream rows gone"
unset CLAUDE_PROJECT_DIR

# --- decisions.mjs ---
D="$(mktemp -d)"; mkrecord "$D"; export CLAUDE_PROJECT_DIR="$D"
node "$S/decisions.mjs" --add '{"question":"Pricing: flat or usage-based?","stakes":"high","default":"flat $29/mo","by":"prd"}' >/dev/null
assert_exit0 $? "decisions: add"
assert_grepf "$D/.sunoku/decisions.jsonl" '"id":"D-001"' "decisions: id D-001"
assert_grepf "$D/.sunoku/decisions.jsonl" '"status":"open"' "decisions: default open"
grep -qE '"asked":"[0-9]{4}-[0-9]{2}-[0-9]{2}"' "$D/.sunoku/decisions.jsonl" && pass "decisions: asked stamped" || fail "decisions: asked stamped"

node "$S/decisions.mjs" --add '{"question":"Low stakes q","by":"research"}' >/dev/null
OUT="$(node "$S/decisions.mjs" --list high)"
echo "$OUT" | grep -qF '"D-001"' && pass "decisions: high filter hits" || fail "decisions: high filter hits" "$OUT"
echo "$OUT" | grep -qF '"D-002"' && fail "decisions: high filter excludes low" || pass "decisions: high filter excludes low"

node "$S/decisions.mjs" --resolve D-001 --answer "flat" >/dev/null
assert_exit0 $? "decisions: resolve"
assert_grepf "$D/.sunoku/decisions.jsonl" '"answer":"flat"' "decisions: answer written"
OUT="$(node "$S/decisions.mjs" --list open)"
echo "$OUT" | grep -qF '"D-001"' && fail "decisions: resolved leaves open list" || pass "decisions: resolved leaves open list"

node "$S/decisions.mjs" --add '{"question":"x","by":"ceo"}' >/dev/null 2>&1
assert_exitn $? "decisions: invalid by rejected"
node "$S/decisions.mjs" --add '{"by":"prd"}' >/dev/null 2>&1
assert_exitn $? "decisions: question required"
node "$S/decisions.mjs" --resolve D-999 --answer x >/dev/null 2>&1
assert_exitn $? "decisions: resolve unknown id dies"
unset CLAUDE_PROJECT_DIR

# --- scaffold.mjs (init) ---
SCAF="$HERE/skills/starting-a-product/scripts/scaffold.mjs"
D="$(mktemp -d)"
OUT="$(CLAUDE_PROJECT_DIR="$D" node "$SCAF" --product "Zed")"
assert_exit0 $? "scaffold: fresh run exits 0"
assert_grepf "$D/.sunoku/status.json" '"product": "Zed"' "scaffold: product written"
assert_grepf "$D/.sunoku/status.json" '"lifecycle": "defining"' "scaffold: default lifecycle defining"
assert_grepf "$D/.sunoku/status.json" '"tracking": false' "scaffold: tracking starts false"
assert_grepf "$D/.sunoku/PRD.md" '<!-- sunoku:stub -->' "scaffold: PRD stub sentinel"
assert_grepf "$D/.sunoku/.gitattributes" 'merge=union' "scaffold: jsonl merge=union"
[ -d "$D/.sunoku/research" ] && pass "scaffold: research dir" || fail "scaffold: research dir"
CLAUDE_PROJECT_DIR="$D" node "$SCAF" --product "Zed" >/dev/null 2>&1
assert_exitn $? "scaffold: refuses over existing record"
D2="$(mktemp -d)"
CLAUDE_PROJECT_DIR="$D2" node "$SCAF" --product "Zed" --lifecycle validating >/dev/null
assert_grepf "$D2/.sunoku/status.json" '"lifecycle": "validating"' "scaffold: lifecycle flag"
CLAUDE_PROJECT_DIR="$(mktemp -d)" node "$SCAF" >/dev/null 2>&1
assert_exitn $? "scaffold: product required"

# --- report.mjs (status) ---
REP="$HERE/skills/checking-status/scripts/report.mjs"
D="$(mktemp -d)"; mkrecord "$D"; export CLAUDE_PROJECT_DIR="$D"
node "$S/decisions.mjs" --add '{"question":"Big call?","stakes":"high","default":"yes","by":"prd"}' >/dev/null
node "$S/tasks.mjs" --add '{"type":"milestone","title":"Skeleton"}' >/dev/null
node "$S/tasks.mjs" --add '{"type":"epic","milestone":"M1","title":"Auth"}' >/dev/null
node "$S/tasks.mjs" --add '{"type":"task","epic":"E-01","title":"Contract","description":"Do the thing. Done when tested.","discipline":"backend","size":"S"}' >/dev/null
node "$S/tasks.mjs" --add '{"type":"task","epic":"E-01","title":"UI","description":"Build the UI layer.","discipline":"frontend","size":"M","deps":["T-001"]}' >/dev/null
touch "$D/.sunoku/research/competitors.md"
OUT="$(cd "$D" && node "$REP")"
assert_exit0 $? "report: exits 0"
echo "$OUT" | grep -qF '"product": "Testo"' && pass "report: product" || fail "report: product" "$OUT"
echo "$OUT" | grep -qF '"open": 1' && pass "report: open decisions" || fail "report: open decisions" "$OUT"
echo "$OUT" | grep -qF '"Big call?"' && pass "report: high titles" || fail "report: high titles" "$OUT"
echo "$OUT" | grep -qF '"todo": 2' && pass "report: task counts" || fail "report: task counts" "$OUT"
echo "$OUT" | grep -qF '"ready": 1' && pass "report: ready frontier" || fail "report: ready frontier" "$OUT"
echo "$OUT" | grep -qF '"frontier"' && pass "report: frontier rows" || fail "report: frontier rows" "$OUT"
echo "$OUT" | grep -qF 'Do the thing' && pass "report: frontier has description" || fail "report: frontier has description" "$OUT"
echo "$OUT" | grep -qF 'competitors.md' && pass "report: research listed" || fail "report: research listed" "$OUT"
echo "$OUT" | grep -qF '"prd_stub": false' && pass "report: prd filled" || fail "report: prd filled" "$OUT"
D2="$(mktemp -d)"; CLAUDE_PROJECT_DIR="$D2" node "$HERE/skills/starting-a-product/scripts/scaffold.mjs" --product P >/dev/null
OUT="$(CLAUDE_PROJECT_DIR="$D2" node "$REP")"
echo "$OUT" | grep -qF '"prd_stub": true' && pass "report: stub detected" || fail "report: stub detected" "$OUT"
echo "$OUT" | grep -qF '"tasks": null' && pass "report: no tasks -> null" || fail "report: no tasks -> null" "$OUT"
unset CLAUDE_PROJECT_DIR

# --- query.mjs (read) ---
Q="$HERE/skills/querying-the-record/scripts/query.mjs"
D="$(mktemp -d)"; mkrecord "$D"; export CLAUDE_PROJECT_DIR="$D"
node "$S/tasks.mjs" --add '{"type":"milestone","title":"Skeleton"}' >/dev/null
node "$S/tasks.mjs" --add '{"type":"epic","milestone":"M1","title":"Auth"}' >/dev/null
node "$S/tasks.mjs" --add '{"type":"task","epic":"E-01","title":"Contract","description":"Define the contract.","discipline":"backend","size":"S"}' >/dev/null
node "$S/decisions.mjs" --add '{"question":"Open one?","by":"plan"}' >/dev/null
printf '# Competitors\n\nAcme dominates.\n' > "$D/.sunoku/research/competitors.md"

OUT="$(node "$Q" --prd Problem)"
echo "$OUT" | grep -qF 'artifacts rot' && pass "query: prd section" || fail "query: prd section" "$OUT"
OUT="$(node "$Q" --prd Nonexistent)"
echo "$OUT" | grep -qF '"prd": null' && pass "query: missing section null" || fail "query: missing section null" "$OUT"
OUT="$(node "$Q" --changelog --since 2026-06-15)"
echo "$OUT" | grep -qF 'fast capture' && pass "query: changelog since hits" || fail "query: changelog since hits" "$OUT"
echo "$OUT" | grep -qF 'teams tier' && fail "query: changelog since excludes" || pass "query: changelog since excludes"
OUT="$(node "$Q" --tasks ready)"
echo "$OUT" | grep -qF '"T-001"' && pass "query: tasks ready" || fail "query: tasks ready" "$OUT"
OUT="$(node "$Q" --decisions open)"
echo "$OUT" | grep -qF '"Open one?"' && pass "query: decisions open" || fail "query: decisions open" "$OUT"
OUT="$(node "$Q" --research)"
echo "$OUT" | grep -qF 'competitors.md' && pass "query: research list" || fail "query: research list" "$OUT"
OUT="$(node "$Q" --research compet)"
echo "$OUT" | grep -qF 'Acme dominates' && pass "query: research file content" || fail "query: research file content" "$OUT"
OUT="$(node "$Q" --research --changelog)"
echo "$OUT" | grep -qF 'competitors.md' && pass "query: bare research composes" || fail "query: bare research composes" "$OUT"
echo "$OUT" | grep -qF '"changelog"' && pass "query: changelog survives bare research" || fail "query: changelog survives bare research" "$OUT"
OUT="$(node "$Q" --research zzz)"
echo "$OUT" | grep -qF '"research_file"' && fail "query: no null research_file key" || pass "query: no null research_file key"
echo "$OUT" | grep -qF '"research": []' && pass "query: no-match returns empty list" || fail "query: no-match returns empty list" "$OUT"
node "$Q" >/dev/null 2>&1
assert_exitn $? "query: no flags dies"
unset CLAUDE_PROJECT_DIR

# --- record-html.mjs (viewing-the-record) ---
V="$HERE/skills/viewing-the-record/scripts/record-html.mjs"
D="$(mktemp -d)"; mkrecord "$D"; export CLAUDE_PROJECT_DIR="$D"
node "$S/tasks.mjs" --add '{"type":"milestone","title":"Skeleton"}' >/dev/null
node "$S/tasks.mjs" --add '{"type":"epic","milestone":"M1","title":"Auth"}' >/dev/null
node "$S/tasks.mjs" --add '{"type":"task","epic":"E-01","title":"Contract","description":"Define auth contract. Done when agreed.","discipline":"backend","size":"S"}' >/dev/null
node "$S/decisions.mjs" --add '{"question":"Which auth provider?","stakes":"high","default":"clerk","by":"plan"}' >/dev/null
OUT="$(node "$V" --no-open)"
assert_exit0 $? "record-html: exits 0"
echo "$OUT" | grep -qF 'record.html' && pass "record-html: prints path" || fail "record-html: prints path" "$OUT"
assert_grepf "$D/.sunoku/record.html" 'Define auth contract' "record-html: task description rendered"
assert_grepf "$D/.sunoku/record.html" 'Which auth provider?' "record-html: decision rendered"
assert_grepf "$D/.sunoku/record.html" 'Skeleton' "record-html: milestone rendered"
grep -qE 'https?://' "$D/.sunoku/record.html" && fail "record-html: no external assets" || pass "record-html: no external assets"
node "$S/tasks.mjs" --add '{"type":"task","epic":"E-01","title":"x\"><b>evil</b>","description":"Escape me. Done when safe.","discipline":"qa","size":"S"}' >/dev/null
node "$V" --no-open >/dev/null
assert_nogrepf "$D/.sunoku/record.html" '"><b>evil</b>' "record-html: hostile title escaped"
CLAUDE_PROJECT_DIR="$(mktemp -d)" node "$V" --no-open >/dev/null 2>&1
assert_exitn $? "record-html: no record dies"
unset CLAUDE_PROJECT_DIR

# --- duplicate id guards ---
D="$(mktemp -d)"; mkrecord "$D"; export CLAUDE_PROJECT_DIR="$D"
node "$S/tasks.mjs" --add '{"type":"task","title":"a","description":"Task a.","discipline":"backend","size":"S"}' >/dev/null
node "$S/tasks.mjs" --add '{"type":"task","id":"T-001","title":"b","description":"Task b.","discipline":"backend","size":"S"}' >/dev/null 2>&1
assert_exitn $? "tasks: duplicate explicit id rejected"
node "$S/decisions.mjs" --add '{"question":"q","by":"prd"}' >/dev/null
node "$S/decisions.mjs" --add '{"question":"q2","id":"D-001","by":"prd"}' >/dev/null 2>&1
assert_exitn $? "decisions: duplicate explicit id rejected"
unset CLAUDE_PROJECT_DIR

echo; echo "test-scripts: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
