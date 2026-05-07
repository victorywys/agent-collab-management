# add-agent-collab-to-existing

Install the multi-agent coordination layer (git-notes events, shared
`tasks.json` / `messages.log`, advisory file locks, helper commands) into an
existing project. Idempotent: safe to re-run for upgrades.

## What gets installed

Files written into the target repo:

- `.claude/settings.json` — hooks for session start/stop, git ops, file locks,
  notes auto-sync. Replaces or backs up an existing one.
- `.claude/COORDINATION.md` — system overview.
- `.claude/agent-coordination-helpers.sh` — bash/zsh helpers.
- `.claude/agent-coordination-helpers.fish` — fish helpers.
- `.claude/coordination/tasks.json` — shared task store (committed).
- `.claude/coordination/messages.log` — broadcast/DM log (committed).
- `.claude/coordination/README.md` — describes the directory.
- `.claude/coordination/locks/` — per-host advisory locks (gitignored).
- `.gitignore` — append entries for `.claude/coordination/locks/` and an
  override `!.claude/coordination/messages.log`.

## Source files

The canonical files live in this repo under `.claude/`. The skill ships
copies of them in `assets/` next to this SKILL.md so it works offline.

When invoking, prefer fetching the latest from GitHub
(`https://github.com/victorywys/agent-collab-management.git`) — the bundled
`assets/` are a fallback only.

## Procedure

Run from the **target repository's root** (the repo you want to add
collaboration to — not the management repo).

### 1. Validate prerequisites

```bash
command -v git  >/dev/null || { echo "❌ git required"; exit 1; }
command -v jq   >/dev/null || { echo "❌ jq required (apt/brew install jq)"; exit 1; }
command -v sha1sum >/dev/null || command -v shasum >/dev/null \
  || { echo "❌ sha1sum or shasum required"; exit 1; }

# Confirm we're at a repo root
if [ ! -d .git ]; then
    read -p "Not a git repo. Initialize one here? [y/N] " yn
    [ "$yn" = "y" ] || { echo "Aborted."; exit 1; }
    git init -q
    git branch -M main 2>/dev/null || true
fi

TARGET=$(git rev-parse --show-toplevel)
cd "$TARGET"
```

### 2. Resolve the source directory

Try GitHub first; fall back to the skill's bundled `assets/`.

```bash
SOURCE=""
TMP=$(mktemp -d)
if git clone --quiet --depth=1 \
     https://github.com/victorywys/agent-collab-management.git \
     "$TMP/mgmt" 2>/dev/null; then
    SOURCE="$TMP/mgmt/.claude"
    echo "📡 Using latest files from GitHub."
fi

if [ -z "$SOURCE" ]; then
    # Fall back to skill assets. The skill dir contains this SKILL.md.
    # Resolve by walking up from the SKILL.md path Claude was given.
    SKILL_DIR=$(dirname "$(realpath "$0" 2>/dev/null || echo $HOME/.claude/skills/add-agent-collab-to-existing/SKILL.md)")
    if [ -d "$SKILL_DIR/assets" ]; then
        SOURCE="$SKILL_DIR/assets"
        echo "📦 Offline — using bundled assets from $SOURCE."
    else
        echo "❌ Could not reach GitHub and no bundled assets found."
        echo "   Manually copy .claude/{settings.json,COORDINATION.md,agent-coordination-helpers.{sh,fish}} from"
        echo "   https://github.com/victorywys/agent-collab-management"
        exit 1
    fi
fi
```

If `realpath "$0"` doesn't resolve (e.g. running interactively), use the
absolute path of this SKILL.md as you read it — Claude knows where it loaded
the skill from.

### 3. Back up an existing `.claude/`

```bash
if [ -e .claude/settings.json ]; then
    BK=".claude/settings.json.bak.$(date +%s)"
    cp .claude/settings.json "$BK"
    echo "💾 Backed up existing settings.json to $BK"
    echo "   Review the diff afterwards: diff $BK .claude/settings.json"
fi
```

If the existing `.claude/settings.json` already has hooks the user cares
about, **stop and ask the user how to proceed**. Do not silently merge
hook arrays — JSON parsers accept duplicate keys but only one survives, which
silently drops hooks. Either:
- Overwrite (after backup), and tell the user to re-add their custom hooks
  from the backup, or
