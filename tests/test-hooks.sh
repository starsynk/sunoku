#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SS="$HERE/hooks/scripts/session-start.mjs"
GW="$HERE/hooks/scripts/guard-record-writes.mjs"
PASS=0; FAIL=0

check() { # name expected_exit expected_stdout_substr actual_exit actual_out
  ok=0
  if [ "$4" -eq "$2" ]; then
    if [ -z "$3" ]; then
      [ -z "$5" ] && ok=1
    else
      printf '%s' "$5" | grep -q "$3" && ok=1
    fi
  fi
  if [ "$ok" -eq 1 ]; then
    echo "PASS: $1"; PASS=$((PASS+1))
  else
    echo "FAIL: $1 (exit=$4 out=$5)"; FAIL=$((FAIL+1))
  fi
}

mkrepo() { # $1 = dir; live tracking v2 record
  mkdir -p "$1/.sunoku"
  cat > "$1/.sunoku/status.json" <<'EOF'
{
  "product": "T",
  "one_liner": "T.",
  "lifecycle": "live",
  "tracking": true,
  "created": "2026-07-01T00:00:00Z",
  "updated": "2026-07-01T00:00:00Z"
}
EOF
}

STDIN_MAIN='{"session_id":"s1","hook_event_name":"SessionStart","source":"startup"}'
STDIN_SUB='{"session_id":"s1","agent_id":"a1","hook_event_name":"SessionStart"}'

# session-start
D="$(mktemp -d)"
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" node "$SS")"; check "ss: no record silent" 0 "" $? "$OUT"

D="$(mktemp -d)"; mkrepo "$D"
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" node "$SS")"
check "ss: record injects gateway skill" 0 "using-sunoku" $? "$OUT"
check "ss: gateway wrapped importance tag" 0 "EXTREMELY_IMPORTANT" $? "$OUT"
check "ss: gateway routes tracking" 0 "sunoku:tracking-changes" $? "$OUT"
check "ss: gateway routes record queries" 0 "sunoku:querying-the-record" $? "$OUT"
check "ss: tracking-on state armed" 0 "never auto-track" $? "$OUT"

D="$(mktemp -d)"; mkrepo "$D"
sed -i.bak 's/"tracking": true/"tracking": false/' "$D/.sunoku/status.json"
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" node "$SS")"
check "ss: muted says muted" 0 "tracking muted" $? "$OUT"
check "ss: muted still injects gateway" 0 "using-sunoku" $? "$OUT"

D="$(mktemp -d)"; mkrepo "$D"
sed -i.bak 's/"lifecycle": "live"/"lifecycle": "defining"/' "$D/.sunoku/status.json"
OUT="$(printf '%s' "$STDIN_MAIN" | CLAUDE_PROJECT_DIR="$D" node "$SS")"
check "ss: pre-live record still injects gateway" 0 "lifecycle defining" $? "$OUT"

D="$(mktemp -d)"; mkrepo "$D"
OUT="$(printf '%s' "$STDIN_SUB" | CLAUDE_PROJECT_DIR="$D" node "$SS")"; check "ss: subagent silent" 0 "" $? "$OUT"

OUT="$(printf 'not json' | CLAUDE_PROJECT_DIR="$(mktemp -d)" node "$SS")"; check "ss: garbage stdin exit 0" 0 "" $? "$OUT"

# guard
deny() { printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$1" | node "$GW"; }
OUT="$(deny "/x/.sunoku/status.json")"; check "gw: status.json denied" 0 '"permissionDecision": "deny"' $? "$OUT"
OUT="$(deny "/x/.sunoku/status.json")"; check "gw: deny names status-write" 0 "status-write.mjs" $? "$OUT"
OUT="$(deny "/x/.sunoku/tasks.jsonl")"; check "gw: tasks.jsonl denied" 0 "tasks.mjs" $? "$OUT"
OUT="$(deny "/x/.sunoku/decisions.jsonl")"; check "gw: decisions.jsonl denied" 0 "decisions.mjs" $? "$OUT"
OUT="$(deny "/x/.sunoku/PRD.md")"; check "gw: PRD.md allowed" 0 "" $? "$OUT"
OUT="$(deny "/x/.sunoku/research/notes.md")"; check "gw: research allowed" 0 "" $? "$OUT"
OUT="$(deny "/x/src/app.ts")"; check "gw: source allowed" 0 "" $? "$OUT"
OUT="$(printf 'not json' | node "$GW")"; check "gw: garbage stdin exit 0" 0 "" $? "$OUT"

echo; echo "test-hooks: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
