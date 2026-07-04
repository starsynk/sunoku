#!/usr/bin/env bash
# Behavior tests for the deterministic record scripts in scripts/.
# Same conventions as test-hooks.sh: temp-dir fixtures, PASS/FAIL counters, exit 1 on any FAIL.
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
S="$HERE/scripts"
PV="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$HERE/.claude-plugin/plugin.json" | head -n1)"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1${2:+ ($2)}"; FAIL=$((FAIL+1)); }
assert_grep()   { grep -qE -- "$2" "$1" 2>/dev/null && pass "$3" || fail "$3" "pattern '$2' not in $1"; }
assert_grepf()  { grep -qF -- "$2" "$1" 2>/dev/null && pass "$3" || fail "$3" "literal '$2' not in $1"; }
assert_nogrepf(){ grep -qF -- "$2" "$1" 2>/dev/null && fail "$3" "literal '$2' still in $1" || pass "$3"; }
assert_exit0()  { [ "$1" -eq 0 ] && pass "$2" || fail "$2" "exit=$1"; }
assert_exitn()  { [ "$1" -ne 0 ] && pass "$2" || fail "$2" "expected nonzero exit"; }

mkrecord() { # $1 = dir; git repo + full current-shape live record
  mkdir -p "$1/.sunoku/research" "$1/.sunoku/journal" 2>/dev/null
  rmdir "$1/.sunoku/journal" 2>/dev/null # only pre-create research; journal dir is rollover's job
  cd "$1"
  git init -q; git config user.email t@t; git config user.name t
  echo hi > f.txt; git add .; git commit -qm init
  SHA="$(git rev-parse HEAD)"
  cat > .sunoku/status.json <<EOF
{
  "version": 1,
  "sunokuVersion": "$PV",
  "product": "Testo",
  "origin": "existing",
  "lifecycle": "live",
  "tracking": true,
  "one_liner": "Testo",
  "open_questions": 0,
  "high_stakes": 0,
  "last_entry": "",
  "last_reconciled_sha": "$SHA",
  "created": "2026-07-02T00:00:00Z",
  "updated": "2026-07-02T00:00:00Z"
}
EOF
  cat > .sunoku/PRD.md <<'EOF'
# PRD — Testo

> Living document.

## Problem

Planning artifacts rot and
teams forget why. More prose here that is not the first sentence.

## Personas

- Someone.
EOF
  cat > .sunoku/QUESTIONS.md <<'EOF'
# Open Questions — Testo

> Open questions only. Format per entry:
> ## Q-<n> — <title>  (stakes: high|normal, status: open)

## Q-1 — First question  (stakes: normal, status: open)
**Assumption taken:** A.
**Reasoning:** B.
**Flip if wrong:** C.

## Q-2 — Second question  (stakes: high, status: open)
**Assumption taken:** D.
**Reasoning:** E.
**Flip if wrong:** F.
EOF
  cat > .sunoku/JOURNAL.md <<'EOF'
# Journal — Testo

> Append-only. Entry types: track | reshape | decision. Newest at the bottom.
> Entry header pattern (machine-scanned): `## YYYY-MM-DD — <type>`

## 2026-07-02 — track
**What:** Record armed.
**Why:** Start.
**Refs:** conversation
EOF
  cat > .sunoku/TASKS.md <<'EOF'
# Tasks — Testo

> Sizes: S / M / L. `[SPIKE]` marks genuine unknowns. Every task traces to a PRD requirement.
> Status: todo / doing / done / blocked — maintained by whoever executes the task (canon
> Execution contract); reconcile flips rows whose work the diff proves landed.

## M1 — Walking skeleton
| ID | Task | Size | Trace | Depends on | Status |
|---|---|---|---|---|---|
| T1 | Skeleton | S | F-1 | — | done |
| T2 | Thing | M | F-2 | T1 | todo |

## Blocked
<!-- | ID | Attempts | Reason | -->
EOF
  export CLAUDE_PROJECT_DIR="$1"
}

run() { node "$S/$1" "${@:2}" 2>&1; }

# ---------- status-write.mjs ----------

