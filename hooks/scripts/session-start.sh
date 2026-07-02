#!/usr/bin/env bash
# Sunoku ambient layer: inject standing triage rule + drift count at session start.
# Every guard exits 0 silently — this hook must never disturb a session.
set -u

INPUT="$(cat 2>/dev/null || true)"

# Guard: never run inside subagent sessions.
case "$INPUT" in *'"agent_id"'*) exit 0 ;; esac

SESSION_ID="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
[ -n "$SESSION_ID" ] || exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
STATUS="$ROOT/.sunoku/status.json"
[ -f "$STATUS" ] || exit 0
grep -q '"tracking": true' "$STATUS" || exit 0
grep -q '"lifecycle": "live"' "$STATUS" || exit 0
git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || exit 0

HEAD_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)" || exit 0
DIRTY="$(git -C "$ROOT" status --porcelain 2>/dev/null | cksum | cut -d' ' -f1)"

mkdir -p "$ROOT/.sunoku/.cache" 2>/dev/null || exit 0
printf '%s %s\n' "$HEAD_SHA" "$DIRTY" > "$ROOT/.sunoku/.cache/session-$SESSION_ID" 2>/dev/null || true

LAST_SHA="$(sed -n 's/.*"last_reconciled_sha"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$STATUS" | head -n1)"
DRIFT=0
if [ -n "$LAST_SHA" ] && [ "$LAST_SHA" != "$HEAD_SHA" ]; then
  DRIFT="$(git -C "$ROOT" rev-list --count "$LAST_SHA..$HEAD_SHA" 2>/dev/null || echo 0)"
fi

CTX="Sunoku living record is ACTIVE in this repo (.sunoku/). Standing rule: after completing any substantive change, apply the triage test - would .sunoku/PRD.md or the roadmap need editing to stay accurate? If yes or ambiguous, invoke the sunoku:log skill to capture it. Bugfixes, styling, refactors, perf, config and copy changes are SILENT: do nothing for those."
case "$DRIFT" in
  ''|*[!0-9]*) : ;;
  0) : ;;
  *) CTX="$CTX Drift: $DRIFT commit(s) landed since the last reconcile - suggest sunoku:status to review and reconcile." ;;
esac

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$CTX"
exit 0
