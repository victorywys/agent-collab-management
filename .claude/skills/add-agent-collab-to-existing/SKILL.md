# Advanced Agent Collaboration Setup Agent

You are an advanced collaboration setup agent that adds comprehensive multi-agent coordination to existing repositories with intelligent task management, monitoring, and inter-agent communication capabilities.

## Task: Add Agent Collaboration to Existing Repository

When the user requests to add agent collaboration to an existing project, execute this comprehensive workflow:

## Phase 1: Repository Analysis & Understanding

### Step 1: Validate Repository Context
```bash
# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "❌ Not a git repository. Initializing..."
    git init
    git branch -M main
fi

# Get repository information
REPO_NAME=$(basename "$(pwd)")
REPO_PATH=$(pwd)
REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "No remote")
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
```

### Step 2: Intelligent Repository Analysis
Analyze the repository to understand its purpose and structure:

```bash
# Count files by type
echo "📊 Analyzing repository structure..."

# Programming languages detection
JS_FILES=$(find . -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" 2>/dev/null | wc -l)
PY_FILES=$(find . -name "*.py" 2>/dev/null | wc -l)
GO_FILES=$(find . -name "*.go" 2>/dev/null | wc -l)
JAVA_FILES=$(find . -name "*.java" 2>/dev/null | wc -l)
MD_FILES=$(find . -name "*.md" 2>/dev/null | wc -l)

# Configuration files detection
CONFIG_FILES=$(find . -name "package.json" -o -name "requirements.txt" -o -name "go.mod" -o -name "Cargo.toml" -o -name "pom.xml" 2>/dev/null)

# Project type inference
if [ -f "package.json" ]; then
    PROJECT_TYPE="node"
    PACKAGE_JSON_CONTENT=$(cat package.json)
elif [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
    PROJECT_TYPE="python"
elif [ -f "go.mod" ]; then
    PROJECT_TYPE="go"
elif [ -f "Cargo.toml" ]; then
    PROJECT_TYPE="rust"
elif [ $MD_FILES -gt 10 ]; then
    PROJECT_TYPE="docs"
else
    PROJECT_TYPE="generic"
fi

echo "🔍 Repository Analysis:"
echo "  📁 Name: $REPO_NAME"
echo "  🏷️  Type: $PROJECT_TYPE"
echo "  📊 Files: JS($JS_FILES) PY($PY_FILES) GO($GO_FILES) MD($MD_FILES)"
```

### Step 3: Read Existing Documentation
```bash
# Analyze README and documentation to understand project purpose
if [ -f "README.md" ]; then
    README_CONTENT=$(head -50 README.md)
    echo "📖 Found README.md - analyzing project description..."
fi

# Look for other documentation
DOCS_DIRS=$(find . -type d -name "docs" -o -name "documentation" 2>/dev/null)
```

## Phase 2: Agent Collaboration System Installation

### Step 4: Download Latest Coordination System
```bash
echo "⬇️  Installing agent coordination system..."

# Create temporary directory for download
TEMP_DIR=$(mktemp -d)

# Try to download from management repo
if curl -s "https://api.github.com/repos/victorywys/agent-collab-management" > /dev/null; then
    echo "📡 Downloading latest coordination system..."
    cd $TEMP_DIR
    git clone --quiet https://github.com/victorywys/agent-collab-management.git temp-collab
    cd - > /dev/null

    # Copy coordination files
    if [ -d "$TEMP_DIR/temp-collab/.claude" ]; then
        cp -r "$TEMP_DIR/temp-collab/.claude" ./
        echo "✅ Coordination system installed"
    else
        echo "⚠️  Fallback to manual setup"
        mkdir -p .claude
    fi
else
    echo "⚠️  Cannot download - creating manual setup"
    mkdir -p .claude
fi

# Cleanup
rm -rf $TEMP_DIR
```

### Step 5: Create Advanced Task Management System
```bash
echo "📋 Setting up advanced task management..."

# Create task management directories
mkdir -p .claude/tasks
mkdir -p .claude/agents
mkdir -p .claude/communication

# Initialize task database
cat > .claude/tasks/task-db.json << 'EOF'
{
  "tasks": [],
  "agents": {},
  "project_info": {
    "name": "'$REPO_NAME'",
    "type": "'$PROJECT_TYPE'",
    "analyzed_at": "'$(date -Iseconds)'",
    "description": "Auto-analyzed repository"
  },
  "communication_log": []
}
EOF
```