D="$(mktemp -d)"; mkrecord "$D"
OUT="$(run status-write.mjs --set lifecycle=live --set tracking=false)"; RC=$?
assert_exit0 $RC "status-write: set exits 0"
assert_grepf .sunoku/status.json '"tracking": false' "status-write: boolean serialized bare"
assert_grepf .sunoku/status.json "\"sunokuVersion\": \"$PV\"" "status-write: sunokuVersion restamped"
assert_nogrepf .sunoku/status.json '"updated": "2026-07-02T00:00:00Z"' "status-write: updated restamped"
assert_grepf .sunoku/status.json '"created": "2026-07-02T00:00:00Z"' "status-write: created untouched"
# canonical shape: one key per line, exact order, trailing newline
KEYS="$(grep -o '"[a-z_A-Z]*":' .sunoku/status.json | tr -d '":' | tr '\n' ' ')"
[ "$KEYS" = "version sunokuVersion product origin lifecycle tracking one_liner open_questions high_stakes last_entry last_reconciled_sha created updated " ] \
  && pass "status-write: canonical key order" || fail "status-write: canonical key order" "$KEYS"
[ -z "$(tail -c 1 .sunoku/status.json)" ] && pass "status-write: trailing newline" || fail "status-write: trailing newline"

OUT="$(run status-write.mjs --refresh)"; RC=$?
assert_exit0 $RC "status-write: refresh exits 0"
assert_grepf .sunoku/status.json '"open_questions": 2' "status-write: refresh counts open questions"
assert_grepf .sunoku/status.json '"high_stakes": 1' "status-write: refresh counts high stakes"
assert_grepf .sunoku/status.json '"one_liner": "Planning artifacts rot and teams forget why."' "status-write: refresh one_liner = PRD first sentence, joined"
assert_grepf .sunoku/status.json '"last_entry": "2026-07-02 — track — Record armed."' "status-write: refresh last_entry from journal"

git -C "$D" commit -qam more --allow-empty
OUT="$(run status-write.mjs --sha-head)"; RC=$?
assert_exit0 $RC "status-write: sha-head exits 0"
assert_grepf .sunoku/status.json "\"last_reconciled_sha\": \"$(git -C "$D" rev-parse HEAD)\"" "status-write: sha-head writes HEAD"

BEFORE="$(cksum .sunoku/status.json)"
OUT="$(run status-write.mjs --set bogus_key=1)"; RC=$?
assert_exitn $RC "status-write: unknown key rejected"
[ "$BEFORE" = "$(cksum .sunoku/status.json)" ] && pass "status-write: reject leaves file untouched" || fail "status-write: reject leaves file untouched"

OUT="$(run status-write.mjs --set lifecycle=bogus)"; RC=$?
assert_exitn $RC "status-write: invalid lifecycle rejected"

D2="$(mktemp -d)"; cd "$D2"; export CLAUDE_PROJECT_DIR="$D2"
OUT="$(run status-write.mjs --set tracking=true)"; RC=$?
assert_exitn $RC "status-write: no record -> nonzero"

# ---------- report.mjs ----------

D="$(mktemp -d)"; mkrecord "$D"
git -C "$D" commit -qam drift1 --allow-empty
OUT="$(run report.mjs)"; RC=$?
assert_exit0 $RC "report: exits 0"
echo "$OUT" | node -e 'JSON.parse(require("fs").readFileSync(0,"utf8"))' 2>/dev/null && pass "report: valid JSON" || fail "report: valid JSON" "$OUT"
echo "$OUT" | grep -qF '"lifecycle": "live"' && pass "report: lifecycle" || fail "report: lifecycle" "$OUT"
echo "$OUT" | grep -qF '"drift": 1' && pass "report: drift counted" || fail "report: drift" "$OUT"
echo "$OUT" | grep -qF '"dirty": false' && pass "report: clean tree" || fail "report: dirty flag" "$OUT"
echo "$OUT" | grep -qF '"todo": 1' && pass "report: task todo count" || fail "report: task counts" "$OUT"
echo "$OUT" | grep -qF '"done": 1' && pass "report: task done count" || fail "report: task counts" "$OUT"
echo "$OUT" | grep -qF '"high_stakes_titles"' && pass "report: high-stakes titles key" || fail "report: high-stakes titles" "$OUT"
echo "$OUT" | grep -qF 'Second question' && pass "report: names high-stakes entry" || fail "report: names high-stakes entry" "$OUT"

