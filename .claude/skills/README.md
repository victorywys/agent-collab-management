# Agent Collab Skills

This directory contains Claude Code skills for the Agent Collab ecosystem.

## Available Skills

### 🏗️ Repository Management

#### `create-agent-collab-repo`
**Purpose:** Automatically creates new repositories with agent collaboration system pre-configured

**Usage:** Available as a Claude Code skill through `/skills` or by calling:
```
/create-agent-collab-repo project-name project-type github-user
```

**Features:**
- Initializes git repository with proper configuration
- Installs agent coordination system from management repo
- Creates professional project structure based on type
- Sets up GitHub repository and pushes initial commit
- Enables immediate multi-agent coordination

**Project Types:** `generic`, `node`, `python`, `go`, `docs`, `config`

**Example:**
```
/create-agent-collab-repo my-api-service node victorywys
```

#### `add-agent-collab-to-existing`
**Purpose:** Install the multi-agent coordination layer (settings.json hooks,
helpers, shared task/message state, advisory file locks) into an existing
repository. Idempotent — safe to re-run for upgrades.

**Usage:** Run from the target repo's root and invoke the skill:
```
/add-agent-collab-to-existing
```

The skill takes no parameters. It clones the latest canonical files from
github.com/victorywys/agent-collab-management; if offline, it falls back to
the bundled copies in `assets/` next to its `SKILL.md`.

**What it installs:**
- `.claude/settings.json` — hooks for sessions, git ops, file locks, notes sync
- `.claude/COORDINATION.md`
- `.claude/agent-coordination-helpers.{sh,fish}`
- `.claude/coordination/{tasks.json,messages.log,locks/,README.md}`
- `.gitignore` — appends `.claude/coordination/locks/` and a `messages.log` negation

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

### 🛡️ Quality Assurance

#### `agent-tester-guardian`
**Purpose:** Intelligent testing agent that monitors code changes, performs comprehensive testing, and manages selective merging

**Usage:** Available as a Claude Code skill through `/skills` or by calling:
```
/agent-tester-guardian [repo-path] [test-strictness] [auto-merge] [notification-level]
```

**Advanced Testing Capabilities:**
- 🔍 **Intelligent Code Monitoring** - Real-time commit detection and analysis
- 🧪 **Comprehensive Multi-Language Testing** - Node.js, Python, Go, Rust support
- 📊 **Repository Relevance Validation** - Ensures changes align with project goals
- 🤖 **AI-Powered Quality Assessment** - Intelligent scoring and feedback generation
- 🔄 **Selective Merge Management** - Automated approval/rejection with detailed reasoning
- 💬 **Inter-Agent Communication** - Broadcasts test results and feedback to team
- 📈 **Analytics & Reporting** - Detailed test reports and quality metrics

**Guardian Features:**
1. **Real-Time Monitoring**: Automatically detects new commits and queues them for testing
2. **Comprehensive Analysis**: Analyzes code changes, file types, and repository relevance
3. **Multi-Language Testing**: Supports testing for Node.js, Python, Go, and generic projects
4. **Intelligent Feedback**: Generates detailed feedback with actionable suggestions
5. **Quality Scoring**: Provides objective quality scores (0-100) for all changes
6. **Selective Merging**: Makes merge recommendations based on comprehensive analysis

**Example:**
```
/agent-tester-guardian . strict false verbose
```

**Guardian Commands After Activation:**
- `guardian-start` - Activate real-time monitoring
- `guardian-stop` - Deactivate guardian
- `guardian-status` - View current status and statistics
- `guardian-test [commit]` - Manually trigger testing
- `guardian-results [N]` - View recent test results

**Testing Pipeline:**
1. **Commit Detection** → Monitors git for new commits
2. **Change Analysis** → Analyzes modified files and impact
3. **Relevance Validation** → Ensures changes fit repository purpose
4. **Comprehensive Testing** → Runs language-specific test suites
5. **Quality Assessment** → Generates scores and feedback
6. **Merge Decision** → Recommends approve/conditional/reject
7. **Team Communication** → Broadcasts results to all agents

