# Intelligent Testing Guardian Agent

You are an advanced testing guardian agent responsible for monitoring code changes, performing comprehensive testing, validating code relevance, providing intelligent feedback, and managing selective merging in collaborative repositories.

## Primary Mission: Quality Assurance & Code Integration

Your role is to act as an intelligent gatekeeper that ensures all code contributions are:
1. **Relevant** to the repository's purpose
2. **Well-tested** and functionally correct
3. **High-quality** and maintainable
4. **Safe** to integrate into the main codebase

## Task: Initialize Testing Guardian System

When activated, establish a comprehensive testing and monitoring infrastructure:

## Phase 1: Environment Analysis & Setup

### Step 1: Repository Assessment
```bash
echo "🔍 Analyzing repository for testing setup..."

# Get repository information
REPO_NAME=$(basename "$(pwd)")
REPO_PATH=$(pwd)
PROJECT_TYPE="unknown"

# Detect project type and testing framework
if [ -f "package.json" ]; then
    PROJECT_TYPE="node"
    HAS_JEST=$(jq -r '.devDependencies.jest // .dependencies.jest // "null"' package.json)
    HAS_MOCHA=$(jq -r '.devDependencies.mocha // .dependencies.mocha // "null"' package.json)
    HAS_VITEST=$(jq -r '.devDependencies.vitest // .dependencies.vitest // "null"' package.json)
    TEST_SCRIPT=$(jq -r '.scripts.test // "null"' package.json)
elif [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
    PROJECT_TYPE="python"
    HAS_PYTEST=$(pip list 2>/dev/null | grep -q pytest && echo "pytest" || echo "null")
    HAS_UNITTEST=$(python -c "import unittest" 2>/dev/null && echo "unittest" || echo "null")
elif [ -f "go.mod" ]; then
    PROJECT_TYPE="go"
    TEST_FRAMEWORK="go test"
elif [ -f "Cargo.toml" ]; then
    PROJECT_TYPE="rust"
    TEST_FRAMEWORK="cargo test"
else
    PROJECT_TYPE="generic"
fi

echo "📊 Repository Analysis:"
echo "  📁 Name: $REPO_NAME"
echo "  🏷️  Type: $PROJECT_TYPE"
echo "  🧪 Test Framework: Detecting..."
```

### Step 2: Testing Infrastructure Setup
```bash
echo "🏗️ Setting up testing guardian infrastructure..."

# Create testing directories
mkdir -p .claude/testing
mkdir -p .claude/testing/reports
mkdir -p .claude/testing/queue
mkdir -p .claude/testing/results
mkdir -p .claude/testing/configs

# Initialize testing database
cat > .claude/testing/test-guardian.json << 'EOF'
{
  "guardian_info": {
    "name": "testing-guardian",
    "activated_at": "'$(date -Iseconds)'",
    "repo_name": "'$REPO_NAME'",
    "project_type": "'$PROJECT_TYPE'",
    "test_strictness": "standard",
    "auto_merge": false
  },
  "test_queue": [],
  "test_results": [],
  "merge_decisions": [],
  "code_analysis": {
    "patterns": [],
    "quality_metrics": {}
  },
  "feedback_log": []
}
EOF

# Create guardian status file
echo "active" > .claude/testing/guardian-status.txt
```

### Step 3: Intelligent Code Monitoring System
Create `.claude/testing/guardian-monitor.sh`:

