#!/usr/bin/env bash
# Structure invariants for Sunoku 2.0. Pure grep/stat checks, no side effects.
set -u
cd "$(dirname "$0")/.."
FAIL=0
ok()   { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; FAIL=1; }
assert_file()    { [ -f "$1" ] && ok "exists: $1" || fail "missing: $1"; }
assert_nofile()  { [ -e "$1" ] && fail "should not exist: $1" || ok "absent: $1"; }
assert_contains(){ grep -qF -- "$2" "$1" 2>/dev/null && ok "$1 contains: $2" || fail "$1 missing: $2"; }
assert_absent()  { grep -qF -- "$2" "$1" 2>/dev/null && fail "$1 still contains: $2" || ok "$1 clean of: $2"; }

# Seven skills, each self-contained
for s in init research prd plan track status read; do
  assert_file "skills/$s/SKILL.md"
done
assert_nofile skills/log
assert_nofile reference
assert_nofile .sunoku

# Invocability flags
assert_contains skills/init/SKILL.md "disable-model-invocation: true"
assert_contains skills/track/SKILL.md "Internal — model-invoked"
assert_contains skills/read/SKILL.md "Internal — model-invoked"

# Skill-owned scripts and references
assert_file skills/init/scripts/scaffold.mjs
assert_file skills/init/references/onboarding.md
assert_file skills/status/scripts/report.mjs
assert_file skills/read/scripts/query.mjs
assert_file skills/plan/references/methodology.md
assert_file skills/prd/templates/PRD.md
for f in create existing reshape product-owner-contract codebase-analyst-contract; do
  assert_file "skills/prd/references/$f.md"
done
for f in validate standalone researcher-contract red-team-contract; do
  assert_file "skills/research/references/$f.md"
done

# Shared plumbing: exactly these four
for f in lib status-write tasks decisions; do assert_file "scripts/$f.mjs"; done
for f in digest doctor journal-append migrate questions-flush release-notes report scaffold sentinels tasks-set; do
  assert_nofile "scripts/$f.mjs"
done

# PRD template change-log columns are machine-read
assert_contains skills/prd/templates/PRD.md "| date | change | why | trigger |"

# No skill or agent references the dead v1 world
if grep -rqE "canon|JOURNAL\.md|QUESTIONS\.md|ROADMAP|journal-append|stop-nudge" skills/ agents/ scripts/ hooks/; then
  fail "v1 references leaked into v2 sources"
else
  ok "no v1 references in sources"
fi

# Agents: exactly four, valid model lines, short descriptions
[ "$(ls agents/*.md | wc -l | tr -d ' ')" = "4" ] && ok "exactly 4 agents" || fail "agent count != 4"
for f in agents/*.md; do
  grep -qE '^model: (sonnet|opus|haiku|fable|inherit)$' "$f" && ok "valid model: $f" || fail "invalid model: $f"
done
for f in skills/*/SKILL.md agents/*.md; do
  [ "$(awk -F'description: ' '/^description:/{print length($2); exit}' "$f")" -le 320 ] \
    && ok "desc <=320 chars: $f" || fail "desc too long: $f"
done

# Hooks: two, wired; stop-nudge gone
assert_file hooks/scripts/session-start.mjs
assert_file hooks/scripts/guard-record-writes.mjs
assert_nofile hooks/scripts/stop-nudge.mjs
assert_contains hooks/hooks.json "SessionStart"
assert_contains hooks/hooks.json "PreToolUse"
assert_absent hooks/hooks.json "Stop"
assert_contains hooks/scripts/guard-record-writes.mjs "tasks.mjs"
assert_contains hooks/scripts/guard-record-writes.mjs "decisions.mjs"

# Version aligned
assert_contains .claude-plugin/plugin.json '"version": "2.1.0"'
assert_contains CHANGELOG.md "## 2.1.0"

# CI still runs all three suites
for t in test-structure.sh test-scripts.sh test-hooks.sh; do
  assert_contains .github/workflows/test.yml "$t"
done

exit $FAIL
