#!/usr/bin/env fish

# Claude Agent Coordination Helper Scripts for Fish Shell
# These commands help you view and interact with multi-agent coordination

echo "🤖 Claude Multi-Agent Coordination Commands (Fish Shell):"
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

# Function definitions for Fish shell
function claude-agents-log
    echo "📜 Recent Agent Activity (Git Notes + Commits):"
    echo "═══════════════════════════════════════════════"

    # Show git notes first
    echo "🗒️  Git Notes (agent-coordination):"
    if git notes --ref=agent-coordination show HEAD 2>/dev/null | tail -20
        # Notes found
    else
        echo "   No coordination notes yet"
    end

    echo
    echo "💬 Recent Agent Event Commits:"
    if git log --oneline -20 --grep="AGENT_EVENT:" --all --format="%C(yellow)%h%C(reset) %C(green)%ad%C(reset) %s" --date=relative 2>/dev/null
        # Commits found
    else
        echo "   No agent event commits yet"
    end
end

function claude-agents-active
    echo "👥 Active Agents (last 24 hours):"
    echo "═══════════════════════════════════════════"

    # Get unique agents from last 24 hours
    set temp_file (mktemp)

    # From git log
    git log --since="24 hours ago" --grep="AGENT_EVENT:" --all --format="%s" 2>/dev/null | grep -o "agent: [^|]*" | sort | uniq >> $temp_file

    # From git notes - Fish compatible date handling
    set yesterday (date -d yesterday '+%Y-%m-%d' 2>/dev/null; or date -v-1d '+%Y-%m-%d' 2>/dev/null; or echo (date '+%Y-%m-%d'))
    set today (date '+%Y-%m-%d')
    git notes --ref=agent-coordination show HEAD 2>/dev/null | grep -E "$yesterday|$today" | grep -o "agent: [^|]*" | sort | uniq >> $temp_file

    if test -s $temp_file
        sort $temp_file | uniq
    else
        echo "   No recent agent activity"
    end

    rm -f $temp_file
end

function claude-agents-today
    echo "📅 Today's Agent Activity:"
    echo "════════════════════════════"
    set today (date '+%Y-%m-%d')
    set temp_file (mktemp)

    # Get commits from today
    git log --since="today" --grep="AGENT_EVENT:" --all --format="%C(blue)%ad%C(reset) | %s" --date=format:"%H:%M" 2>/dev/null >> $temp_file

    # Get notes from today
    git notes --ref=agent-coordination show HEAD 2>/dev/null | grep "$today" | sed "s/^/📝 /" >> $temp_file

    if test -s $temp_file
        sort $temp_file
    else
        echo "   No activity today"
    end

    rm -f $temp_file
end

function claude-agents-yesterday
    echo "📅 Yesterday's Agent Activity:"
    echo "═════════════════════════════"
    set yesterday (date -d yesterday '+%Y-%m-%d' 2>/dev/null; or date -v-1d '+%Y-%m-%d' 2>/dev/null; or echo (date '+%Y-%m-%d'))
    set temp_file (mktemp)

    # Get commits from yesterday
    git log --since="yesterday" --until="today" --grep="AGENT_EVENT:" --all --format="%C(blue)%ad%C(reset) | %s" --date=format:"%H:%M" 2>/dev/null >> $temp_file

    # Get notes from yesterday
    git notes --ref=agent-coordination show HEAD 2>/dev/null | grep "$yesterday" | sed "s/^/📝 /" >> $temp_file

    if test -s $temp_file
        sort $temp_file
    else
        echo "   No activity yesterday"
    end

    rm -f $temp_file
end

function claude-agents-search
    if test (count $argv) -eq 0
        echo "Usage: claude-agents-search <keyword>"
        echo "Example: claude-agents-search \"commit_complete\""
        return 1
    end

    set keyword $argv[1]
    echo "🔍 Searching agent events for: '$keyword'"
    echo "════════════════════════════════════════"

    set temp_file (mktemp)

    # Search in git log
    git log --grep="AGENT_EVENT:" --all --format="%C(yellow)%h%C(reset) %C(green)%ad%C(reset) %s" --date=relative 2>/dev/null | grep -i "$keyword" >> $temp_file

    # Search in git notes
    git notes --ref=agent-coordination show HEAD 2>/dev/null | grep -i "$keyword" | sed "s/^/📝 /" >> $temp_file

    if test -s $temp_file
        head -20 $temp_file
    else
        echo "   No matches found for '$keyword'"
    end

    rm -f $temp_file
end

function claude-agents-stats
    echo "📊 Agent Coordination Statistics:"
    echo "════════════════════════════════"

    echo "📈 Event Types (last 50 events):"
    set temp_file (mktemp)

    # Get event types from commits
    git log -50 --grep="AGENT_EVENT:" --all --format="%s" 2>/dev/null | grep -o "AGENT_EVENT: [^|]*" | sed 's/AGENT_EVENT: //' | sort | uniq -c | sort -nr >> $temp_file

    # Get event types from notes
    git notes --ref=agent-coordination show HEAD 2>/dev/null | tail -50 | grep -o ": [A-Z_]*" | sed 's/: //' | sort | uniq -c | sort -nr >> $temp_file

    if test -s $temp_file
        head -10 $temp_file
    end

    echo
    echo "🤖 Most Active Agents:"
    set temp_file2 (mktemp)

    # Get agents from commits
    git log -50 --grep="AGENT_EVENT:" --all --format="%s" 2>/dev/null | grep -o "agent: [^|]*" | sed 's/agent: //' | sort | uniq -c | sort -nr >> $temp_file2

    # Get agents from notes
    git notes --ref=agent-coordination show HEAD 2>/dev/null | tail -50 | grep -o "agent: [^|]*" | sed 's/agent: //' | sort | uniq -c | sort -nr >> $temp_file2

    if test -s $temp_file2
        head -5 $temp_file2
    end

    rm -f $temp_file $temp_file2
end

function claude-agents-cleanup
    echo "🧹 Cleaning up old agent coordination data..."
    echo "═══════════════════════════════════════════"

    # Remove agent event commits older than 30 days
    echo "Removing agent event commits older than 30 days..."
    git log --since="30 days ago" --until="now" --grep="AGENT_EVENT:" --format="%H" --all | head -100 > /tmp/keep_commits.txt

    # Clean up git notes (keep last 1000 entries)
    echo "Trimming coordination notes to last 1000 entries..."
    set notes_file /tmp/coordination_notes_clean.txt
    git notes --ref=agent-coordination show HEAD 2>/dev/null | tail -1000 > $notes_file

    if test -s $notes_file
        git notes --ref=agent-coordination remove HEAD 2>/dev/null; or true
        cat $notes_file | git notes --ref=agent-coordination add HEAD
    end

    echo "✅ Cleanup complete!"
    rm -f /tmp/keep_commits.txt $notes_file
end

# Make functions available globally in Fish
funcsave claude-agents-log
funcsave claude-agents-active
funcsave claude-agents-today
funcsave claude-agents-yesterday
funcsave claude-agents-search
funcsave claude-agents-stats
funcsave claude-agents-cleanup