#!/usr/bin/env bash
# tests/test_coordination.sh - integration test for the bash helper functions.
#
# Runs every command end-to-end in a throwaway git repo, asserts on output,
# and exits non-zero on any failure. Safe to run repeatedly.

set -uo pipefail

HELPERS_PATH=${HELPERS_PATH:-$(dirname "$0")/../.claude/agent-coordination-helpers.sh}
HELPERS_PATH=$(cd "$(dirname "$HELPERS_PATH")" && pwd)/$(basename "$HELPERS_PATH")

if [ ! -f "$HELPERS_PATH" ]; then
    echo "❌ helpers not found at $HELPERS_PATH"
    exit 1
fi

PASS=0
FAIL=0
assert_contains() {
    local haystack=$1 needle=$2 label=$3
    if echo "$haystack" | grep -q -- "$needle"; then
        echo "  ✅ $label"
        PASS=$((PASS+1))
    else
        echo "  ❌ $label"
        echo "     expected to contain: $needle"
        echo "     got:"
        echo "$haystack" | sed 's/^/       /'
        FAIL=$((FAIL+1))
    fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cd "$WORK"
git init -q
git config user.email "t@t" >/dev/null
git config user.name  "t"   >/dev/null
git commit -q --allow-empty -m initial

# shellcheck disable=SC1090
source "$HELPERS_PATH" >/dev/null
export CLAUDE_AGENT_ID=claude-test

echo "▶ analyze"
out=$(claude-agents-analyze)
assert_contains "$out" "Type: generic" "analyze infers generic project"
assert_contains "$out" "Branch:"        "analyze prints branch"

echo "▶ task lifecycle"
claude-agents-task-add T001 "Wire auth" "2026-05-10T17:00:00Z" >/dev/null
out=$(claude-agents-tasks open)
assert_contains "$out" "T001"          "task-add inserts T001"
assert_contains "$out" "Wire auth"     "task description preserved"

claude-agents-assign T001 >/dev/null
out=$(claude-agents-tasks mine)
assert_contains "$out" "T001"          "assign sets current agent as assignee"

# duplicate add should fail
if claude-agents-task-add T001 "dup" 2>/dev/null; then
    echo "  ❌ duplicate task-add should fail"
    FAIL=$((FAIL+1))
else
    echo "  ✅ duplicate task-add rejected"
    PASS=$((PASS+1))
fi

claude-agents-task-done T001 >/dev/null
out=$(claude-agents-tasks done)
assert_contains "$out" "T001"          "task-done moves T001 to done"

echo "▶ messaging"
claude-agents-broadcast "hello team" >/dev/null
claude-agents-dm claude-test "ping" >/dev/null
out=$(claude-agents-inbox)
assert_contains "$out" "hello team"    "broadcast appears in inbox"
assert_contains "$out" "ping"          "dm to self appears in inbox"

echo "▶ status (after task done — should still show agent id)"
out=$(claude-agents-status)
assert_contains "$out" "claude-test"   "status shows agent id"
# tasks all done now → 'Open tasks:' section should be empty (no T001 listed)
if echo "$out" | grep -A2 "Open tasks:" | grep -q "T001"; then
    echo "  ❌ status should not list completed task as open"
    FAIL=$((FAIL+1))
else
    echo "  ✅ status correctly excludes done task from Open"
    PASS=$((PASS+1))
fi

echo "▶ search via git notes"
out=$(claude-agents-search BROADCAST)
assert_contains "$out" "hello team"    "search finds broadcast in notes"

echo "▶ session disambiguation"
out=$(env -i HOME="$HOME" PATH="$PATH" USER=alice HOSTNAME=lap1 bash -c "source '$HELPERS_PATH' >/dev/null; _claude_agent_id")
assert_contains "$out" "claude-alice-lap1" "default agent id uses USER+HOSTNAME"
out=$(env -i HOME="$HOME" PATH="$PATH" USER=alice HOSTNAME=lap1 CLAUDE_SESSION_ID=auth bash -c "source '$HELPERS_PATH' >/dev/null; _claude_agent_id")
assert_contains "$out" "claude-alice-lap1-auth" "CLAUDE_SESSION_ID is appended"
out=$(env -i HOME="$HOME" PATH="$PATH" USER=alice HOSTNAME=lap1 CLAUDE_AGENT_ID=override bash -c "source '$HELPERS_PATH' >/dev/null; _claude_agent_id")
assert_contains "$out" "override"           "explicit CLAUDE_AGENT_ID wins"

echo "▶ advisory locks"
mkdir -p .claude/coordination/locks
LOCK_PATH="$WORK/foo.txt"
HASH=$(printf %s "$LOCK_PATH" | sha1sum | awk '{print $1}')
LOCK_FILE=".claude/coordination/locks/$HASH.lock"

# simulate another agent holding a fresh lock
NOW=$(date +%s)
{ echo "agent=claude-other"; echo "path=$LOCK_PATH"; echo "ts=2026-05-07T08:00:00Z"; echo "ts_epoch=$NOW"; } > "$LOCK_FILE"

out=$(claude-agents-locks)
assert_contains "$out" "claude-other"  "locks lists foreign lock"
assert_contains "$out" "$LOCK_PATH"    "locks lists locked path"

# clearing 'mine' should NOT remove the foreign lock
claude-agents-locks-clear mine >/dev/null
[ -f "$LOCK_FILE" ] && { echo "  ✅ locks-clear mine keeps foreign lock"; PASS=$((PASS+1)); } || { echo "  ❌ locks-clear mine should not remove foreign lock"; FAIL=$((FAIL+1)); }

# stale clearing on a fresh lock should NOT remove
claude-agents-locks-clear stale >/dev/null
[ -f "$LOCK_FILE" ] && { echo "  ✅ locks-clear stale keeps fresh lock"; PASS=$((PASS+1)); } || { echo "  ❌ locks-clear stale should keep fresh lock"; FAIL=$((FAIL+1)); }

# mark as stale and clear
{ echo "agent=claude-other"; echo "path=$LOCK_PATH"; echo "ts=2026-05-07T07:00:00Z"; echo "ts_epoch=$((NOW-9999))"; } > "$LOCK_FILE"
claude-agents-locks-clear stale >/dev/null
[ ! -f "$LOCK_FILE" ] && { echo "  ✅ locks-clear stale removes stale lock"; PASS=$((PASS+1)); } || { echo "  ❌ locks-clear stale should remove stale lock"; FAIL=$((FAIL+1)); }

# 'all' wipes everything
{ echo "agent=claude-other"; echo "ts_epoch=$NOW"; } > "$LOCK_FILE"
claude-agents-locks-clear all >/dev/null
[ ! -f "$LOCK_FILE" ] && { echo "  ✅ locks-clear all removes everything"; PASS=$((PASS+1)); } || { echo "  ❌ locks-clear all should remove all locks"; FAIL=$((FAIL+1)); }

echo
echo "─────────────────────────────"
echo "PASSED: $PASS   FAILED: $FAIL"
[ "$FAIL" -eq 0 ]
