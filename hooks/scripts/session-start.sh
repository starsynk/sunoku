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

CTX="Sunoku record active (.sunoku/). After any substantive change ask: would PRD.md or roadmap need edits to stay accurate? Yes/unsure -> run the sunoku:log triage. Bugfix/styling/refactor/perf/config/copy -> silent, do nothing."
case "$DRIFT" in
  ''|*[!0-9]*) : ;;
  0) : ;;
  *) CTX="$CTX Drift: $DRIFT commit(s) unreconciled -> sunoku:status." ;;
esac

# Version-skew nudge: record written by an older plugin -> point at the migration path.
# Read-only like everything else here; the actual migration happens in-session per canon.
PLUGIN_JSON="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)/.claude-plugin/plugin.json"
if [ -f "$PLUGIN_JSON" ]; then
  PLUGIN_VER="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PLUGIN_JSON" | head -n1)"
  RECORD_VER="$(sed -n 's/.*"sunokuVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$STATUS" | head -n1)"
  if [ -n "$PLUGIN_VER" ] && [ "$RECORD_VER" != "$PLUGIN_VER" ]; then
    OLDEST="$(printf '%s\n%s\n' "$RECORD_VER" "$PLUGIN_VER" | sort -V | head -n1)"
    if [ "$OLDEST" = "$PLUGIN_VER" ] && [ -n "$RECORD_VER" ]; then
      CTX="$CTX Record schema $RECORD_VER is newer than plugin $PLUGIN_VER -> update the Sunoku plugin."
    else
      CTX="$CTX Record schema ${RECORD_VER:-pre-1.1.0} older than plugin $PLUGIN_VER - migrates on next record touch; sunoku:status migrates now."
    fi
  fi
fi

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$CTX"
exit 0
