#!/bin/bash

# Claude Agent Coordination Universal Shell Helper
# Automatically detects shell and loads appropriate helpers

# Detect the current shell
detect_shell() {
    local shell_name
    if [ -n "$FISH_VERSION" ]; then
        echo "fish"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    elif [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    else
        # Fallback: check process name
        shell_name=$(ps -p $$ -o comm= 2>/dev/null)
        case "$shell_name" in
            *fish*) echo "fish" ;;
            *zsh*) echo "zsh" ;;
            *bash*) echo "bash" ;;
            *) echo "bash" ;; # Default fallback
        esac
    fi
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect shell and source appropriate helper
CURRENT_SHELL=$(detect_shell)

case "$CURRENT_SHELL" in
    fish)
        echo "🐟 Loading Fish shell helpers..."
        if [ -f "$SCRIPT_DIR/agent-coordination-helpers.fish" ]; then
            echo "Source this file in Fish: source $SCRIPT_DIR/agent-coordination-helpers.fish"
        else
            echo "❌ Fish helpers not found at $SCRIPT_DIR/agent-coordination-helpers.fish"
        fi
        ;;
    bash|zsh)
        echo "🐚 Loading Bash/Zsh helpers..."
        if [ -f "$SCRIPT_DIR/agent-coordination-helpers.sh" ]; then
            source "$SCRIPT_DIR/agent-coordination-helpers.sh"
        else
            echo "❌ Bash helpers not found at $SCRIPT_DIR/agent-coordination-helpers.sh"
        fi
        ;;
    *)
        echo "⚠️  Unknown shell: $CURRENT_SHELL"
        echo "Falling back to Bash helpers..."
        if [ -f "$SCRIPT_DIR/agent-coordination-helpers.sh" ]; then
            source "$SCRIPT_DIR/agent-coordination-helpers.sh"
        fi
        ;;
esac