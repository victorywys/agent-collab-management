# init-agent-collab

Initialize a directory or existing repository for multi-agent Claude Code
collaboration. Works on three starting states:

1. **Plain directory** — no `.git/`. Skill offers to `git init`.
2. **Empty git repo** — `.git/` exists, no commits yet.
3. **Existing repo with code** — skill analyzes the codebase, narrates back
   what it thinks the project is for, asks the user to confirm or correct,
   and stores the agreed-upon description in `.claude/coordination/PROJECT.md`
   so future agents inherit the context.

Idempotent. Safe to re-run for upgrades.

## What gets installed

In the target repo:

- `.claude/settings.json` — hooks for sessions, git ops, advisory file locks,
  notes auto-sync.
- `.claude/COORDINATION.md` — system overview.
- `.claude/agent-coordination-helpers.sh` — bash/zsh helpers.
- `.claude/agent-coordination-helpers.fish` — fish helpers.
- `.claude/coordination/tasks.json` — shared task store (committed).
- `.claude/coordination/messages.log` — broadcast/DM log (committed).
- `.claude/coordination/PROJECT.md` — **project context for future agents**.
- `.claude/coordination/README.md` — describes the directory.
- `.claude/coordination/locks/` — per-host advisory locks (gitignored).
- `.gitignore` — appends `.claude/coordination/locks/` and a
  `!.claude/coordination/messages.log` negation.

## Source files

The canonical files live in this repo at `.claude/`. The skill ships
copies of them in `assets/` next to this `SKILL.md` so it works offline.
When invoking, prefer fetching the latest from
`https://github.com/victorywys/agent-collab-management.git`; fall back to
`assets/` only if the clone fails.

## Procedure

Run from the **target repository's root** — the directory the user wants
to make collaborative, not the management repo.

### 1. Validate prerequisites

```bash
command -v git     >/dev/null || { echo "❌ git required"; exit 1; }
command -v jq      >/dev/null || { echo "❌ jq required (apt/brew install jq)"; exit 1; }
command -v sha1sum >/dev/null || command -v shasum >/dev/null \
  || { echo "❌ sha1sum or shasum required"; exit 1; }
```

### 2. Detect repo state and resolve target root

```bash
if [ -d .git ]; then
    TARGET=$(git rev-parse --show-toplevel)
    cd "$TARGET"
    if git rev-parse HEAD >/dev/null 2>&1; then
        STATE=existing       # repo with at least one commit
    else
        STATE=empty          # repo with no commits yet
    fi
else
    STATE=plain
    TARGET=$(pwd)
fi
echo "🔍 State: $STATE   Target: $TARGET"
```

If `STATE=plain`, ask the user whether to `git init` here. Use the
`AskUserQuestion` tool with two options ("init here" / "abort"). Do not
silently `git init` — the user might be in the wrong directory.

After init: `git init -q && git branch -M main 2>/dev/null` — but do not
commit yet, the install step will create the first commit.

### 3. Analyze the codebase (only when `STATE=existing`)

The goal is a one-paragraph mental model the user can confirm in seconds.
Prefer reading a few well-chosen files over scanning everything.

Inspect:

- `README.md` — first ~120 lines. Skip if missing.
- Top-level entries: `ls -1`. Note hidden files only if relevant
  (`.github/workflows/`, `Dockerfile`, etc.).
- Language fingerprints — exactly one of these is usually decisive:
  `package.json`, `pyproject.toml` / `requirements.txt`, `go.mod`,
  `Cargo.toml`, `pom.xml`, `Gemfile`, `composer.json`. Read the project
  name + description fields if present.