echo dirty >> f.txt
OUT="$(run report.mjs)"
echo "$OUT" | grep -qF '"dirty": true' && pass "report: dirty tree flagged" || fail "report: dirty tree" "$OUT"

# empty last_reconciled_sha -> full-history fallback
sed -i.bak "s/\"last_reconciled_sha\": \"[a-f0-9]*\"/\"last_reconciled_sha\": \"\"/" .sunoku/status.json
OUT="$(run report.mjs)"
N="$(git -C "$D" rev-list --count HEAD)"
echo "$OUT" | grep -qF "\"drift\": $N" && pass "report: empty-sha fallback counts all history" || fail "report: empty-sha fallback" "$OUT"

D2="$(mktemp -d)"; cd "$D2"; export CLAUDE_PROJECT_DIR="$D2"
OUT="$(run report.mjs)"; RC=$?
assert_exitn $RC "report: no record -> nonzero"

# ---------- journal-append.mjs ----------

D="$(mktemp -d)"; mkrecord "$D"
printf '<!-- sunoku:stub -->\n# Journal — Testo\n\n> Append-only. Entry types: track | reshape | decision. Newest at the bottom.\n> Entry header pattern (machine-scanned): `## YYYY-MM-DD — <type>`\n' > .sunoku/JOURNAL.md
OUT="$(run journal-append.mjs --type track --what "Did a thing." --why "Because." --refs "abc123")"; RC=$?
assert_exit0 $RC "journal: append exits 0"
assert_nogrepf .sunoku/JOURNAL.md '<!-- sunoku:stub -->' "journal: stub sentinel removed"
assert_grep .sunoku/JOURNAL.md '^## [0-9]{4}-[0-9]{2}-[0-9]{2} — track$' "journal: dated header appended"
assert_grepf .sunoku/JOURNAL.md '**What:** Did a thing.' "journal: What line"
assert_grepf .sunoku/JOURNAL.md '**Refs:** abc123' "journal: Refs line"
assert_grepf .sunoku/status.json 'track — Did a thing.' "journal: status last_entry auto-refreshed"

OUT="$(run journal-append.mjs --type decision --what "Second." --why "W." --refs "conversation")"
LAST="$(grep '^## ' .sunoku/JOURNAL.md | tail -1)"
echo "$LAST" | grep -q 'decision' && pass "journal: newest at bottom" || fail "journal: newest at bottom" "$LAST"

OUT="$(run journal-append.mjs --type track --why "no what" --refs x)"; RC=$?
assert_exitn $RC "journal: missing --what rejected"

OUT="$(run journal-append.mjs --type bogus --what w --why y --refs r)"; RC=$?
assert_exitn $RC "journal: invalid type rejected"

# rollover: inflate past 30KB, next append must archive oldest entries down under 15KB
D="$(mktemp -d)"; mkrecord "$D"
{ for i in $(seq 1 40); do
    printf '\n## 2025-01-%02d — track\n**What:** Entry %d.\n**Why:** %s\n**Refs:** conversation\n' "$((i % 28 + 1))" "$i" "$(printf 'x%.0s' $(seq 1 900))"
  done; } >> .sunoku/JOURNAL.md
OUT="$(run journal-append.mjs --type track --what "Trigger rollover." --why "Big." --refs c)"; RC=$?
assert_exit0 $RC "journal: rollover append exits 0"
SZ="$(wc -c < .sunoku/JOURNAL.md | tr -d ' ')"
[ "$SZ" -le 15360 ] && pass "journal: rolled down under 15KB" || fail "journal: rolled down under 15KB" "size=$SZ"
[ -f .sunoku/journal/2025.md ] && pass "journal: archive file by entry year" || fail "journal: archive file by entry year"
assert_grepf .sunoku/journal/2025.md '**What:** Entry 1.' "journal: oldest entry archived first"
assert_grepf .sunoku/JOURNAL.md 'Trigger rollover.' "journal: new entry survives rollover"
assert_grepf .sunoku/JOURNAL.md '> Older entries: .sunoku/journal/' "journal: header points at archive"
assert_grepf .sunoku/JOURNAL.md '# Journal — Testo' "journal: header block intact"
TOTAL="$(cat .sunoku/JOURNAL.md .sunoku/journal/2025.md .sunoku/journal/2026.md 2>/dev/null | grep -c '^## ')"
[ "$TOTAL" -eq 42 ] && pass "journal: no entries lost in rollover" || fail "journal: no entries lost" "total=$TOTAL"