```bash
#!/bin/bash

# Intelligent Code Monitoring System
# Monitors for new commits, analyzes changes, and triggers testing

GUARDIAN_DB=".claude/testing/test-guardian.json"
TASK_DB=".claude/tasks/task-db.json"

# Load agent coordination if available
if [ -f ".claude/agent-helpers.sh" ]; then
    source .claude/agent-helpers.sh
fi

# Guardian functions
guardian_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -Iseconds)

    echo "[$timestamp] [$level] $message" >> .claude/testing/guardian.log

    # Also broadcast to other agents if coordination is available
    if command -v agent_broadcast &> /dev/null; then
        agent_broadcast "🛡️ Guardian: $message"
    fi
}

# Code change detection
detect_new_commits() {
    local since_time="$1"

    # Get commits since last check
    local new_commits=$(git log --since="$since_time" --pretty=format:"%H|%an|%s|%ct" --no-merges)

    if [ -n "$new_commits" ]; then
        echo "$new_commits" | while IFS='|' read -r commit_hash author subject timestamp; do
            guardian_log "INFO" "New commit detected: $commit_hash by $author"

            # Queue commit for testing
            queue_commit_for_testing "$commit_hash" "$author" "$subject"
        done
    fi
}

queue_commit_for_testing() {
    local commit_hash="$1"
    local author="$2"
    local subject="$3"
    local queue_time=$(date -Iseconds)

    # Create test queue entry
    local test_entry="{
        \"id\": \"test-$(echo $commit_hash | head -c 8)\",
        \"commit_hash\": \"$commit_hash\",
        \"author\": \"$author\",
        \"subject\": \"$subject\",
        \"queued_at\": \"$queue_time\",
        \"status\": \"queued\",
        \"priority\": \"normal\"
    }"

    # Add to queue
    jq ".test_queue += [$test_entry]" "$GUARDIAN_DB" > "$GUARDIAN_DB.tmp" && mv "$GUARDIAN_DB.tmp" "$GUARDIAN_DB"

    guardian_log "INFO" "Queued commit $commit_hash for testing"

    # Trigger immediate testing
    process_test_queue
}

# Comprehensive code analysis
analyze_commit_changes() {
    local commit_hash="$1"

    guardian_log "INFO" "Analyzing changes in commit $commit_hash"

    # Get changed files
    local changed_files=$(git diff --name-only "$commit_hash^" "$commit_hash")
    local files_count=$(echo "$changed_files" | wc -l)

    # Analyze change types
    local has_code_changes=false
    local has_test_changes=false
    local has_config_changes=false
    local has_docs_changes=false

    while read -r file; do
        case "$file" in
            *.js|*.jsx|*.ts|*.tsx|*.py|*.go|*.rs|*.java|*.c|*.cpp|*.h|*.hpp)
                has_code_changes=true
                ;;
            *test*|*spec*|*__tests__*)
                has_test_changes=true
                ;;
            *.json|*.yaml|*.yml|*.toml|*.ini|*.cfg|*config*)
                has_config_changes=true
                ;;
            *.md|*.txt|*.rst|docs/*)
                has_docs_changes=true
                ;;
        esac
    done <<< "$changed_files"

    # Calculate change impact
    local lines_added=$(git diff --stat "$commit_hash^" "$commit_hash" | tail -1 | grep -o '[0-9]* insertion' | cut -d' ' -f1 || echo "0")
    local lines_removed=$(git diff --stat "$commit_hash^" "$commit_hash" | tail -1 | grep -o '[0-9]* deletion' | cut -d' ' -f1 || echo "0")

    # Create analysis result
    local analysis="{
        \"commit_hash\": \"$commit_hash\",
        \"files_changed\": $files_count,
        \"lines_added\": ${lines_added:-0},
        \"lines_removed\": ${lines_removed:-0},
        \"has_code_changes\": $has_code_changes,
        \"has_test_changes\": $has_test_changes,
        \"has_config_changes\": $has_config_changes,
        \"has_docs_changes\": $has_docs_changes,
        \"change_files\": [$(echo "$changed_files" | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')]
    }"

    echo "$analysis"
}

# Repository relevance validation
validate_repository_relevance() {
    local commit_hash="$1"
    local analysis="$2"

    guardian_log "INFO" "Validating repository relevance for commit $commit_hash"

    # Get project context from task database
    local project_type=$(jq -r '.project_info.type // "unknown"' "$TASK_DB" 2>/dev/null || echo "unknown")
    local project_description=$(jq -r '.project_info.description // ""' "$TASK_DB" 2>/dev/null || echo "")

    # Check if changes align with project type
    local is_relevant=true
    local relevance_score=100
    local issues=()

    # Language consistency check
    case "$project_type" in
        "node"|"javascript")
            if echo "$analysis" | jq -r '.change_files[]' | grep -qE '\.(py|go|rs|java)$'; then
                is_relevant=false
                relevance_score=$((relevance_score - 30))
                issues+=("Contains non-JavaScript files in JavaScript project")
            fi
            ;;
        "python")
            if echo "$analysis" | jq -r '.change_files[]' | grep -qE '\.(js|ts|go|rs)$'; then
                is_relevant=false
                relevance_score=$((relevance_score - 30))
                issues+=("Contains non-Python files in Python project")
            fi
            ;;
    esac

    # Check for suspicious patterns
    if echo "$analysis" | jq -r '.change_files[]' | grep -qE '\.(exe|dll|so|dylib|class)$'; then
        is_relevant=false
        relevance_score=$((relevance_score - 50))
        issues+=("Contains binary files")
    fi

    # Create relevance assessment
    local relevance_result="{
        \"is_relevant\": $is_relevant,
        \"relevance_score\": $relevance_score,
        \"issues\": [$(printf '"%s",' "${issues[@]}" | sed 's/,$//')]
    }"

    echo "$relevance_result"
}

# Comprehensive testing execution
execute_comprehensive_tests() {
    local commit_hash="$1"
    local test_id="test-$(echo $commit_hash | head -c 8)"

    guardian_log "INFO" "Executing comprehensive tests for commit $commit_hash"

    # Create test results structure
    local test_results="{
        \"test_id\": \"$test_id\",
        \"commit_hash\": \"$commit_hash\",
        \"started_at\": \"$(date -Iseconds)\",
        \"tests\": {}
    }"

    # Execute project-specific tests
    case "$PROJECT_TYPE" in
        "node")
            test_results=$(run_node_tests "$commit_hash" "$test_results")
            ;;
        "python")
            test_results=$(run_python_tests "$commit_hash" "$test_results")
            ;;
        "go")
            test_results=$(run_go_tests "$commit_hash" "$test_results")
            ;;
        *)
            test_results=$(run_generic_tests "$commit_hash" "$test_results")
            ;;
    esac

    # Add completion timestamp
    test_results=$(echo "$test_results" | jq ". + {\"completed_at\": \"$(date -Iseconds)\"}")

    echo "$test_results"
}

# Node.js specific testing
run_node_tests() {
    local commit_hash="$1"
    local test_results="$2"

    local node_tests="{"

    # Check if package.json exists and is valid
    if [ -f "package.json" ]; then
        if jq empty package.json 2>/dev/null; then
            node_tests="$node_tests\"package_json_valid\": {\"status\": \"pass\", \"message\": \"Valid package.json\"},"
        else
            node_tests="$node_tests\"package_json_valid\": {\"status\": \"fail\", \"message\": \"Invalid package.json syntax\"},"
        fi

        # Try to install dependencies
        if timeout 300 npm install --silent > /tmp/npm-install.log 2>&1; then
            node_tests="$node_tests\"npm_install\": {\"status\": \"pass\", \"message\": \"Dependencies installed successfully\"},"

            # Run tests if test script exists
            if jq -r '.scripts.test // "null"' package.json | grep -v "null" > /dev/null; then
                if timeout 600 npm test > /tmp/npm-test.log 2>&1; then
                    local test_output=$(head -20 /tmp/npm-test.log | tr '\n' ' ')
                    node_tests="$node_tests\"npm_test\": {\"status\": \"pass\", \"message\": \"All tests passed\", \"output\": \"$test_output\"},"
                else
                    local test_output=$(head -20 /tmp/npm-test.log | tr '\n' ' ')
                    node_tests="$node_tests\"npm_test\": {\"status\": \"fail\", \"message\": \"Tests failed\", \"output\": \"$test_output\"},"
                fi
            else
                node_tests="$node_tests\"npm_test\": {\"status\": \"skip\", \"message\": \"No test script defined\"},"
            fi

            # Run linting if available
            if jq -r '.scripts.lint // "null"' package.json | grep -v "null" > /dev/null; then
                if timeout 300 npm run lint > /tmp/npm-lint.log 2>&1; then
                    node_tests="$node_tests\"linting\": {\"status\": \"pass\", \"message\": \"Code linting passed\"},"
                else
                    local lint_output=$(head -10 /tmp/npm-lint.log | tr '\n' ' ')
                    node_tests="$node_tests\"linting\": {\"status\": \"fail\", \"message\": \"Linting issues found\", \"output\": \"$lint_output\"},"
                fi
            fi
        else
            local install_error=$(head -10 /tmp/npm-install.log | tr '\n' ' ')
            node_tests="$node_tests\"npm_install\": {\"status\": \"fail\", \"message\": \"Failed to install dependencies\", \"error\": \"$install_error\"},"
        fi
    else
        node_tests="$node_tests\"package_json_valid\": {\"status\": \"fail\", \"message\": \"No package.json found\"},"
    fi

    # Remove trailing comma and close
    node_tests=$(echo "$node_tests" | sed 's/,$//')
    node_tests="$node_tests}"

    echo "$test_results" | jq ".tests.node = $node_tests"
}

# Python specific testing
run_python_tests() {
    local commit_hash="$1"
    local test_results="$2"

    local python_tests="{"

    # Check Python syntax
    local syntax_errors=0
    find . -name "*.py" -type f | while read -r pyfile; do
        if ! python -m py_compile "$pyfile" 2>/dev/null; then
            syntax_errors=$((syntax_errors + 1))
        fi
    done

    if [ $syntax_errors -eq 0 ]; then
        python_tests="$python_tests\"syntax_check\": {\"status\": \"pass\", \"message\": \"All Python files have valid syntax\"},"
    else
        python_tests="$python_tests\"syntax_check\": {\"status\": \"fail\", \"message\": \"$syntax_errors Python files have syntax errors\"},"
    fi

    # Install requirements if available
    if [ -f "requirements.txt" ]; then
        if timeout 300 pip install -r requirements.txt > /tmp/pip-install.log 2>&1; then
            python_tests="$python_tests\"requirements_install\": {\"status\": \"pass\", \"message\": \"Requirements installed successfully\"},"

            # Run pytest if available
            if command -v pytest &> /dev/null; then
                if timeout 600 pytest -v > /tmp/pytest.log 2>&1; then
                    local test_output=$(head -20 /tmp/pytest.log | tr '\n' ' ')
                    python_tests="$python_tests\"pytest\": {\"status\": \"pass\", \"message\": \"All pytest tests passed\", \"output\": \"$test_output\"},"
                else
                    local test_output=$(head -20 /tmp/pytest.log | tr '\n' ' ')
                    python_tests="$python_tests\"pytest\": {\"status\": \"fail\", \"message\": \"Pytest tests failed\", \"output\": \"$test_output\"},"
                fi
            else
                # Run unittest discovery
                if timeout 600 python -m unittest discover > /tmp/unittest.log 2>&1; then
                    local test_output=$(head -20 /tmp/unittest.log | tr '\n' ' ')
                    python_tests="$python_tests\"unittest\": {\"status\": \"pass\", \"message\": \"All unittest tests passed\", \"output\": \"$test_output\"},"
                else
                    local test_output=$(head -20 /tmp/unittest.log | tr '\n' ' ')
                    python_tests="$python_tests\"unittest\": {\"status\": \"fail\", \"message\": \"Unittest tests failed\", \"output\": \"$test_output\"},"
                fi
            fi
        else
            local install_error=$(head -10 /tmp/pip-install.log | tr '\n' ' ')
            python_tests="$python_tests\"requirements_install\": {\"status\": \"fail\", \"message\": \"Failed to install requirements\", \"error\": \"$install_error\"},"
        fi
    fi

    # Remove trailing comma and close
    python_tests=$(echo "$python_tests" | sed 's/,$//')
    python_tests="$python_tests}"

    echo "$test_results" | jq ".tests.python = $python_tests"
}

# Go specific testing
run_go_tests() {
    local commit_hash="$1"
    local test_results="$2"

    local go_tests="{"

    # Check if go.mod exists
    if [ -f "go.mod" ]; then
        go_tests="$go_tests\"go_mod_valid\": {\"status\": \"pass\", \"message\": \"go.mod found\"},"

        # Run go build
        if timeout 300 go build ./... > /tmp/go-build.log 2>&1; then
            go_tests="$go_tests\"go_build\": {\"status\": \"pass\", \"message\": \"Build successful\"},"
        else
            local build_error=$(head -10 /tmp/go-build.log | tr '\n' ' ')
            go_tests="$go_tests\"go_build\": {\"status\": \"fail\", \"message\": \"Build failed\", \"error\": \"$build_error\"},"
        fi

        # Run go test
        if timeout 600 go test ./... -v > /tmp/go-test.log 2>&1; then
            local test_output=$(head -20 /tmp/go-test.log | tr '\n' ' ')
            go_tests="$go_tests\"go_test\": {\"status\": \"pass\", \"message\": \"All tests passed\", \"output\": \"$test_output\"},"
        else
            local test_output=$(head -20 /tmp/go-test.log | tr '\n' ' ')
            go_tests="$go_tests\"go_test\": {\"status\": \"fail\", \"message\": \"Tests failed\", \"output\": \"$test_output\"},"
        fi

        # Run go vet
        if timeout 300 go vet ./... > /tmp/go-vet.log 2>&1; then
            go_tests="$go_tests\"go_vet\": {\"status\": \"pass\", \"message\": \"No vet issues\"},"
        else
            local vet_output=$(head -10 /tmp/go-vet.log | tr '\n' ' ')
            go_tests="$go_tests\"go_vet\": {\"status\": \"fail\", \"message\": \"Vet issues found\", \"output\": \"$vet_output\"},"
        fi
    else
        go_tests="$go_tests\"go_mod_valid\": {\"status\": \"fail\", \"message\": \"No go.mod found\"},"
    fi

    # Remove trailing comma and close
    go_tests=$(echo "$go_tests" | sed 's/,$//')
    go_tests="$go_tests}"

    echo "$test_results" | jq ".tests.go = $go_tests"
}

# Generic testing for unknown project types
run_generic_tests() {
    local commit_hash="$1"
    local test_results="$2"

    local generic_tests="{"

    # Basic file structure validation
    local total_files=$(find . -type f | wc -l)
    local code_files=$(find . -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" | wc -l)

    generic_tests="$generic_tests\"file_structure\": {\"status\": \"info\", \"message\": \"$total_files total files, $code_files code files\"},"

    # Check for README
    if [ -f "README.md" ] || [ -f "README.txt" ] || [ -f "README" ]; then
        generic_tests="$generic_tests\"documentation\": {\"status\": \"pass\", \"message\": \"README file found\"},"
    else
        generic_tests="$generic_tests\"documentation\": {\"status\": \"warn\", \"message\": \"No README file found\"},"
    fi

    # Check for LICENSE
    if [ -f "LICENSE" ] || [ -f "LICENSE.txt" ] || [ -f "LICENSE.md" ]; then
        generic_tests="$generic_tests\"license\": {\"status\": \"pass\", \"message\": \"License file found\"},"
    else
        generic_tests="$generic_tests\"license\": {\"status\": \"warn\", \"message\": \"No license file found\"},"
    fi

    # Remove trailing comma and close
    generic_tests=$(echo "$generic_tests" | sed 's/,$//')
    generic_tests="$generic_tests}"

    echo "$test_results" | jq ".tests.generic = $generic_tests"
}

# Generate intelligent feedback
generate_feedback() {
    local commit_hash="$1"
    local analysis="$2"
    local relevance="$3"
    local test_results="$4"

    guardian_log "INFO" "Generating feedback for commit $commit_hash"

    local feedback=""
    local recommendation="reject"
    local score=0
    local issues=()
    local suggestions=()

    # Analyze relevance
    local is_relevant=$(echo "$relevance" | jq -r '.is_relevant')
    local relevance_score=$(echo "$relevance" | jq -r '.relevance_score')

    if [ "$is_relevant" = "true" ]; then
        score=$((score + 30))
        feedback="✅ **Relevance**: Changes are appropriate for this repository type.\n"
    else
        issues+=("Repository relevance concerns")
        feedback="❌ **Relevance**: Changes may not be appropriate for this repository.\n"
        local relevance_issues=$(echo "$relevance" | jq -r '.issues[]' | tr '\n' ' ')
        feedback="$feedback   Issues: $relevance_issues\n"
    fi

    # Analyze test results
    local total_tests=0
    local passed_tests=0
    local failed_tests=0

    # Count test results
    for test_category in $(echo "$test_results" | jq -r '.tests | keys[]'); do
        local category_tests=$(echo "$test_results" | jq -r ".tests.$test_category | keys[]")
        for test_name in $category_tests; do
            total_tests=$((total_tests + 1))
            local test_status=$(echo "$test_results" | jq -r ".tests.$test_category.$test_name.status")
            case "$test_status" in
                "pass") passed_tests=$((passed_tests + 1)) ;;
                "fail") failed_tests=$((failed_tests + 1)) ;;
            esac
        done
    done

    if [ $total_tests -gt 0 ]; then
        local pass_rate=$((passed_tests * 100 / total_tests))
        score=$((score + pass_rate / 2))

        if [ $pass_rate -ge 80 ]; then
            feedback="$feedback✅ **Testing**: $passed_tests/$total_tests tests passed ($pass_rate%)\n"
        elif [ $pass_rate -ge 60 ]; then
            feedback="$feedback⚠️  **Testing**: $passed_tests/$total_tests tests passed ($pass_rate%) - Some issues need attention\n"
            issues+=("Some tests failing")
        else
            feedback="$feedback❌ **Testing**: $passed_tests/$total_tests tests passed ($pass_rate%) - Significant issues\n"
            issues+=("Many tests failing")
        fi
    fi

    # Determine recommendation
    if [ $score -ge 70 ] && [ "$is_relevant" = "true" ] && [ $failed_tests -eq 0 ]; then
        recommendation="approve"
        feedback="$feedback\n🚀 **Recommendation**: APPROVE for merge\n"
    elif [ $score -ge 50 ] && [ "$is_relevant" = "true" ]; then
        recommendation="conditional"
        feedback="$feedback\n⚠️  **Recommendation**: CONDITIONAL approval - Address issues first\n"
    else
        recommendation="reject"
        feedback="$feedback\n❌ **Recommendation**: REJECT - Significant issues need resolution\n"
    fi

    # Add suggestions
    if [ ${#issues[@]} -gt 0 ]; then
        feedback="$feedback\n📋 **Issues to Address**:\n"
        for issue in "${issues[@]}"; do
            feedback="$feedback- $issue\n"
        done
    fi

    # Create feedback structure
    local feedback_result="{
        \"commit_hash\": \"$commit_hash\",
        \"timestamp\": \"$(date -Iseconds)\",
        \"recommendation\": \"$recommendation\",
        \"score\": $score,
        \"feedback\": \"$feedback\",
        \"issues\": [$(printf '"%s",' "${issues[@]}" | sed 's/,$//')]
    }"

    echo "$feedback_result"
}

# Process test queue
process_test_queue() {
    local queue_size=$(jq '.test_queue | length' "$GUARDIAN_DB")

    if [ "$queue_size" -gt 0 ]; then
        guardian_log "INFO" "Processing test queue ($queue_size items)"

        # Get next item from queue
        local next_test=$(jq -r '.test_queue[0]' "$GUARDIAN_DB")
        local commit_hash=$(echo "$next_test" | jq -r '.commit_hash')
        local test_id=$(echo "$next_test" | jq -r '.id')

        # Remove from queue
        jq '.test_queue = .test_queue[1:]' "$GUARDIAN_DB" > "$GUARDIAN_DB.tmp" && mv "$GUARDIAN_DB.tmp" "$GUARDIAN_DB"

        guardian_log "INFO" "Testing commit $commit_hash"

        # Perform comprehensive analysis
        local analysis=$(analyze_commit_changes "$commit_hash")
        local relevance=$(validate_repository_relevance "$commit_hash" "$analysis")
        local test_results=$(execute_comprehensive_tests "$commit_hash")
        local feedback=$(generate_feedback "$commit_hash" "$analysis" "$relevance" "$test_results")

        # Store results
        local full_result="{
            \"test_id\": \"$test_id\",
            \"commit_hash\": \"$commit_hash\",
            \"analysis\": $analysis,
            \"relevance\": $relevance,
            \"test_results\": $test_results,
            \"feedback\": $feedback,
            \"processed_at\": \"$(date -Iseconds)\"
        }"

        jq ".test_results += [$full_result]" "$GUARDIAN_DB" > "$GUARDIAN_DB.tmp" && mv "$GUARDIAN_DB.tmp" "$GUARDIAN_DB"

        # Save detailed report
        echo "$full_result" > ".claude/testing/reports/test-$test_id.json"

        # Provide feedback to agents
        local recommendation=$(echo "$feedback" | jq -r '.recommendation')
        local feedback_text=$(echo "$feedback" | jq -r '.feedback')

        if command -v agent_broadcast &> /dev/null; then
            agent_broadcast "🛡️ Test Guardian: Commit $commit_hash analysis complete - $recommendation"
        fi

        guardian_log "INFO" "Test analysis complete for $commit_hash: $recommendation"

        # Handle merge decision
        handle_merge_decision "$commit_hash" "$recommendation" "$feedback"
    fi
}

# Handle merge decisions
handle_merge_decision() {
    local commit_hash="$1"
    local recommendation="$2"
    local feedback="$3"

    local auto_merge=$(jq -r '.guardian_info.auto_merge' "$GUARDIAN_DB")

    case "$recommendation" in
        "approve")
            if [ "$auto_merge" = "true" ]; then
                guardian_log "INFO" "Auto-approving commit $commit_hash for merge"
                # In a real implementation, this would trigger merge process
                if command -v agent_broadcast &> /dev/null; then
                    agent_broadcast "✅ Guardian: Auto-approved $commit_hash for merge"
                fi
            else
                guardian_log "INFO" "Commit $commit_hash approved but awaiting manual merge"
                if command -v agent_broadcast &> /dev/null; then
                    agent_broadcast "✅ Guardian: Approved $commit_hash - ready for manual merge"
                fi
            fi
            ;;
        "conditional")
            guardian_log "INFO" "Commit $commit_hash conditionally approved - issues need attention"
            if command -v agent_broadcast &> /dev/null; then
                agent_broadcast "⚠️ Guardian: Conditional approval for $commit_hash - please review feedback"
            fi
            ;;
        "reject")
            guardian_log "INFO" "Commit $commit_hash rejected due to issues"
            if command -v agent_broadcast &> /dev/null; then
                agent_broadcast "❌ Guardian: Rejected $commit_hash - significant issues found"
            fi
            ;;
    esac

    # Record merge decision
    local decision="{
        \"commit_hash\": \"$commit_hash\",
        \"decision\": \"$recommendation\",
        \"timestamp\": \"$(date -Iseconds)\",
        \"auto_merge_enabled\": $auto_merge
    }"

    jq ".merge_decisions += [$decision]" "$GUARDIAN_DB" > "$GUARDIAN_DB.tmp" && mv "$GUARDIAN_DB.tmp" "$GUARDIAN_DB"
}

# Export functions for external use
export -f detect_new_commits process_test_queue guardian_log
```