- Bail with instructions if the existing hooks look intentional.

### 4. Copy the canonical files

```bash
mkdir -p .claude
cp "$SOURCE/COORDINATION.md"                .claude/COORDINATION.md
cp "$SOURCE/settings.json"                  .claude/settings.json
cp "$SOURCE/agent-coordination-helpers.sh"  .claude/agent-coordination-helpers.sh
cp "$SOURCE/agent-coordination-helpers.fish" .claude/agent-coordination-helpers.fish
chmod +x .claude/agent-coordination-helpers.sh .claude/agent-coordination-helpers.fish
```

### 5. Initialize shared coordination state

Skip files that already exist (upgrade-safe).

```bash
mkdir -p .claude/coordination/locks
[ -f .claude/coordination/tasks.json ]    || echo '{"tasks": []}' > .claude/coordination/tasks.json
[ -f .claude/coordination/messages.log ]  || : > .claude/coordination/messages.log
[ -f .claude/coordination/README.md ]     || cat > .claude/coordination/README.md <<'EOF'
# coordination/

Shared multi-agent state. Committed to git so every agent sees the same truth.

- `tasks.json`     — task list (jq-edited by helpers)
- `messages.log`   — broadcasts and DMs (append-only)
- `locks/`         — per-host advisory file locks (gitignored)

Edit through the `claude-agents-*` helpers, not by hand.
EOF
```

### 6. Patch `.gitignore`

```bash
touch .gitignore
grep -qxF '.claude/coordination/locks/' .gitignore \
  || printf '\n# agent-collab\n.claude/coordination/locks/\n!.claude/coordination/messages.log\n' >> .gitignore
```

The `!.claude/coordination/messages.log` line negates a possibly-broad
`*.log` rule. If the user keeps an explicit `.gitignore` style without `*.log`,
this line is harmless.

### 7. Commit

```bash
git add .claude/ .gitignore
git status --short
git commit -m "feat: add multi-agent coordination layer

Sets up .claude/{settings.json,COORDINATION.md,agent-coordination-helpers.{sh,fish}}
and shared state under .claude/coordination/. Hooks log session/file/git
events, sync notes with origin, and emit advisory file locks.

Helpers (after sourcing): claude-agents-status / -log / -tasks /
-broadcast / -dm / -inbox / -locks.

See .claude/COORDINATION.md for details."
```

### 8. Tell the user what's next

Print:

```
✅ Installed. Next steps:

  bash/zsh:  source .claude/agent-coordination-helpers.sh
  fish:      source .claude/agent-coordination-helpers.fish

  Then:
    claude-agents-status            # see who's around + open tasks
    claude-agents-broadcast "hi"    # post a message
    claude-agents-task-add T001 "first task"
    claude-agents-locks             # inspect any advisory file locks

  To disambiguate two Claude sessions on the same host, set
  CLAUDE_SESSION_ID before launching:    CLAUDE_SESSION_ID=auth claude

  If you have a remote, the SessionStart hook will fetch
  refs/notes/agent-coordination from origin and merge it in. Stop hook
  pushes back. No action needed beyond `git push` access.
```

## Rules

- **Never** silently overwrite an existing `.claude/settings.json` with custom
  hooks — back up and warn first.
- **Never** edit the user's existing files outside `.claude/` or `.gitignore`.
- Use `git rev-parse --show-toplevel` to locate the repo root; do not assume
  cwd is the root.
- The `git notes` syntax is **`git notes --ref=X append -m "..." HEAD`** —
  `--ref` must precede the subcommand, and `append` ignores stdin. The
  canonical files use this form; do not "fix" them.
- The deny rules in `permissions.deny` (e.g. `Bash(git push --force*)`) are
  there for a reason. Don't strip them.
- Helpers are bash 3+ compatible (macOS default). Avoid bashisms newer than
  4.0 if you modify them.

## Edge cases to watch for

- **No remote**: notes auto-sync hooks no-op. Helpers and hooks still work
  locally.
- **Existing `.claude/coordination/`**: leave its data alone (upgrade path).
- **Worktrees**: `git rev-parse --show-toplevel` resolves to the worktree
  root, which is what we want — coordination state is per-worktree.
- **Submodules**: install at the top level only; don't recurse.