# ---------- questions-flush.mjs ----------

D="$(mktemp -d)"; mkrecord "$D"
node "$S/status-write.mjs" --refresh >/dev/null 2>&1 # seed counts
OUT="$(run questions-flush.mjs --id Q-1)"; RC=$?
assert_exit0 $RC "questions: flush exits 0"
assert_nogrepf .sunoku/QUESTIONS.md 'Q-1 — First question' "questions: block deleted"
assert_grepf .sunoku/QUESTIONS.md 'Q-2 — Second question' "questions: survivor intact"
assert_grepf .sunoku/status.json '"open_questions": 1' "questions: count refreshed"

BEFORE="$(cksum .sunoku/QUESTIONS.md)"
OUT="$(run questions-flush.mjs --id Q-9)"; RC=$?
assert_exitn $RC "questions: unknown id -> nonzero"
[ "$BEFORE" = "$(cksum .sunoku/QUESTIONS.md)" ] && pass "questions: unknown id leaves file untouched" || fail "questions: unknown id leaves file untouched"

# ---------- tasks-set.mjs ----------

D="$(mktemp -d)"; mkrecord "$D"
OUT="$(run tasks-set.mjs --id T2 --status done)"; RC=$?
assert_exit0 $RC "tasks: flip exits 0"
grep -E '^\| T2 \|' .sunoku/TASKS.md | grep -q '| done |$' && pass "tasks: T2 flipped to done" || fail "tasks: T2 flipped" "$(grep T2 .sunoku/TASKS.md)"
grep -E '^\| T1 \|' .sunoku/TASKS.md | grep -q '| done |$' && pass "tasks: T1 untouched" || fail "tasks: T1 untouched"
OUT="$(run tasks-set.mjs --id T9 --status done)"; RC=$?
assert_exitn $RC "tasks: unknown id -> nonzero"
OUT="$(run tasks-set.mjs --id T2 --status bogus)"; RC=$?
assert_exitn $RC "tasks: invalid status rejected"

# ---------- scaffold.mjs ----------

D="$(mktemp -d)"; cd "$D"; export CLAUDE_PROJECT_DIR="$D"; git init -q
OUT="$(run scaffold.mjs --product "Fresh" --origin greenfield)"; RC=$?
assert_exit0 $RC "scaffold: greenfield exits 0"
for f in BRIEF.md PRD.md JOURNAL.md QUESTIONS.md research/EVIDENCE.md .gitignore status.json; do
  [ -f ".sunoku/$f" ] && pass "scaffold: $f created" || fail "scaffold: $f created"
