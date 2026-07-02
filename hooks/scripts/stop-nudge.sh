#!/usr/bin/env bash
# Sunoku one-shot Stop nudge: fires at most once per session, and only when
# code changed but the journal did not. Never blocks stopping (always exit 0).
set -u

INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in *'"agent_id"'*) exit 0 ;; esac

SESSION_ID="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
[ -n "$SESSION_ID" ] || exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
STATUS="$ROOT/.sunoku/status.json"
[ -f "$STATUS" ] || exit 0
grep -q '"tracking": true' "$STATUS" || exit 0
grep -q '"lifecycle": "live"' "$STATUS" || exit 0

SNAP="$ROOT/.sunoku/.cache/session-$SESSION_ID"
[ -f "$SNAP" ] || exit 0
MARKER="$ROOT/.sunoku/.cache/nudged-$SESSION_ID"
[ -f "$MARKER" ] && exit 0

git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || exit 0
HEAD_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)" || exit 0
DIRTY="$(git -C "$ROOT" status --porcelain 2>/dev/null | cksum | cut -d' ' -f1)"
CUR="$HEAD_SHA $DIRTY"
OLD="$(cat "$SNAP" 2>/dev/null || true)"
[ "$CUR" = "$OLD" ] && exit 0

JOURNAL="$ROOT/.sunoku/JOURNAL.md"
if [ -f "$JOURNAL" ] && [ "$JOURNAL" -nt "$SNAP" ]; then exit 0; fi

touch "$MARKER" 2>/dev/null || true
printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"Sunoku: code changed in this session but the journal did not. Run the sunoku:log triage on the work from this session now. SILENT is a valid outcome; if the PRD or roadmap would need edits to stay accurate, capture them."}}\n'
exit 0
