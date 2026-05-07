# Agent Collab Skills

Claude Code skills for the agent-collab-management ecosystem.

## Available Skills

### `init-agent-collab`

**Purpose:** Initialize a directory or existing repository for multi-agent
Claude Code collaboration. Handles three starting states:

1. **Plain directory** — no `.git/`. Skill offers to `git init`.
2. **Empty git repo** — `.git/` exists but no commits yet.
3. **Existing repo with code** — skill analyzes the codebase, narrates back
   what it thinks the project is for, asks the user to confirm or correct,
   and stores the agreed-upon description in `.claude/coordination/PROJECT.md`
   so future agents inherit the context.

Idempotent — safe to re-run for upgrades.

**Usage:** Run from the target repo's root and invoke:
```
/init-agent-collab
```

The skill takes no parameters. It clones the latest canonical files from
`github.com/victorywys/agent-collab-management`; if offline, it falls back
to the bundled copies in `assets/` next to its `SKILL.md`.

**What it installs:**

- `.claude/settings.json` — hooks for sessions, git ops, file locks, notes sync
- `.claude/COORDINATION.md` — system overview
- `.claude/agent-coordination-helpers.{sh,fish}` — helper commands
- `.claude/coordination/tasks.json` — shared task store
- `.claude/coordination/messages.log` — broadcast/DM log
- `.claude/coordination/PROJECT.md` — project context for future agents
- `.claude/coordination/locks/` — advisory file locks (gitignored)
- `.gitignore` — patches for locks/ and the messages.log negation

**After install, source the helpers:**
```bash
source .claude/agent-coordination-helpers.sh    # bash/zsh
# or
source .claude/agent-coordination-helpers.fish  # fish
```

**Available helpers:**

- `claude-agents-status` — overview of agents + open tasks
- `claude-agents-log` / `-active` / `-today` / `-yesterday` / `-search`
- `claude-agents-tasks` / `-task-add` / `-assign` / `-task-done`
- `claude-agents-broadcast` / `-dm` / `-inbox`
- `claude-agents-locks` / `-locks-clear`

**Important:** only the first installer runs this skill. Anyone who later
clones the repo gets the entire coordination layer for free — they just
need to `source` the helpers above.

### `agent-tester-guardian`

**Purpose:** Intelligent testing agent that monitors code changes, runs
language-specific tests, and produces quality scores + merge recommendations.

**Usage:**
```
/agent-tester-guardian [repo-path] [test-strictness] [auto-merge] [notification-level]
```

See `agent-tester-guardian/SKILL.md` for the full pipeline (commit detection,
multi-language testing, quality scoring, merge decisions).

## Skill Format

```
skillname/
├── spec.yaml      # name, description, triggers, parameters
├── SKILL.md       # instructions Claude follows when the skill is invoked
├── tools.json     # tools the skill is allowed to call
└── assets/        # optional bundled files (for offline fallback, etc.)
```

## Installation

Skills are picked up automatically when the directory exists under either
`~/.claude/skills/` or `<repo>/.claude/skills/`. To make them globally
available:

```bash
mkdir -p ~/.claude/skills
ln -sf "$PWD/.claude/skills/init-agent-collab"      ~/.claude/skills/
ln -sf "$PWD/.claude/skills/agent-tester-guardian"  ~/.claude/skills/
```

Verify with `/skills` inside a Claude Code session.

## Roadmap

- `sync-agent-collab` — propagate coordination upgrades across many repos
- `agent-performance-analyzer` — collaboration effectiveness reports
- `agent-conflict-resolver` — advanced merge conflict resolution
