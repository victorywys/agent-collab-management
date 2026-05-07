# Agent Coordination State

This directory holds **shared state** consumed by `claude-agents-*` helpers.

| File / dir | Purpose | Committed? |
|---|---|---|
| `tasks.json` | Authoritative task list (id, description, assignee, deadline, status) | ✅ yes — shared across agents |
| `messages.log` | Append-only chat log (broadcasts + DMs) | ✅ yes — durable audit trail |
| `locks/` | Per-machine advisory file locks (Tier 2 work) | ❌ no — runtime only |

Helpers update `tasks.json` and `messages.log` atomically (write-tmp + rename). To
sync state with teammates, just `git pull` / `git push` like any other tracked file.