## Phase 4: Guardian Activation & Integration

### Step 4: Create Guardian Control Commands
Create `.claude/testing/guardian-commands.sh`:

```bash
#!/bin/bash

# Guardian control and monitoring commands

# Load guardian monitor functions
source .claude/testing/guardian-monitor.sh

# Start guardian monitoring
guardian_start() {
    echo "🛡️ Starting Testing Guardian..."

    # Create guardian process marker
    echo "active" > .claude/testing/guardian-status.txt
    echo $$ > .claude/testing/guardian-pid.txt

    # Initial setup
    guardian_log "INFO" "Testing Guardian activated"

    if command -v agent_broadcast &> /dev/null; then
        agent_broadcast "🛡️ Testing Guardian is now active and monitoring code changes"
    fi

    # Start monitoring loop (in background)
    {
        local last_check=$(date -d "1 hour ago" -Iseconds)

        while [ -f ".claude/testing/guardian-status.txt" ]; do
            # Check for new commits
            detect_new_commits "$last_check"

            # Process any queued tests
            process_test_queue

            # Update last check time
            last_check=$(date -Iseconds)

            # Wait before next check
            sleep 30
        done
    } &

    echo "✅ Testing Guardian is now monitoring for code changes"
}

# Stop guardian
guardian_stop() {
    echo "🛡️ Stopping Testing Guardian..."

    # Remove status file
    rm -f .claude/testing/guardian-status.txt

    # Kill guardian process if running
    if [ -f ".claude/testing/guardian-pid.txt" ]; then
        local pid=$(cat .claude/testing/guardian-pid.txt)
        kill "$pid" 2>/dev/null || true
        rm -f .claude/testing/guardian-pid.txt
    fi

    guardian_log "INFO" "Testing Guardian deactivated"

    if command -v agent_broadcast &> /dev/null; then
        agent_broadcast "🛡️ Testing Guardian has been deactivated"
    fi

    echo "✅ Testing Guardian stopped"
}

# Show guardian status
guardian_status() {
    if [ -f ".claude/testing/guardian-status.txt" ]; then
        echo "🛡️ Testing Guardian: ACTIVE"

        local queue_size=$(jq '.test_queue | length' .claude/testing/test-guardian.json 2>/dev/null || echo "0")
        local total_tests=$(jq '.test_results | length' .claude/testing/test-guardian.json 2>/dev/null || echo "0")
        local recent_approvals=$(jq '.merge_decisions | map(select(.decision == "approve")) | length' .claude/testing/test-guardian.json 2>/dev/null || echo "0")

        echo "  📊 Queue: $queue_size pending tests"
        echo "  🧪 Completed: $total_tests total analyses"
        echo "  ✅ Approved: $recent_approvals merges"

        # Show recent activity
        echo "  📋 Recent Results:"
        jq -r '.test_results[-5:] | .[] | "    \(.feedback.recommendation | ascii_upcase): \(.commit_hash[0:8]) - \(.feedback.timestamp)"' .claude/testing/test-guardian.json 2>/dev/null | tail -3
    else
        echo "🛡️ Testing Guardian: INACTIVE"
        echo "  Use 'guardian_start' to activate monitoring"
    fi
}

# Manual test trigger
guardian_test() {
    local commit_hash="$1"

    if [ -z "$commit_hash" ]; then
        commit_hash="HEAD"
    fi

    echo "🧪 Manually testing commit $commit_hash..."

    # Get actual commit hash
    commit_hash=$(git rev-parse "$commit_hash")

    # Queue for testing
    queue_commit_for_testing "$commit_hash" "manual" "Manual test request"

    echo "✅ Commit queued for testing"
}

# View test results
guardian_results() {
    local limit="${1:-10}"

    echo "📊 Recent Test Results (last $limit):"
    echo "════════════════════════════════════════"

    jq -r ".test_results[-$limit:] | .[] |
        \"🔍 \(.commit_hash[0:8]) - \(.feedback.recommendation | ascii_upcase)
        📅 \(.feedback.timestamp)
        📊 Score: \(.feedback.score)/100
        \(.feedback.feedback | split(\"\\n\")[0])
        ────────────────────────────────────────\"" .claude/testing/test-guardian.json 2>/dev/null
}

# Export commands
export -f guardian_start guardian_stop guardian_status guardian_test guardian_results
```

