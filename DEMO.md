# Multi-Agent Coordination Demo

This file demonstrates the Claude multi-agent coordination system.

## Current Agent
Agent ID: ${CLAUDE_AGENT_ID:-claude-agent-demo}

## Example Workflow
1. Agent starts session → SESSION_START logged
2. Agent modifies files → FILE_MODIFY events logged
3. Agent commits → COMMIT_COMPLETE logged
4. Other agents can see activity via helper commands

## Test Commands
Run these to see coordination in action:
- `claude-agents-log` - Recent activity
- `claude-agents-active` - Who's working
- `claude-agents-stats` - Summary statistics