done
[ -d .sunoku/research/.fragments ] && pass "scaffold: fragments dir" || fail "scaffold: fragments dir"
[ -d .sunoku/validation ] && pass "scaffold: greenfield validation dir" || fail "scaffold: validation dir"
assert_grepf .sunoku/BRIEF.md '<!-- sunoku:stub -->' "scaffold: sentinel intact in stub"
assert_grepf .sunoku/status.json '"lifecycle": "validating"' "scaffold: greenfield lifecycle"
assert_grepf .sunoku/status.json '"tracking": false' "scaffold: tracking off until arm"
assert_grepf .sunoku/status.json '"one_liner": "Fresh"' "scaffold: one_liner = product"
assert_grepf .sunoku/status.json "\"sunokuVersion\": \"$PV\"" "scaffold: plugin version stamped"
C="$(sed -n 's/.*"created": "\([^"]*\)".*/\1/p' .sunoku/status.json)"
U="$(sed -n 's/.*"updated": "\([^"]*\)".*/\1/p' .sunoku/status.json)"
[ -n "$C" ] && [ "$C" = "$U" ] && pass "scaffold: created == updated" || fail "scaffold: created == updated" "$C vs $U"

OUT="$(run scaffold.mjs --product "Fresh" --origin greenfield)"; RC=$?
assert_exitn $RC "scaffold: refuses over existing record"

D="$(mktemp -d)"; cd "$D"; export CLAUDE_PROJECT_DIR="$D"; git init -q
OUT="$(run scaffold.mjs --product "Old" --origin existing)"; RC=$?
assert_exit0 $RC "scaffold: existing exits 0"
assert_grepf .sunoku/status.json '"lifecycle": "defining"' "scaffold: existing lifecycle"
[ -d .sunoku/validation ] && fail "scaffold: existing skips validation dir" || pass "scaffold: existing skips validation dir"

# ---------- sentinels.mjs ----------

D="$(mktemp -d)"; cd "$D"; export CLAUDE_PROJECT_DIR="$D"; git init -q
node "$S/scaffold.mjs" --product "Fresh" --origin greenfield >/dev/null 2>&1
OUT="$(run sentinels.mjs)"; RC=$?
assert_exit0 $RC "sentinels: exits 0"
echo "$OUT" | grep -qF '"BRIEF.md": "stub"' && pass "sentinels: stub detected" || fail "sentinels: stub" "$OUT"
echo "$OUT" | grep -qF '"ROADMAP.md": "missing"' && pass "sentinels: missing detected" || fail "sentinels: missing" "$OUT"
printf '# Brief — Fresh\n\nReal content.\n' > .sunoku/BRIEF.md
printf '# Journal — Fresh\n\n> Append-only.\n' > .sunoku/JOURNAL.md
OUT="$(run sentinels.mjs)"
echo "$OUT" | grep -qF '"BRIEF.md": "done"' && pass "sentinels: done detected" || fail "sentinels: done" "$OUT"
echo "$OUT" | grep -qF '"JOURNAL.md": "empty-ledger"' && pass "sentinels: empty ledger not done" || fail "sentinels: empty ledger" "$OUT"
printf '\n## 2026-07-04 — track\n**What:** X.\n**Why:** Y.\n**Refs:** c\n' >> .sunoku/JOURNAL.md
OUT="$(run sentinels.mjs)"
echo "$OUT" | grep -qF '"JOURNAL.md": "done"' && pass "sentinels: ledger with entry done" || fail "sentinels: ledger done" "$OUT"

# ---------- migrate.mjs ----------

D="$(mktemp -d)"; mkrecord "$D"
# 1.0-shape: no sunokuVersion, no summary fields, TASKS without Status column
cat > .sunoku/status.json <<EOF
{
  "version": 1,
  "product": "Testo",
  "origin": "existing",
  "lifecycle": "live",
  "tracking": true,
  "last_reconciled_sha": "",
  "created": "2026-07-02T00:00:00Z",
  "updated": "2026-07-02T00:00:00Z"
}
EOF
cat > .sunoku/TASKS.md <<'EOF'
# Tasks — Testo

> Sizes: S / M / L. `[SPIKE]` marks genuine unknowns. Every task traces to a PRD requirement.

## M1 — Walking skeleton
| ID | Task | Size | Trace | Depends on |
|---|---|---|---|---|
| T1 | Skeleton | S | F-1 | — |
| T2 | Thing | M | F-2 | T1 |
EOF
OUT="$(run migrate.mjs)"; RC=$?
assert_exit0 $RC "migrate: exits 0"
echo "$OUT" | grep -q 'migrated' && pass "migrate: reports migrations" || fail "migrate: reports" "$OUT"
assert_grepf .sunoku/status.json "\"sunokuVersion\": \"$PV\"" "migrate: sunokuVersion inserted"
assert_grepf .sunoku/status.json '"open_questions": 2' "migrate: 1.3.0 summary fields computed"
assert_grepf .sunoku/status.json '"one_liner": "Planning artifacts rot and teams forget why."' "migrate: one_liner from PRD"
KEYS="$(grep -o '"[a-z_A-Z]*":' .sunoku/status.json | tr -d '":' | tr '\n' ' ')"
[ "$KEYS" = "version sunokuVersion product origin lifecycle tracking one_liner open_questions high_stakes last_entry last_reconciled_sha created updated " ] \
  && pass "migrate: canonical key order" || fail "migrate: canonical key order" "$KEYS"
grep -E '^\| ID \| Task \| Size \| Trace \| Depends on \| Status \|$' .sunoku/TASKS.md >/dev/null && pass "migrate: Status column in header" || fail "migrate: Status header" "$(head -8 .sunoku/TASKS.md)"
grep -E '^\| T1 \| Skeleton \| S \| F-1 \| — \| todo \|$' .sunoku/TASKS.md >/dev/null && pass "migrate: todo appended to rows" || fail "migrate: todo rows" "$(grep T1 .sunoku/TASKS.md)"
assert_grepf .sunoku/TASKS.md '## Blocked' "migrate: Blocked section added"
assert_grepf .sunoku/TASKS.md '> Status: todo / doing / done / blocked' "migrate: legend added"

B1="$(cksum .sunoku/status.json)"; B2="$(cksum .sunoku/TASKS.md)"
OUT="$(run migrate.mjs)"; RC=$?
assert_exit0 $RC "migrate: idempotent run exits 0"
echo "$OUT" | grep -qi 'up to date' && pass "migrate: reports up to date" || fail "migrate: up-to-date report" "$OUT"
[ "$B1" = "$(cksum .sunoku/status.json)" ] && [ "$B2" = "$(cksum .sunoku/TASKS.md)" ] \
  && pass "migrate: idempotent (no byte changes)" || fail "migrate: idempotent"

# 1.2.0 legend row: sunoku:work legend replaced
D="$(mktemp -d)"; mkrecord "$D"
sed -i.bak 's|^> Status: todo.*$|> Status: todo / doing / done / blocked — worked by `sunoku:work`, one task per loop iteration.|' .sunoku/TASKS.md
sed -i.bak '/^> Execution contract); reconcile flips/d' .sunoku/TASKS.md
OUT="$(run migrate.mjs)"; RC=$?
assert_exit0 $RC "migrate: legend run exits 0"
assert_nogrepf .sunoku/TASKS.md 'sunoku:work' "migrate: stale legend replaced"
assert_grepf .sunoku/TASKS.md 'reconcile flips rows whose work the diff proves landed' "migrate: current legend present"

# ---------- 1.6.0: baseline-lost detection ----------

D="$(mktemp -d)"; mkrecord "$D"
OUT="$(run report.mjs)"
echo "$OUT" | grep -qF '"baseline_lost": false' && pass "report: reachable sha -> baseline_lost false" || fail "report: baseline_lost false" "$OUT"
sed -i.bak 's/"last_reconciled_sha": "[a-f0-9]*"/"last_reconciled_sha": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"/' .sunoku/status.json
OUT="$(run report.mjs)"
echo "$OUT" | grep -qF '"baseline_lost": true' && pass "report: unreachable sha -> baseline_lost true" || fail "report: baseline_lost true" "$OUT"
echo "$OUT" | grep -qF '"drift": null' && pass "report: lost baseline -> drift null" || fail "report: lost baseline drift" "$OUT"

# ---------- 1.6.0: journal field sanitization + last_entry cap ----------

D="$(mktemp -d)"; mkrecord "$D"
OUT="$(run journal-append.mjs --type track --what "$(printf 'Line one.\nLine two.')" --why "W." --refs c)"; RC=$?
assert_exit0 $RC "journal: newline in --what accepted"
assert_grepf .sunoku/JOURNAL.md '**What:** Line one. Line two.' "journal: newlines collapsed to one line"

LONG="$(printf 'x%.0s' $(seq 1 200))"
OUT="$(run journal-append.mjs --type track --what "$LONG" --why "W." --refs c)"
assert_grepf .sunoku/JOURNAL.md "$LONG" "journal: full What kept in entry"
grep -oE 'x{150}' .sunoku/status.json >/dev/null && fail "status: last_entry capped" "150+ run of x in status.json" || pass "status: last_entry capped"
assert_grepf .sunoku/status.json '…' "status: capped last_entry marked with ellipsis"

# ---------- 1.6.0: tasks-set id regex-escaped ----------

D="$(mktemp -d)"; mkrecord "$D"
OUT="$(run tasks-set.mjs --id "T1." --status done)"; RC=$?
assert_exitn $RC "tasks: dot in id does not wildcard-match"

# ---------- 1.6.0: report per-milestone counts ----------

D="$(mktemp -d)"; mkrecord "$D"
OUT="$(run report.mjs)"
echo "$OUT" | grep -qF '"milestones"' && pass "report: milestones key" || fail "report: milestones key" "$OUT"
echo "$OUT" | node -e '
const r = JSON.parse(require("fs").readFileSync(0, "utf8"));
const m = (r.milestones || [])[0] || {};
process.exit(m.name === "M1 — Walking skeleton" && m.total === 2 && m.done === 1 ? 0 : 1);
' && pass "report: per-milestone counts" || fail "report: per-milestone counts" "$OUT"

# ---------- 1.6.0: merge=union gitattributes (scaffold + migrate) ----------

D="$(mktemp -d)"; cd "$D"; export CLAUDE_PROJECT_DIR="$D"; git init -q
run scaffold.mjs --product "Fresh" --origin greenfield >/dev/null
[ -f .sunoku/.gitattributes ] && pass "scaffold: .gitattributes created" || fail "scaffold: .gitattributes created"
assert_grepf .sunoku/.gitattributes 'JOURNAL.md merge=union' "scaffold: journal merge=union"

D="$(mktemp -d)"; mkrecord "$D"
OUT="$(run migrate.mjs)"; RC=$?
assert_exit0 $RC "migrate: gitattributes run exits 0"
[ -f .sunoku/.gitattributes ] && pass "migrate: .gitattributes backfilled" || fail "migrate: .gitattributes backfilled"
assert_grepf .sunoku/.gitattributes 'JOURNAL.md merge=union' "migrate: journal merge=union backfilled"
OUT="$(run migrate.mjs)"
echo "$OUT" | grep -qi 'up to date' && pass "migrate: gitattributes idempotent" || fail "migrate: gitattributes idempotent" "$OUT"

# ---------- 1.7.0: doctor.mjs ----------

D="$(mktemp -d)"; mkrecord "$D"
node "$S/migrate.mjs" >/dev/null 2>&1        # healthy = migrated (gitattributes present)
node "$S/status-write.mjs" --refresh >/dev/null 2>&1 # ...and summary index in sync
OUT="$(run doctor.mjs)"; RC=$?
assert_exit0 $RC "doctor: healthy record exits 0"
echo "$OUT" | grep -qF '"ok": true' && pass "doctor: healthy record ok" || fail "doctor: healthy ok" "$OUT"

# break things: duplicate task id, bad journal header, unreachable baseline, stray tmp, two doing
sed -i.bak 's/| T2 | Thing | M | F-2 | T1 | todo |/| T1 | Thing | M | F-2 | T1 | doing |/' .sunoku/TASKS.md
printf '\n## 2026-13-99 broken header\ntext\n' >> .sunoku/JOURNAL.md
sed -i.bak 's/"last_reconciled_sha": "[a-f0-9]*"/"last_reconciled_sha": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"/' .sunoku/status.json
touch .sunoku/PRD.md.tmp-999
OUT="$(run doctor.mjs)"; RC=$?
assert_exit0 $RC "doctor: findings still exit 0"
echo "$OUT" | grep -qF '"ok": false' && pass "doctor: broken record not ok" || fail "doctor: broken not ok" "$OUT"
for check in tasks_duplicate_id journal_header baseline_unreachable stray_tmp; do
  echo "$OUT" | grep -qF "\"$check\"" && pass "doctor: flags $check" || fail "doctor: flags $check" "$OUT"
done

D2="$(mktemp -d)"; cd "$D2"; export CLAUDE_PROJECT_DIR="$D2"
OUT="$(run doctor.mjs)"; RC=$?
assert_exitn $RC "doctor: no record -> nonzero"

# ---------- 1.7.0: digest.mjs ----------

D="$(mktemp -d)"; mkrecord "$D"
run journal-append.mjs --type track --what "Fresh work landed." --why "Because tests." --refs c >/dev/null
OUT="$(run digest.mjs)"; RC=$?
assert_exit0 $RC "digest: exits 0"
DG=".sunoku/digest/$(date +%F).md"
[ -f "$DG" ] && pass "digest: dated file written" || fail "digest: dated file written" "$OUT"
assert_grepf "$DG" 'Testo' "digest: product named"
assert_grepf "$DG" 'Planning artifacts rot' "digest: problem excerpt"
assert_grepf "$DG" 'Fresh work landed.' "digest: recent journal entry included"
assert_grepf "$DG" 'Second question' "digest: open question listed"
OUT="$(run digest.mjs --days 1)"
grep -qF 'Record armed.' "$DG" && fail "digest: --days window excludes old entries" || pass "digest: --days window excludes old entries"

# ---------- 1.7.0: validation staleness ----------

D="$(mktemp -d)"; mkrecord "$D"
OUT="$(run report.mjs)"
echo "$OUT" | grep -qF '"validation_stale": null' && pass "report: no reports -> stale null" || fail "report: stale null" "$OUT"
mkdir -p .sunoku/validation
echo x > .sunoku/validation/2020-01-01-validation.md
OUT="$(run report.mjs)"
echo "$OUT" | grep -qF '"validation_stale": true' && pass "report: old report -> stale true" || fail "report: stale true" "$OUT"
echo x > ".sunoku/validation/$(date +%F)-validation.md"
OUT="$(run report.mjs)"
echo "$OUT" | grep -qF '"validation_stale": false' && pass "report: fresh report -> stale false" || fail "report: stale false" "$OUT"

# ---------- 1.7.0: journal tags + report --since/--tag ----------

D="$(mktemp -d)"; mkrecord "$D"
OUT="$(run journal-append.mjs --type decision --what "Priced it." --why "W." --refs c --tags "pricing, auth")"; RC=$?
assert_exit0 $RC "journal: --tags accepted"
assert_grepf .sunoku/JOURNAL.md '**Tags:** pricing, auth' "journal: Tags line written"
run journal-append.mjs --type track --what "Untagged." --why "W." --refs c >/dev/null
N="$(grep -c '\*\*Tags:\*\*' .sunoku/JOURNAL.md)"
[ "$N" = "1" ] && pass "journal: no Tags line without --tags" || fail "journal: no Tags line without --tags" "count=$N"

OUT="$(run report.mjs --tag pricing)"
echo "$OUT" | node -e '
const r = JSON.parse(require("fs").readFileSync(0, "utf8"));
const whats = (r.journal_matches || []).map((m) => m.what);
process.exit(whats.includes("Priced it.") && !whats.includes("Untagged.") ? 0 : 1);
' && pass "report: --tag matches tagged, excludes untagged" || fail "report: --tag filter" "$OUT"
OUT="$(run report.mjs --since 2020-01-01)"
echo "$OUT" | grep -qF '"journal_matches"' && pass "report: --since emits matches" || fail "report: --since emits matches" "$OUT"
echo "$OUT" | grep -qF 'Record armed.' && pass "report: --since includes window" || fail "report: --since window" "$OUT"
OUT="$(run report.mjs --since 2999-01-01)"
echo "$OUT" | grep -qF 'Record armed.' && fail "report: --since excludes older" "$OUT" || pass "report: --since excludes older"

# ---------- 1.6.0: atomic writes leave no temp files ----------

D="$(mktemp -d)"; mkrecord "$D"
run journal-append.mjs --type track --what "A." --why "B." --refs c >/dev/null
run status-write.mjs --refresh >/dev/null
run questions-flush.mjs --id Q-1 >/dev/null
STRAY="$(find .sunoku -name '*.tmp-*' | wc -l | tr -d ' ')"
[ "$STRAY" = "0" ] && pass "atomic: no stray temp files" || fail "atomic: no stray temp files" "found $STRAY"

echo "---"; echo "$PASS passed, $FAIL failed"; [ "$FAIL" -eq 0 ]
