#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SS="$HERE/hooks/scripts/session-start.sh"
SN="$HERE/hooks/scripts/stop-nudge.sh"
PASS=0; FAIL=0

check() { # name expected_exit expected_stdout_substr actual_exit actual_out
  if [ "$4" -eq "$2" ] && { [ -z "$3" ] && [ -z "$5" ] || printf '%s' "$5" | grep -q "$3"; }; then
    echo "PASS: $1"; PASS=$((PASS+1))
  else
    echo "FAIL: $1 (exit=$4 out=$5)"; FAIL=$((FAIL+1))
  fi
}

mkrepo() { # $1 = dir; creates git repo with live tracking status.json
  mkdir -p "$1/.sunoku"; cd "$1"
  git init -q; git config user.email t@t; git config user.name t
  echo hi > f.txt; git add .; git commit -qm init
  SHA="$(git rev-parse HEAD)"
  cat > .sunoku/status.json <<EOF
{
  "version": 1,
  "product": "T",
  "origin": "greenfield",
  "lifecycle": "live",
  "tracking": true,
  "last_reconciled_sha": "$SHA",
  "created": "2026-07-02T00:00:00Z",
  "updated": "2026-07-02T00:00:00Z"
}
EOF
}

STDIN_MAIN='{"session_id":"s1","hook_event_name":"SessionStart","source":"startup"}'
STDIN_SUB='{"session_id":"s1","agent_id":"a1","hook_event_name":"SessionStart"}'

# 1. No .sunoku -> silent no-op
D="$(mktemp -d)"; cd "$D"; git init -q
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" bash "$SS")"; check "no-record no-op" 0 "" $? "$OUT"

# 2. Tracking off -> silent
D="$(mktemp -d)"; mkrepo "$D"
sed -i.bak 's/"tracking": true/"tracking": false/' .sunoku/status.json
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" bash "$SS")"; check "muted no-op" 0 "" $? "$OUT"

# 3. Live+tracking -> injects context + writes snapshot
D="$(mktemp -d)"; mkrepo "$D"
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" bash "$SS")"
check "inject rule" 0 "additionalContext" $? "$OUT"
[ -f "$D/.sunoku/.cache/session-s1" ] && echo "PASS: snapshot" && PASS=$((PASS+1)) || { echo "FAIL: snapshot"; FAIL=$((FAIL+1)); }

# 4. Drift -> mentions Drift
D="$(mktemp -d)"; mkrepo "$D"
echo more >> f.txt; git commit -qam second
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" bash "$SS")"; check "drift surfaced" 0 "Drift: 1" $? "$OUT"

# 5. Subagent -> silent
D="$(mktemp -d)"; mkrepo "$D"
OUT="$(printf '%s' "$STDIN_SUB" | CLAUDE_PROJECT_DIR="$D" bash "$SS")"; check "subagent no-op" 0 "" $? "$OUT"

# 6. Stop: no snapshot -> silent
D="$(mktemp -d)"; mkrepo "$D"
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" bash "$SN")"; check "stop no-snapshot no-op" 0 "" $? "$OUT"

# 7. Stop: change + empty journal -> nudge once, then marker suppresses
D="$(mktemp -d)"; mkrepo "$D"
printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" bash "$SS" >/dev/null
echo change >> f.txt
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" bash "$SN")"; check "stop nudges" 0 "sunoku:log" $? "$OUT"
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" bash "$SN")"; check "nudge once only" 0 "" $? "$OUT"

# 8. Stop: journal updated after snapshot -> silent
D="$(mktemp -d)"; mkrepo "$D"
printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" bash "$SS" >/dev/null
echo change >> f.txt; sleep 1; echo "## 2026-07-02 - track" >> .sunoku/JOURNAL.md
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" bash "$SN")"; check "journal-written no-op" 0 "" $? "$OUT"

# 9. Malformed status.json -> silent
D="$(mktemp -d)"; mkrepo "$D"; echo '{broken' > .sunoku/status.json
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" bash "$SS")"; check "malformed no-op" 0 "" $? "$OUT"

# 10. JSON output is valid JSON
D="$(mktemp -d)"; mkrepo "$D"
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" bash "$SS")"
printf '%s' "$OUT" | python3 -m json.tool >/dev/null 2>&1 && { echo "PASS: valid json"; PASS=$((PASS+1)); } || { echo "FAIL: valid json"; FAIL=$((FAIL+1)); }

echo "---"; echo "$PASS passed, $FAIL failed"; [ "$FAIL" -eq 0 ]
