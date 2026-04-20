# Agent Collab Skills

This directory contains skills and tools for the Agent Collab ecosystem.

## Available Skills

### 🏗️ Repository Management

#### `create-agent-collab-repo`
**Purpose:** Automatically creates new repositories with agent collaboration system pre-configured

**Usage:**
```bash
create-agent-collab-repo <project-name> [project-type] [--github-user USERNAME]
```

**Features:**
- Initializes git repository with proper configuration
- Installs agent coordination system from management repo
- Creates professional project structure based on type
- Sets up GitHub repository and pushes initial commit
- Enables immediate multi-agent coordination

**Project Types:** `generic`, `node`, `python`, `go`, `docs`, `config`

**Example:**
```bash
create-agent-collab-repo my-api-service node --github-user victorywys
```

## Installation

These skills are part of the agent-collab-management system. To use them:

1. **Clone the management repository:**
   ```bash
   git clone https://github.com/victorywys/agent-collab-management.git
   cd agent-collab-management
   ```

2. **Add skills to your PATH:**
   ```bash
   export PATH="$PATH:$(pwd)/.claude/skills"
   ```

3. **Or run directly:**
   ```bash
   ./.claude/skills/create-agent-collab-repo my-project
   ```

## Creating New Skills

To add a new skill to the ecosystem:

1. **Create skill documentation:** `skillname.md`
2. **Create executable script:** `skillname` (no extension)
3. **Follow naming convention:** `verb-noun-context` (e.g., `create-agent-collab-repo`)
4. **Include coordination system integration**
5. **Add error handling and help text**
6. **Update this README**

### Skill Template Structure

```bash
#!/bin/bash
# Skill Name
# Brief description

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_usage() {
    cat << EOF
Skill Usage Information
EOF
}

main() {
    # Skill implementation
    print_success "Skill completed!"
}

main "$@"
```

## Integration with Claude Code

These skills are designed to work with Claude Code agents. They automatically:

- Set up agent coordination systems
- Enable multi-agent collaboration
- Create professional project structures
- Handle git and GitHub operations
- Provide coordination commands

## Future Skills (Roadmap)

- `clone-agent-collab-repo` - Clone and set up existing repos with coordination
- `add-agent-collab` - Add coordination to existing repositories
- `sync-agent-collab` - Synchronize coordination systems across repos
- `create-agent-collab-workspace` - Set up multi-repo workspaces
- `deploy-agent-collab` - Deploy projects with coordination intact

## Contributing

When creating new skills:

1. Test with multiple project types
2. Include comprehensive error handling
3. Document all parameters and options
4. Follow the established patterns
5. Ensure coordination system integration

---

**Happy skill development! 🛠️**