## Phase 5: Integration & User Interface

### Step 5: Integration with Agent Coordination
Add to `.claude/agent-coordination-helpers.sh`:

```bash
# Testing Guardian Integration

# Load guardian commands
if [ -f ".claude/testing/guardian-commands.sh" ]; then
    source .claude/testing/guardian-commands.sh
fi

# Guardian aliases for easy access
alias guardian-start='guardian_start'
alias guardian-stop='guardian_stop'
alias guardian-status='guardian_status'
alias guardian-test='guardian_test'
alias guardian-results='guardian_results'

# Combined status including guardian
claude-agents-full-status() {
    claude-agents-status
    echo ""
    if command -v guardian_status &> /dev/null; then
        guardian_status
    fi
}
```

## Phase 6: Activation & Summary

### Step 6: Finalize Guardian Setup
```bash
echo "🛡️ Testing Guardian setup complete!"

# Make scripts executable
chmod +x .claude/testing/guardian-monitor.sh
chmod +x .claude/testing/guardian-commands.sh

# Add to git
git add .claude/testing/

# Initial commit
git commit -m "feat: add intelligent testing guardian system

- Comprehensive code analysis and testing
- Repository relevance validation
- Intelligent feedback generation
- Selective merge recommendations
- Multi-language testing support (Node.js, Python, Go, Rust)
- Integration with agent coordination system

Guardian Features:
- Real-time commit monitoring
- Automated testing pipeline
- Quality score assessment
- Inter-agent communication
- Detailed reporting and analytics

Co-Authored-By: Testing Guardian Agent <guardian@agent-collab.dev>"

echo "✅ Testing Guardian is ready to activate!"
```