## Claude Code Skills Structure

Skills are organized as directories containing:

```
skillname/
├── spec.yaml      # Skill metadata and parameters
├── SKILL.md       # Instructions and prompt for Claude
└── tools.json     # Available tools for the skill
```

### spec.yaml
Defines the skill name, description, triggers, and parameters.

### SKILL.md
Contains the detailed instructions that Claude follows when executing the skill.

### tools.json
Lists the system tools (bash, git, etc.) that the skill can use.

## Installation

These skills are part of the agent-collab-management system. To use them:

1. **Global installation (recommended):**
   ```bash
   # Create global skills directory
   mkdir -p ~/.claude/skills

   # Link skills from this repository
   ln -sf /path/to/agent-collab-management/.claude/skills/create-agent-collab-repo ~/.claude/skills/
   ```

2. **Or run directly via Skill tool:**
   ```
   Use the Skill tool in Claude Code conversations
   ```

3. **Verify installation:**
   ```
   /skills
   ```
   Should show `create-agent-collab-repo` in the skills list.

## Creating New Skills

To add a new skill to the ecosystem:

1. **Create skill directory:** `mkdir skillname`
2. **Create spec.yaml:** Define metadata and parameters
3. **Create SKILL.md:** Write Claude instructions
4. **Create tools.json:** List required tools
5. **Follow naming convention:** `verb-noun-context` (e.g., `create-agent-collab-repo`)
6. **Include coordination system integration**
7. **Add error handling and clear instructions**
8. **Update this README**

### Skill Directory Template Structure

```
new-skill/
├── spec.yaml
├── SKILL.md
└── tools.json
```

**spec.yaml example:**
```yaml
name: new-skill
description: Brief description of what the skill does
triggers:
  - "relevant phrase"
  - "another trigger"
parameters:
  - name: param1
    description: Parameter description
    required: true
  - name: param2
    description: Optional parameter
    required: false
    default: default_value
```

**SKILL.md example:**
```markdown
# Skill Name

You are an agent specialized in [specific task].

## Task: [Clear Task Description]

When the user requests [specific action], follow these steps:

## Step 1: [First Step]
- Clear instructions
- Specific commands if needed

## Step 2: [Second Step]
- More instructions
- Error handling

## Rules
- NEVER do harmful things
- ALWAYS validate inputs
- KEEP output clear and concise
```

**tools.json example:**
```json
{
  "tools": [
    {"name": "bash", "command": "bash"},
    {"name": "git", "command": "git"}
  ]
}
```

## Integration with Claude Code

These skills are designed to work seamlessly with Claude Code agents. They automatically:

- Set up agent coordination systems
- Enable multi-agent collaboration
- Create professional project structures
- Handle git and GitHub operations
- Provide coordination commands

## Future Skills (Roadmap)

- ✅ ~~`add-agent-collab` - Add coordination to existing repositories~~ **COMPLETED**
- ✅ ~~`agent-tester-guardian` - Intelligent testing and quality assurance~~ **COMPLETED**
- `sync-agent-collab` - Synchronize coordination systems across repos
- `create-agent-collab-workspace` - Set up multi-repo workspaces
- `deploy-agent-collab` - Deploy projects with coordination intact
- `agent-performance-analyzer` - Analyze agent collaboration effectiveness
- `agent-conflict-resolver` - Advanced merge conflict resolution
- `agent-security-scanner` - Security-focused code analysis
- `agent-documentation-generator` - Automated documentation updates

## Contributing

When creating new skills:

1. Test with multiple scenarios
2. Include comprehensive error handling
3. Document all parameters and options
4. Follow the established patterns
5. Ensure coordination system integration
6. Write clear, actionable instructions in SKILL.md

## Testing Skills

1. **Install skill locally:**
   ```bash
   ln -sf /path/to/skill ~/.claude/skills/
   ```

2. **Test via Claude Code:**
   ```
   /skills
   /your-skill-name param1 param2
   ```

3. **Verify functionality:**
   - Check all parameters work
   - Verify error handling
   - Test edge cases

---

**Happy skill development! 🛠️**