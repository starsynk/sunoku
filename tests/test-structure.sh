#!/usr/bin/env bash
# Structure invariants for Sunoku 3.x. Pure grep/stat checks, no side effects.
set -u
cd "$(dirname "$0")/.."
FAIL=0
ok()   { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; FAIL=1; }
assert_file()    { [ -f "$1" ] && ok "exists: $1" || fail "missing: $1"; }
assert_nofile()  { [ -e "$1" ] && fail "should not exist: $1" || ok "absent: $1"; }
assert_contains(){ grep -qF -- "$2" "$1" 2>/dev/null && ok "$1 contains: $2" || fail "$1 missing: $2"; }
assert_absent()  { grep -qF -- "$2" "$1" 2>/dev/null && fail "$1 still contains: $2" || ok "$1 clean of: $2"; }

# Eight skills (gateway + seven processes), each self-contained
SKILLS="using-sunoku starting-a-product researching writing-the-prd planning-the-work tracking-changes checking-status querying-the-record"
for s in $SKILLS; do
  assert_file "skills/$s/SKILL.md"
done
for s in init research prd plan track status read log; do
  assert_nofile "skills/$s"
done
assert_nofile agents
assert_nofile reference
assert_nofile .sunoku

# Invocability flags
assert_contains skills/starting-a-product/SKILL.md "disable-model-invocation: true"
assert_contains skills/tracking-changes/SKILL.md "user-invocable: false"
assert_contains skills/querying-the-record/SKILL.md "user-invocable: false"

# SDO: every description carries triggers ("Use when"), model-only skills say so
for s in $SKILLS; do
  awk '/^description:/{print; exit}' "skills/$s/SKILL.md" | grep -q "Use when" \
    && ok "SDO 'Use when': $s" || fail "description lacks 'Use when': $s"
done
for s in tracking-changes querying-the-record; do
  assert_contains "skills/$s/SKILL.md" "Internal — model-invoked"
done

# Skill anatomy: overview + announce on every working skill (gateway and model-only
# detector/retrieval skills announce nothing — they are ambient)
for s in starting-a-product researching writing-the-prd planning-the-work checking-status; do
  assert_contains "skills/$s/SKILL.md" "## Overview"
  assert_contains "skills/$s/SKILL.md" "**Announce at start:**"
done

# Skill-owned scripts and references
assert_file skills/starting-a-product/scripts/scaffold.mjs
assert_file skills/starting-a-product/references/onboarding.md
assert_file skills/checking-status/scripts/report.mjs
assert_file skills/querying-the-record/scripts/query.mjs
assert_file skills/planning-the-work/references/methodology.md
assert_contains skills/planning-the-work/references/methodology.md "Description = self-contained task"
assert_contains skills/planning-the-work/SKILL.md "description"
assert_file skills/writing-the-prd/templates/PRD.md
for f in create existing reshape product-owner-prompt codebase-analyst-prompt; do
  assert_file "skills/writing-the-prd/references/$f.md"
done
for f in validate standalone researcher-prompt red-team-prompt; do
  assert_file "skills/researching/references/$f.md"
done

# Shared plumbing: exactly these four
for f in lib status-write tasks decisions; do assert_file "scripts/$f.mjs"; done
for f in digest doctor journal-append migrate questions-flush release-notes report scaffold sentinels tasks-set; do
  assert_nofile "scripts/$f.mjs"
done

# PRD template change-log columns are machine-read
assert_contains skills/writing-the-prd/templates/PRD.md "| date | change | why | trigger |"

# No skill references the dead v1 world
if grep -rqE "canon|JOURNAL\.md|QUESTIONS\.md|ROADMAP|journal-append|stop-nudge" skills/ scripts/ hooks/; then
  fail "v1 references leaked into v2 sources"
else
  ok "no v1 references in sources"
fi

# Fully skill-based: no custom agent types, no contract files, no pre-rename skill names
if grep -rqE "sunoku:(researcher|red-team|product-owner|codebase-analyst)|-contract\.md" skills/ scripts/ hooks/; then
  fail "dead agent-type or contract-file references in sources"
else
  ok "no agent-type or contract-file references"
fi
if grep -rqE "sunoku:(init|research|prd|plan|track|status|read)\b|skills/(init|research|prd|plan|track|status|read)/" skills/ scripts/ hooks/; then
  fail "pre-rename skill names leaked into sources"
else
  ok "no pre-rename skill names in sources"
fi

# Subagent dispatch stays generic
for f in skills/researching/references/researcher-prompt.md skills/researching/references/red-team-prompt.md \
         skills/writing-the-prd/references/product-owner-prompt.md skills/writing-the-prd/references/codebase-analyst-prompt.md; do
  grep -qF "general-purpose" "$f" && ok "generic dispatch: $f" || fail "no generic dispatch: $f"
done

# Description length cap
for f in skills/*/SKILL.md; do
  [ "$(awk -F'description: ' '/^description:/{print length($2); exit}' "$f")" -le 320 ] \
    && ok "desc <=320 chars: $f" || fail "desc too long: $f"
done

# Hooks: two, wired; session-start injects the gateway skill
assert_file hooks/scripts/session-start.mjs
assert_file hooks/scripts/guard-record-writes.mjs
assert_nofile hooks/scripts/stop-nudge.mjs
assert_contains hooks/hooks.json "SessionStart"
assert_contains hooks/hooks.json "PreToolUse"
assert_absent hooks/hooks.json "Stop"
assert_contains hooks/scripts/session-start.mjs "using-sunoku"
assert_contains hooks/scripts/session-start.mjs "EXTREMELY_IMPORTANT"
assert_contains hooks/scripts/guard-record-writes.mjs "tasks.mjs"
assert_contains hooks/scripts/guard-record-writes.mjs "decisions.mjs"

# Version aligned
assert_contains .claude-plugin/plugin.json '"version": "3.0.0"'
assert_contains CHANGELOG.md "## 3.0.0"

# CI still runs all three suites
for t in test-structure.sh test-scripts.sh test-hooks.sh; do
  assert_contains .github/workflows/test.yml "$t"
done

exit $FAIL