## Phase 3: Enhanced Coordination Configuration

### Step 6: Create Advanced Settings Configuration
Create `.claude/settings.json` with enhanced coordination:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Write(.claude/*)",
      "Edit(.claude/*)",
      "Read",
      "Bash(jq:*)",
      "Bash(curl:*)"
    ]
  },
  "env": {
    "CLAUDE_AGENT_ID": "claude-${USER:-agent}-${HOSTNAME:-local}",
    "AGENT_COLLAB_PROJECT": "'$REPO_NAME'",
    "AGENT_COLLAB_TYPE": "'$PROJECT_TYPE'"
  },
  "hooks": {
    "SessionStart": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "source .claude/agent-helpers.sh && agent_session_start",
        "statusMessage": "Initializing agent coordination"
      }]
    }],
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "source .claude/agent-helpers.sh && agent_session_stop",
        "statusMessage": "Finalizing agent session"
      }]
    }],
    "TaskCreated": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "source .claude/agent-helpers.sh && agent_task_created '$ARGUMENTS'",
        "statusMessage": "Registering new task"
      }]
    }],
    "TaskCompleted": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "source .claude/agent-helpers.sh && agent_task_completed '$ARGUMENTS'",
        "statusMessage": "Marking task complete"
      }]
    }],
    "PreToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "source .claude/agent-helpers.sh && agent_file_lock '$ARGUMENTS'",
        "statusMessage": "Coordinating file access"
      }]
    }],
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "source .claude/agent-helpers.sh && agent_file_unlock '$ARGUMENTS'",
        "statusMessage": "Releasing file coordination"
      }]
    }]
  }
}
```

### Step 7: Create Advanced Agent Helper Functions
Create `.claude/agent-helpers.sh` with comprehensive functionality:

```bash
#!/bin/bash

# Advanced Agent Collaboration Helpers
# Provides task management, monitoring, and inter-agent communication

# Configuration
AGENT_ID="${CLAUDE_AGENT_ID:-claude-$(whoami)-$(hostname)}"
TASK_DB=".claude/tasks/task-db.json"
AGENT_DIR=".claude/agents"
COMM_DIR=".claude/communication"

# Ensure directories exist
mkdir -p "$(dirname "$TASK_DB")" "$AGENT_DIR" "$COMM_DIR"

# Initialize task database if it doesn't exist
init_task_db() {
    if [ ! -f "$TASK_DB" ]; then
        echo '{"tasks":[],"agents":{},"project_info":{},"communication_log":[]}' > "$TASK_DB"
    fi
}

# Session Management
agent_session_start() {
    init_task_db

    # Register agent
    local agent_info="{\"id\":\"$AGENT_ID\",\"status\":\"active\",\"last_seen\":\"$(date -Iseconds)\",\"current_tasks\":[]}"
    jq ".agents[\"$AGENT_ID\"] = $agent_info" "$TASK_DB" > "$TASK_DB.tmp" && mv "$TASK_DB.tmp" "$TASK_DB"

    # Create agent status file
    echo "$agent_info" > "$AGENT_DIR/$AGENT_ID.json"

    # Log session start
    git notes append --ref=agent-coordination -m "$(date -Iseconds): SESSION_START | agent: $AGENT_ID | project: ${AGENT_COLLAB_PROJECT:-unknown}" HEAD 2>/dev/null || true

    echo "🤖 Agent $AGENT_ID activated"

    # Show current status
    agent_status_brief
}

agent_session_stop() {
    # Update agent status
    local agent_info="{\"id\":\"$AGENT_ID\",\"status\":\"inactive\",\"last_seen\":\"$(date -Iseconds)\",\"session_end\":\"$(date -Iseconds)\"}"
    jq ".agents[\"$AGENT_ID\"] = $agent_info" "$TASK_DB" > "$TASK_DB.tmp" && mv "$TASK_DB.tmp" "$TASK_DB"

    # Remove agent status file
    rm -f "$AGENT_DIR/$AGENT_ID.json"

    # Log session end
    git notes append --ref=agent-coordination -m "$(date -Iseconds): SESSION_STOP | agent: $AGENT_ID" HEAD 2>/dev/null || true

    echo "👋 Agent $AGENT_ID deactivated"
}

# Task Management Functions
agent_task_created() {
    local task_data="$1"
    local task_id=$(echo "$task_data" | jq -r '.taskId // "unknown"')
    local subject=$(echo "$task_data" | jq -r '.subject // "unknown"')

    # Add to task database
    local task_entry="{\"id\":\"$task_id\",\"subject\":\"$subject\",\"created_by\":\"$AGENT_ID\",\"created_at\":\"$(date -Iseconds)\",\"status\":\"created\",\"assigned_to\":null,\"deadline\":null}"
    jq ".tasks += [$task_entry]" "$TASK_DB" > "$TASK_DB.tmp" && mv "$TASK_DB.tmp" "$TASK_DB"

    # Log creation
    git notes append --ref=agent-coordination -m "$(date -Iseconds): TASK_CREATED | agent: $AGENT_ID | task: $task_id | subject: $subject" HEAD 2>/dev/null || true

    echo "📝 Task created: $subject ($task_id)"
}

agent_task_completed() {
    local task_data="$1"
    local task_id=$(echo "$task_data" | jq -r '.taskId // "unknown"')
    local subject=$(echo "$task_data" | jq -r '.subject // "unknown"')

    # Update task in database
    jq "(.tasks[] | select(.id == \"$task_id\")) |= {\"status\": \"completed\", \"completed_by\": \"$AGENT_ID\", \"completed_at\": \"$(date -Iseconds)\"}" "$TASK_DB" > "$TASK_DB.tmp" && mv "$TASK_DB.tmp" "$TASK_DB"

    # Log completion
    git notes append --ref=agent-coordination -m "$(date -Iseconds): TASK_COMPLETED | agent: $AGENT_ID | task: $task_id | subject: $subject" HEAD 2>/dev/null || true

    echo "✅ Task completed: $subject ($task_id)"
}

# File Coordination
agent_file_lock() {
    local file_data="$1"
    local file_path=$(echo "$file_data" | jq -r '.file_path // "unknown"')

    # Check if file is locked by another agent
    if [ -f ".claude/locks/$(basename "$file_path").lock" ]; then
        local lock_owner=$(cat ".claude/locks/$(basename "$file_path").lock")
        if [ "$lock_owner" != "$AGENT_ID" ]; then
            echo "⚠️  File $file_path is being modified by $lock_owner"
        fi
    fi

    # Create lock
    mkdir -p .claude/locks
    echo "$AGENT_ID" > ".claude/locks/$(basename "$file_path").lock"

    # Log file access
    git notes append --ref=agent-coordination -m "$(date -Iseconds): FILE_LOCK | agent: $AGENT_ID | file: $file_path" HEAD 2>/dev/null || true
}

agent_file_unlock() {
    local file_data="$1"
    local file_path=$(echo "$file_data" | jq -r '.file_path // "unknown"')

    # Remove lock
    rm -f ".claude/locks/$(basename "$file_path").lock" 2>/dev/null || true

    # Log file release
    git notes append --ref=agent-coordination -m "$(date -Iseconds): FILE_UNLOCK | agent: $AGENT_ID | file: $file_path" HEAD 2>/dev/null || true
}

# Communication Functions
agent_broadcast() {
    local message="$1"
    local timestamp=$(date -Iseconds)
    local msg_id=$(echo "$timestamp$AGENT_ID" | shasum | cut -d' ' -f1 | head -c 8)

    # Add to communication log
    local comm_entry="{\"id\":\"$msg_id\",\"from\":\"$AGENT_ID\",\"timestamp\":\"$timestamp\",\"type\":\"broadcast\",\"message\":\"$message\"}"
    jq ".communication_log += [$comm_entry]" "$TASK_DB" > "$TASK_DB.tmp" && mv "$TASK_DB.tmp" "$TASK_DB"

    # Create message file for real-time pickup
    echo "$comm_entry" > "$COMM_DIR/broadcast_$msg_id.json"

    echo "📢 Broadcast: $message"
}

agent_direct_message() {
    local target_agent="$1"
    local message="$2"
    local timestamp=$(date -Iseconds)
    local msg_id=$(echo "$timestamp$AGENT_ID$target_agent" | shasum | cut -d' ' -f1 | head -c 8)

    # Add to communication log
    local comm_entry="{\"id\":\"$msg_id\",\"from\":\"$AGENT_ID\",\"to\":\"$target_agent\",\"timestamp\":\"$timestamp\",\"type\":\"direct\",\"message\":\"$message\"}"
    jq ".communication_log += [$comm_entry]" "$TASK_DB" > "$TASK_DB.tmp" && mv "$TASK_DB.tmp" "$TASK_DB"

    # Create message file
    echo "$comm_entry" > "$COMM_DIR/direct_${target_agent}_$msg_id.json"

    echo "📤 Message to $target_agent: $message"
}

# Monitoring Functions
agent_status_brief() {
    echo "🤖 Agent Collaboration Status:"
    echo "  📋 Active Tasks: $(jq '.tasks | map(select(.status != "completed")) | length' "$TASK_DB")"
    echo "  👥 Active Agents: $(jq '.agents | to_entries | map(select(.value.status == "active")) | length' "$TASK_DB")"
    echo "  📊 Project: ${AGENT_COLLAB_PROJECT:-Unknown} (${AGENT_COLLAB_TYPE:-unknown})"
}

agent_list_tasks() {
    echo "📋 Task List:"
    jq -r '.tasks[] | "  \(.status | if . == "completed" then "✅" elif . == "in_progress" then "🔄" else "⏳" end) \(.subject) (\(.id[0:8]))"' "$TASK_DB"
}

agent_list_agents() {
    echo "👥 Active Agents:"
    jq -r '.agents | to_entries[] | select(.value.status == "active") | "  🤖 \(.key) (last seen: \(.value.last_seen))"' "$TASK_DB"
}

agent_recent_messages() {
    local limit="${1:-5}"
    echo "💬 Recent Messages:"
    jq -r ".communication_log | sort_by(.timestamp) | reverse | limit($limit; .[]) | \"  📨 \(.from): \(.message) (\(.timestamp))\"" "$TASK_DB"
}

# Task Assignment with Deadlines
agent_assign_task() {
    local task_id="$1"
    local deadline="$2"

    # Update task assignment
    jq "(.tasks[] | select(.id == \"$task_id\")) |= {\"assigned_to\": \"$AGENT_ID\", \"status\": \"assigned\", \"deadline\": \"$deadline\", \"assigned_at\": \"$(date -Iseconds)\"}" "$TASK_DB" > "$TASK_DB.tmp" && mv "$TASK_DB.tmp" "$TASK_DB"

    # Broadcast assignment
    agent_broadcast "Taking on task: $task_id (deadline: $deadline)"

    echo "📌 Task $task_id assigned to $AGENT_ID (deadline: $deadline)"
}

# Export functions for use in hooks
export -f agent_session_start agent_session_stop agent_task_created agent_task_completed
export -f agent_file_lock agent_file_unlock agent_broadcast agent_direct_message
export -f agent_status_brief agent_list_tasks agent_list_agents agent_recent_messages agent_assign_task
```

## Phase 4: User Command Interface

### Step 8: Create User-Friendly Command Interface
Create `.claude/agent-coordination-helpers.sh` with user commands:

```bash
#!/bin/bash

# Load advanced agent functions
source .claude/agent-helpers.sh

# User-friendly command aliases
claude-agents-status() {
    agent_status_brief
    echo ""
    agent_list_agents
    echo ""
    agent_list_tasks
}

claude-agents-tasks() {
    agent_list_tasks
}

claude-agents-messages() {
    agent_recent_messages "${1:-10}"
}

claude-agents-assign() {
    local task_id="$1"
    local deadline="$2"

    if [ -z "$task_id" ]; then
        echo "Usage: claude-agents-assign <task-id> [deadline]"
        echo "Available tasks:"
        jq -r '.tasks[] | select(.status == "created" or .status == "pending") | "  \(.id[0:8]) - \(.subject)"' "$TASK_DB"
        return 1
    fi

    if [ -z "$deadline" ]; then
        deadline=$(date -d "+1 week" -Iseconds)
        echo "No deadline specified, using default: $deadline"
    fi

    agent_assign_task "$task_id" "$deadline"
}

claude-agents-broadcast() {
    local message="$1"
    if [ -z "$message" ]; then
        echo "Usage: claude-agents-broadcast \"<message>\""
        return 1
    fi
    agent_broadcast "$message"
}

claude-agents-dm() {
    local target="$1"
    local message="$2"
    if [ -z "$target" ] || [ -z "$message" ]; then
        echo "Usage: claude-agents-dm <agent-id> \"<message>\""
        echo "Available agents:"
        jq -r '.agents | to_entries[] | select(.value.status == "active") | "  \(.key)"' "$TASK_DB"
        return 1
    fi
    agent_direct_message "$target" "$message"
}

claude-agents-monitor() {
    echo "🔍 Monitoring agent activity (press Ctrl+C to stop)..."
    while true; do
        clear
        claude-agents-status
        echo ""
        agent_recent_messages 5
        sleep 5
    done
}

# Project analysis commands
claude-agents-analyze() {
    echo "🔍 Project Analysis:"
    if [ -f "$TASK_DB" ]; then
        jq -r '.project_info | "  📁 Name: \(.name)\n  🏷️  Type: \(.type)\n  📊 Analyzed: \(.analyzed_at)\n  📝 Description: \(.description)"' "$TASK_DB"
    fi
}

export -f claude-agents-status claude-agents-tasks claude-agents-messages claude-agents-assign
export -f claude-agents-broadcast claude-agents-dm claude-agents-monitor claude-agents-analyze
```

## Phase 5: Integration and Validation

### Step 9: Initial Commit and Activation
```bash
echo "🚀 Finalizing agent collaboration setup..."

# Add all new files
git add .claude/

# Create initial coordination commit
git commit -m "feat: add advanced agent collaboration system

- Multi-agent task management with deadlines
- Inter-agent communication system
- Intelligent repository analysis
- Real-time activity monitoring
- File coordination and conflict prevention

Project: $REPO_NAME ($PROJECT_TYPE)
Analyzed: $(date -Iseconds)

Co-Authored-By: Agent Collaboration System <noreply@agent-collab.dev>"

echo "✅ Advanced agent collaboration system installed!"
```

### Step 10: Success Summary and Next Steps
Provide comprehensive setup summary:

```
🎉 Advanced Agent Collaboration Successfully Added!

📁 Repository: $REPO_NAME
🏷️  Type: $PROJECT_TYPE
🤖 Agent ID: $AGENT_ID

🔧 New Capabilities:
  ✅ Multi-agent task management with deadlines
  ✅ Real-time inter-agent communication
  ✅ Intelligent file coordination
  ✅ Activity monitoring and analytics
  ✅ Project understanding and analysis

💻 Available Commands:
  claude-agents-status      # Overview of agents and tasks
  claude-agents-tasks       # List all tasks
  claude-agents-assign      # Take ownership of tasks with deadlines
  claude-agents-messages    # View recent communications
  claude-agents-broadcast   # Send message to all agents
  claude-agents-dm         # Send direct message to specific agent
  claude-agents-monitor    # Real-time activity monitoring
  claude-agents-analyze    # Project analysis and info

🚀 Getting Started:
1. source .claude/agent-coordination-helpers.sh
2. claude-agents-status
3. claude-agents-broadcast "Agent $AGENT_ID ready for collaboration!"

📋 Task Management:
- Create tasks with TaskCreate tool
- Use claude-agents-assign to take ownership
- Set realistic deadlines for coordination
- Communicate progress via broadcast/dm

🤝 Inter-Agent Communication:
- Broadcast updates to all agents
- Send direct messages for specific coordination
- Monitor real-time activity with claude-agents-monitor
- View project analysis with claude-agents-analyze

The repository is now ready for sophisticated multi-agent collaboration! 🚀
```

## Rules and Best Practices

### Critical Rules:
- **NEVER** overwrite existing files without explicit backup
- **ALWAYS** validate git repository state before modifications
- **BACKUP** existing .claude directory if present
- **PRESERVE** existing git history and configuration
- **VALIDATE** all JSON structures before writing
- **TEST** all shell functions before deployment

### Error Handling:
- Handle missing dependencies gracefully (jq, curl, etc.)
- Provide clear error messages with resolution steps
- Fall back to manual setup if automatic download fails
- Validate file permissions and directory access
- Handle network connectivity issues for downloads

### Edge Cases:
- Repository without git initialized
- Existing .claude directory with different structure
- No internet connection for downloading coordination system
- Missing shell tools (jq, curl)
- Repository with complex existing hook systems
- Large repositories requiring performance optimization

This advanced skill transforms any repository into a sophisticated multi-agent collaboration environment with task management, communication, and intelligent coordination capabilities!