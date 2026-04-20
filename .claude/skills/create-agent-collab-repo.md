# Create Agent Collab Repository Skill

**Skill Name:** `create-agent-collab-repo`
**Description:** Automatically creates a new repository with agent collaboration system pre-configured

## Purpose

This skill creates new repositories that are immediately ready for multi-agent collaboration. It sets up:
- Git repository with proper configuration
- Agent coordination system from agent-collab-management
- Project structure based on type (generic, programming, documentation, config)
- GitHub repository integration
- Professional README and project files

## Usage

```bash
create-agent-collab-repo [project-name] [project-type] [--github-user USERNAME]
```

### Parameters

- `project-name`: Name of the new repository (required)
- `project-type`: Type of project - `generic`, `node`, `python`, `go`, `docs`, `config` (default: generic)
- `--github-user`: GitHub username for repository creation (optional, uses git config if not provided)

### Examples

```bash
# Create a generic repository
create-agent-collab-repo my-new-project

# Create a Node.js project
create-agent-collab-repo api-service node --github-user victorywys

# Create a documentation project
create-agent-collab-repo project-docs docs

# Create a Python project
create-agent-collab-repo ml-toolkit python
```

## What It Does

1. **Repository Setup**
   - Creates new directory with project name
   - Initializes git repository
   - Sets up proper git user configuration
   - Creates main branch

2. **Agent Coordination Integration**
   - Downloads latest coordination system from agent-collab-management
   - Copies .claude configuration files
   - Sets up coordination helpers for all shells (Bash, Fish, Zsh)
   - Configures permissions and hooks

3. **Project Structure Creation**
   - Generates appropriate .gitignore based on project type
   - Creates professional README.md with project details
   - Sets up directory structure based on project type
   - Adds configuration files (package.json, requirements.txt, etc.)

4. **GitHub Integration**
   - Creates GitHub repository using GitHub CLI
   - Pushes initial commit with all setup
   - Sets up remote tracking

5. **Coordination Activation**
   - Makes initial commit to trigger coordination system
   - Sources coordination helpers
   - Displays available coordination commands

## Project Types Supported

### Generic (`generic`)
- Basic repository with coordination system
- Minimal structure suitable for any project type
- README and .gitignore only

### Node.js/JavaScript (`node`)
- package.json with basic npm configuration
- Node.js specific .gitignore
- src/ and tests/ directories
- README with npm scripts documentation

### Python (`python`)
- requirements.txt and setup.py templates
- Python specific .gitignore
- Standard Python project structure (src/, tests/, docs/)
- README with pip installation instructions

### Go (`go`)
- go.mod initialization
- Standard Go project layout
- Go specific .gitignore
- README with go commands

### Documentation (`docs`)
- Markdown-focused structure
- docs/, assets/, examples/ directories
- Documentation-specific .gitignore
- README as documentation index

### Configuration (`config`)
- Dotfiles and configuration structure
- Install/setup scripts templates
- Configuration-specific .gitignore
- README with installation instructions

## Prerequisites

- Git installed and configured
- GitHub CLI (`gh`) installed and authenticated
- Internet connection for downloading coordination system
- Write permissions in target directory

## Output

The skill creates a complete repository structure like:

```
new-project/
├── .claude/                          # Agent coordination system
│   ├── settings.json
│   ├── agent-coordination-helpers.sh
│   ├── agent-coordination-helpers.fish
│   └── COORDINATION.md
├── .gitignore                        # Project-type appropriate
├── README.md                         # Professional documentation
├── [project-type specific files]    # package.json, requirements.txt, etc.
└── .git/                            # Initialized repository
```

## Success Indicators

- ✅ Git repository initialized with proper config
- ✅ Agent coordination system active and functional
- ✅ GitHub repository created and synced
- ✅ All coordination commands available
- ✅ Initial commit logged in coordination system
- ✅ Professional project structure in place

## Error Handling

- Validates project name format
- Checks for existing directories
- Verifies GitHub authentication
- Handles network errors gracefully
- Provides clear error messages and recovery steps

## Integration with Agent Collab System

Once created, the repository immediately supports:
- `claude-agents-log` - View recent activity
- `claude-agents-active` - See active agents
- `claude-agents-search` - Search coordination events
- Multi-agent file modification tracking
- Automatic git operation logging
- Cross-agent task coordination

## Examples of Generated Output

### Generic Project README
```markdown
# My New Project

A collaborative project managed with the Agent Collab coordination system.

## Agent Coordination

This project uses agent-collab for multi-agent coordination:

- `source .claude/agent-coordination-helpers.sh` (Bash/Zsh)
- `source .claude/agent-coordination-helpers.fish` (Fish)

### Available Commands
- `claude-agents-log` - Recent agent activity
- `claude-agents-active` - Currently active agents
- `claude-agents-stats` - Coordination statistics

## Getting Started

[Project-specific instructions based on type]

## Contributing

This project supports multi-agent collaboration. Check agent activity before making changes:
```bash
claude-agents-active
claude-agents-search "filename"
```
```

This skill transforms the agent collaboration system from a tool you add to existing projects into a **project creation system** that makes every new repository immediately collaborative.