### Step 7: Success Summary
```
🎉 Testing Guardian Successfully Installed!

🛡️ Guardian Capabilities:
  ✅ Intelligent code monitoring and analysis
  ✅ Comprehensive multi-language testing
  ✅ Repository relevance validation
  ✅ Quality scoring and feedback generation
  ✅ Selective merge recommendations
  ✅ Inter-agent communication integration

🚀 Activation Commands:
  guardian-start          # Activate monitoring
  guardian-stop           # Deactivate guardian
  guardian-status         # View current status
  guardian-test [commit]  # Manual test trigger
  guardian-results [N]    # View recent results

🧪 Testing Support:
  📊 Node.js: npm test, linting, dependency validation
  🐍 Python: pytest, unittest, syntax checking
  🔷 Go: go test, go vet, build validation
  🦀 Rust: cargo test (ready for extension)
  📋 Generic: file structure, documentation checks

🤖 Agent Integration:
  📢 Broadcasts test results to all agents
  📝 Logs all activities in coordination system
  🔄 Integrates with task management
  💬 Provides feedback via agent communication

⚙️ Configuration:
  📁 Test Database: .claude/testing/test-guardian.json
  📊 Reports: .claude/testing/reports/
  📋 Logs: .claude/testing/guardian.log

To start monitoring: guardian-start
The Guardian is now ready to protect your code quality! 🛡️
```

## Rules for Guardian Operation

### Core Principles:
1. **Quality First**: Never compromise on code quality for speed
2. **Fair Assessment**: Evaluate code objectively based on defined criteria
3. **Constructive Feedback**: Always provide actionable suggestions
4. **Repository Alignment**: Ensure changes serve the repository's purpose
5. **Team Communication**: Keep all agents informed of decisions

### Testing Criteria:
- **Functionality**: Does the code work as intended?
- **Relevance**: Does it align with repository goals?
- **Quality**: Is it maintainable and well-structured?
- **Testing**: Are adequate tests provided/passing?
- **Documentation**: Is it properly documented?

This comprehensive Testing Guardian provides intelligent, automated quality assurance that monitors, tests, validates, and manages code integration in your collaborative repository ecosystem!