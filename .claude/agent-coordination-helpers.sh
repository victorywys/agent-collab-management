#!/bin/bash

# Claude Agent Coordination Helper Scripts
# These commands help you view and interact with multi-agent coordination

echo "🤖 Claude Multi-Agent Coordination Commands:"
echo
echo "📋 View Recent Agent Activity:"
echo "   claude-agents-log"
echo
echo "👥 Show Active Agents:"
echo "   claude-agents-active"
echo
echo "🌟 Show Agent Activity by Date:"
echo "   claude-agents-today"
echo "   claude-agents-yesterday"
echo
echo "🔍 Search Agent Events:"
echo "   claude-agents-search <keyword>"
echo
echo "📊 Agent Statistics:"
echo "   claude-agents-stats"
echo
echo "🧹 Clean Old Coordination Data:"
echo "   claude-agents-cleanup"
echo

# Function definitions
claude-agents-log() {
    echo "📜 Recent Agent Activity (Git Notes + Commits):"
    echo "═══════════════════════════════════════════════"

    # Show git notes first
    echo "🗒️  Git Notes (agent-coordination):"
    git notes --ref=agent-coordination show HEAD 2>/dev/null | tail -20 || echo "   No coordination notes yet"

    echo
    echo "💬 Recent Agent Event Commits:"
    git log --oneline -20 --grep="AGENT_EVENT:" --all --format="%C(yellow)%h%C(reset) %C(green)%ad%C(reset) %s" --date=relative || echo "   No agent event commits yet"
}

claude-agents-active() {
    echo "👥 Active Agents (last 24 hours):"
    echo "═══════════════════════════════════════════"

    # Get unique agents from last 24 hours
    {
        git log --since="24 hours ago" --grep="AGENT_EVENT:" --all --format="%s" 2>/dev/null | grep -o "agent: [^|]*" | sort | uniq
        git notes --ref=agent-coordination show HEAD 2>/dev/null | grep -E "$(date -d 'yesterday' '+%Y-%m-%d')|$(date '+%Y-%m-%d')" | grep -o "agent: [^|]*" | sort | uniq
    } | sort | uniq || echo "   No recent agent activity"
}

claude-agents-today() {
    echo "📅 Today's Agent Activity:"
    echo "════════════════════════════"
    TODAY=$(date '+%Y-%m-%d')

    {
        git log --since="today" --grep="AGENT_EVENT:" --all --format="%C(blue)%ad%C(reset) | %s" --date=format:"%H:%M"
        git notes --ref=agent-coordination show HEAD 2>/dev/null | grep "$TODAY" | sed "s/^/📝 /"
    } | sort -k1 2>/dev/null || echo "   No activity today"
}

claude-agents-yesterday() {
    echo "📅 Yesterday's Agent Activity:"
    echo "═════════════════════════════"
    YESTERDAY=$(date -d 'yesterday' '+%Y-%m-%d')

    {
        git log --since="yesterday" --until="today" --grep="AGENT_EVENT:" --all --format="%C(blue)%ad%C(reset) | %s" --date=format:"%H:%M"
        git notes --ref=agent-coordination show HEAD 2>/dev/null | grep "$YESTERDAY" | sed "s/^/📝 /"
    } | sort -k1 2>/dev/null || echo "   No activity yesterday"
}

claude-agents-search() {
    if [ -z "$1" ]; then
        echo "Usage: claude-agents-search <keyword>"
        echo "Example: claude-agents-search \"commit_complete\""
        return 1
    fi

    echo "🔍 Searching agent events for: '$1'"
    echo "════════════════════════════════════════"

    {
        git log --grep="AGENT_EVENT:" --all --format="%C(yellow)%h%C(reset) %C(green)%ad%C(reset) %s" --date=relative | grep -i "$1"
        git notes --ref=agent-coordination show HEAD 2>/dev/null | grep -i "$1" | sed "s/^/📝 /"
    } | head -20 || echo "   No matches found for '$1'"
}

claude-agents-stats() {
    echo "📊 Agent Coordination Statistics:"
    echo "════════════════════════════════"

    echo "📈 Event Types (last 50 events):"
    {
        git log -50 --grep="AGENT_EVENT:" --all --format="%s" 2>/dev/null | grep -o "AGENT_EVENT: [^|]*" | sed 's/AGENT_EVENT: //' | sort | uniq -c | sort -nr
        git notes --ref=agent-coordination show HEAD 2>/dev/null | tail -50 | grep -o ": [A-Z_]*" | sed 's/: //' | sort | uniq -c | sort -nr
    } | head -10

    echo
    echo "🤖 Most Active Agents:"
    {
        git log -50 --grep="AGENT_EVENT:" --all --format="%s" 2>/dev/null | grep -o "agent: [^|]*" | sed 's/agent: //' | sort | uniq -c | sort -nr
        git notes --ref=agent-coordination show HEAD 2>/dev/null | tail -50 | grep -o "agent: [^|]*" | sed 's/agent: //' | sort | uniq -c | sort -nr
    } | head -5
}

claude-agents-cleanup() {
    echo "🧹 Cleaning up old agent coordination data..."
    echo "═══════════════════════════════════════════"

    # Remove agent event commits older than 30 days
    echo "Removing agent event commits older than 30 days..."
    git log --since="30 days ago" --until="now" --grep="AGENT_EVENT:" --format="%H" --all | head -100 > /tmp/keep_commits.txt

    # Clean up git notes (keep last 1000 entries)
    echo "Trimming coordination notes to last 1000 entries..."
    git notes --ref=agent-coordination show HEAD 2>/dev/null | tail -1000 > /tmp/coordination_notes_clean.txt
    if [ -s /tmp/coordination_notes_clean.txt ]; then
        git notes --ref=agent-coordination remove HEAD 2>/dev/null || true
        cat /tmp/coordination_notes_clean.txt | git notes --ref=agent-coordination add HEAD
    fi

    echo "✅ Cleanup complete!"
    rm -f /tmp/keep_commits.txt /tmp/coordination_notes_clean.txt
}

# Make functions available in current shell
export -f claude-agents-log claude-agents-active claude-agents-today claude-agents-yesterday
export -f claude-agents-search claude-agents-stats claude-agents-cleanup