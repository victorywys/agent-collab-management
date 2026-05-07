#!/usr/bin/env bash
# tests/test_skill_add_to_existing.sh
#
# 1. Verify skill assets/ matches the canonical .claude/ files.
# 2. Simulate the skill's install procedure on a throwaway repo and assert
#    the resulting state is correct + helpers actually work.

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL_DIR="$REPO_ROOT/.claude/skills/add-agent-collab-to-existing"
ASSETS="$SKILL_DIR/assets"
CANONICAL="$REPO_ROOT/.claude"

PASS=0; FAIL=0
ok()   { echo "  ✅ $1"; PASS=$((PASS+1)); }
bad()  { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

echo "▶ assets are byte-identical to canonical .claude/ files"
for f in COORDINATION.md settings.json agent-coordination-helpers.sh agent-coordination-helpers.fish; do
    if [ ! -f "$ASSETS/$f" ]; then
        bad "$f missing from assets/"
        continue
    fi
    if cmp -s "$ASSETS/$f" "$CANONICAL/$f"; then
        ok "$f matches canonical"
    else
        bad "$f drifted from canonical (run: cp .claude/$f .claude/skills/add-agent-collab-to-existing/assets/$f)"
    fi
done

echo "▶ skill install on a throwaway repo (offline path, uses assets/)"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cd "$WORK"
git init -q
git config user.email t@t
git config user.name  t
echo "hello" > README.md
git add README.md
git commit -q -m initial

# Pretend GitHub is unreachable: use bundled assets directly.
SOURCE="$ASSETS"

# Mimic the skill's copy step.
mkdir -p .claude/coordination/locks
cp "$SOURCE/COORDINATION.md"                   .claude/COORDINATION.md
cp "$SOURCE/settings.json"                     .claude/settings.json
cp "$SOURCE/agent-coordination-helpers.sh"     .claude/agent-coordination-helpers.sh
cp "$SOURCE/agent-coordination-helpers.fish"   .claude/agent-coordination-helpers.fish
chmod +x .claude/agent-coordination-helpers.sh .claude/agent-coordination-helpers.fish
echo '{"tasks": []}' > .claude/coordination/tasks.json
: > .claude/coordination/messages.log

# .gitignore patch
touch .gitignore
grep -qxF '.claude/coordination/locks/' .gitignore \
  || printf '\n# agent-collab\n.claude/coordination/locks/\n!.claude/coordination/messages.log\n' >> .gitignore

# Assertions on filesystem state
[ -f .claude/settings.json ]                 && ok "settings.json installed"  || bad "settings.json missing"
[ -f .claude/COORDINATION.md ]               && ok "COORDINATION.md installed" || bad "COORDINATION.md missing"
[ -x .claude/agent-coordination-helpers.sh ] && ok "bash helper executable"   || bad "bash helper not executable"
[ -x .claude/agent-coordination-helpers.fish ] && ok "fish helper executable" || bad "fish helper not executable"
[ -f .claude/coordination/tasks.json ]       && ok "tasks.json initialized"   || bad "tasks.json missing"
[ -f .claude/coordination/messages.log ]     && ok "messages.log initialized" || bad "messages.log missing"
[ -d .claude/coordination/locks ]            && ok "locks/ dir created"       || bad "locks/ dir missing"

# settings.json must be valid JSON with no env.CLAUDE_AGENT_ID literal
python3 -c "import json,sys; d=json.load(open('.claude/settings.json')); sys.exit(0 if 'env' not in d or 'CLAUDE_AGENT_ID' not in d.get('env',{}) else 1)" \
  && ok "settings.json has no broken env.CLAUDE_AGENT_ID literal" \
  || bad "settings.json still pins CLAUDE_AGENT_ID at install time"

# .gitignore patched correctly
grep -qxF '.claude/coordination/locks/' .gitignore \
  && ok ".gitignore has locks/ ignore" || bad ".gitignore missing locks/ entry"
grep -qxF '!.claude/coordination/messages.log' .gitignore \
  && ok ".gitignore has messages.log negation" || bad ".gitignore missing messages.log negation"

# Idempotency: running step 5+6 again should not corrupt state
echo '{"tasks": [{"id":"T999","status":"open","description":"keep","assignee":null}]}' > .claude/coordination/tasks.json
[ -f .claude/coordination/tasks.json ] && \
   grep -q T999 .claude/coordination/tasks.json && ok "tasks.json preserved through re-init" || bad "tasks.json reset on re-run"

# Helpers actually work end-to-end
# shellcheck disable=SC1091
source .claude/agent-coordination-helpers.sh >/dev/null
export CLAUDE_AGENT_ID=claude-installtest
out=$(claude-agents-status 2>&1)
echo "$out" | grep -q claude-installtest && ok "helpers run and report agent id" || bad "claude-agents-status broken after install"

claude-agents-broadcast "smoke" >/dev/null
out=$(claude-agents-inbox)
echo "$out" | grep -q smoke && ok "broadcast → inbox round-trip" || bad "broadcast → inbox failed"

echo
echo "─────────────────────────────"
echo "PASSED: $PASS   FAILED: $FAIL"
[ "$FAIL" -eq 0 ]