- `git log --oneline -10` — last commit messages give recent intent.
- If a `docs/` or `documentation/` directory exists, list its top-level
  contents (don't recurse).

**Do not** grep through source files or run `find` over the whole tree.
For projects under ~50 tracked files you may also `git ls-files | head -30`
to spot the rough shape. Larger repos: stop at the language fingerprints.

### 4. Synthesize and confirm understanding

After step 3, write **one short paragraph** in plain language:
- What the project is (1 sentence)
- Primary stack / language (1 short clause)
- 2–4 most important top-level components, in plain English

Then decide:

- **Confident** (signals are clear and consistent): present the paragraph
  and ask the user only "Anything to add or correct? (Enter to accept)"
  via `AskUserQuestion` with options `"Looks right"` and
  `"Let me correct it"`. If they pick correct, accept their free-text reply.
- **Unsure** (no README, no language config, ambiguous): present what you
  observed and explicitly ask the user for the project's purpose and the
  goal of inviting agents to collaborate. Use `AskUserQuestion`.

Either way, **never invent details you didn't observe**. If you can't tell,
say "I don't know" in the draft.

For `STATE=empty` and `STATE=plain`: skip the analysis. Ask the user:
"What is this project for, and what role should collaborating agents play?"
Use the answer as the body of `PROJECT.md`.

### 5. Resolve the install source

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
    # Skill ships byte-identical copies under its own assets/ dir.
    # Resolve relative to the SKILL.md you are reading right now.
    SKILL_DIR=$(dirname "$SKILL_MD_PATH")    # provided by the runtime; or
                                             # fall back to $HOME/.claude/skills/init-agent-collab
    if [ -d "$SKILL_DIR/assets" ]; then
        SOURCE="$SKILL_DIR/assets"
        echo "📦 Offline — using bundled assets."
    else
        echo "❌ Cannot reach GitHub and no bundled assets found."
        echo "   Manually copy .claude/{settings.json,COORDINATION.md,agent-coordination-helpers.{sh,fish}}"
        echo "   from https://github.com/victorywys/agent-collab-management"
        exit 1
    fi
fi
```

### 6. Back up an existing `.claude/settings.json`

```bash
if [ -e .claude/settings.json ]; then
    BK=".claude/settings.json.bak.$(date +%s)"
    cp .claude/settings.json "$BK"
    echo "💾 Backed up existing settings.json to $BK"
fi
```

If the existing `settings.json` already has hooks the user clearly cares
about, **stop and ask**. Do not silently merge — JSON parsers accept
duplicate keys but only one survives, which silently drops hooks. Either:
- overwrite (after backup) and tell the user where to find their old hooks,
  or
- bail and ask the user to migrate by hand.

### 7. Copy canonical files

```bash
mkdir -p .claude
cp "$SOURCE/COORDINATION.md"                  .claude/COORDINATION.md
cp "$SOURCE/settings.json"                    .claude/settings.json
cp "$SOURCE/agent-coordination-helpers.sh"    .claude/agent-coordination-helpers.sh
cp "$SOURCE/agent-coordination-helpers.fish"  .claude/agent-coordination-helpers.fish
chmod +x .claude/agent-coordination-helpers.sh .claude/agent-coordination-helpers.fish
```

### 8. Initialize shared coordination state (skip files that already exist)

```bash
mkdir -p .claude/coordination/locks
[ -f .claude/coordination/tasks.json ]    || echo '{"tasks": []}' > .claude/coordination/tasks.json
[ -f .claude/coordination/messages.log ]  || : > .claude/coordination/messages.log
[ -f .claude/coordination/README.md ]     || cat > .claude/coordination/README.md <<'EOF'
# coordination/

Shared multi-agent state. Committed to git so every agent sees the same truth.

- `tasks.json`     — task list (jq-edited by helpers)
- `messages.log`   — broadcasts and DMs (append-only)
- `PROJECT.md`     — project context for new agents
- `locks/`         — per-host advisory file locks (gitignored)

Edit through the `claude-agents-*` helpers, not by hand.
EOF
```

### 9. Write `PROJECT.md` from the confirmed understanding

```bash
cat > .claude/coordination/PROJECT.md <<'EOF'
# Project context

> Read this first when you join this repo as an agent. It captures what the
> project is for and how collaborating agents should think about it.

## Summary

<one paragraph from step 4 — the confirmed/edited understanding>

## Stack

<one short clause: primary language, framework, etc.>

## Key components

- <component / dir> — <one-line role>
- ...

## Notes for collaborating agents

<free-text section. If the user provided guidance in step 4 about what
agents should or shouldn't do, put it here. Otherwise leave a stub:
"None yet — add as conventions emerge.">
EOF
```

Write the actual content with the user's confirmed text — the heredoc
above is just a template skeleton.

### 10. Patch `.gitignore`

```bash
touch .gitignore
grep -qxF '.claude/coordination/locks/' .gitignore \
  || printf '\n# agent-collab\n.claude/coordination/locks/\n!.claude/coordination/messages.log\n' >> .gitignore
```

### 11. Initial commit

```bash
git add .claude/ .gitignore
git status --short
git commit -m "feat: initialize multi-agent coordination layer

Adds .claude/{settings.json,COORDINATION.md,agent-coordination-helpers.{sh,fish}}
and shared state under .claude/coordination/, including PROJECT.md with the
project context for future agents. Hooks log session/file/git events, sync
notes with origin, and emit advisory file locks.

Helpers (after sourcing): claude-agents-status / -log / -tasks /
-broadcast / -dm / -inbox / -locks.

See .claude/COORDINATION.md for details."
```

If `STATE=plain` or `STATE=empty`, this is the **first commit** in the new
repo. Ensure `git config user.email` / `user.name` are set first; if not,
ask the user.

### 12. Tell the user what's next

Print:

```
✅ Initialized. Next steps:

  bash/zsh:  source .claude/agent-coordination-helpers.sh
  fish:      source .claude/agent-coordination-helpers.fish

  Then:
    claude-agents-status            # see who's around + open tasks
    claude-agents-broadcast "hi"    # post a message
    claude-agents-task-add T001 "first task"
    claude-agents-locks             # inspect any advisory file locks

  Project context for future agents lives in
  .claude/coordination/PROJECT.md — keep it current as the project evolves.

  To disambiguate two Claude sessions on the same host:
    CLAUDE_SESSION_ID=auth claude

  If the repo has a remote, the SessionStart hook will fetch
  refs/notes/agent-coordination from origin and merge it in. Stop hook
  pushes back. No action needed beyond `git push` access.

  This repo is now ready for collaborators: anyone who clones it gets the
  full coordination layer automatically. They do not need to re-run this
  skill — they just source the helpers above.
```

## Rules

- **Never** silently overwrite `.claude/settings.json` with custom hooks.
  Back up and warn first, or bail.
- **Never** edit files outside `.claude/` and `.gitignore`.
- Use `git rev-parse --show-toplevel` to locate the repo root; do not
  assume cwd is the root.
- The `git notes` syntax is **`git notes --ref=X append -m "..." HEAD`** —
  `--ref` must precede the subcommand, and `append` ignores stdin.
  The canonical files use this form; do not "fix" them.
- The deny rules in `permissions.deny` (e.g. `Bash(git push --force*)`)
  exist for safety. Don't strip them.
- Helpers are bash 3+ compatible (macOS default). Avoid bashisms newer
  than 4.0 if you modify them.
- When inspecting an existing repo, **read at most ~5 files**. Don't
  walk the whole tree — language fingerprints + README are enough.

## Edge cases

- **No remote**: notes auto-sync hooks no-op cleanly. Helpers and hooks
  still work locally.
- **Existing `.claude/coordination/`**: leave its data alone. Re-running
  the skill is an upgrade, not a reset.
- **Empty repo (no commits)**: still works — the install commit becomes
  the first commit. Make sure `user.email` / `user.name` are set.
- **Worktrees**: `git rev-parse --show-toplevel` resolves to the worktree
  root, which is correct — coordination state is per-worktree.
- **Submodules**: install at the top level only; don't recurse.
- **Repo huge enough that the inspection is slow**: stop after the
  language fingerprints. Don't run `find` over the tree.
