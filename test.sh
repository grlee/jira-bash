#!/bin/bash
#
# test.sh - Simple test script for jira-bash
# This script runs basic tests to verify the functionality of jira-bash
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JIRA_SCRIPT="$SCRIPT_DIR/jira.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Run a test and report results
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_status="${3:-0}"
    
    echo -e "${YELLOW}Running test:${NC} $test_name"
    echo "Command: $command"
    
    # Run the command in dry-run mode
    eval "$command --dry-run" > /dev/null
    local status=$?
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ $status -eq $expected_status ]; then
        echo -e "${GREEN}✓ Passed${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ Failed${NC} (Expected status: $expected_status, got: $status)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    echo
}

echo "===================================="
echo "  Running jira-bash tests"
echo "===================================="
echo

# Basic command tests
run_test "Help command" "$JIRA_SCRIPT --help"
run_test "Version display" "$JIRA_SCRIPT --version" 0

# List tickets test
run_test "List tickets" "$JIRA_SCRIPT list --limit 5"

# View ticket test (should fail without ticket ID)
run_test "View ticket without ID" "$JIRA_SCRIPT view" 1

# View ticket test with ID
run_test "View ticket with ID" "$JIRA_SCRIPT view TEST-123"

# Create ticket test (should fail without summary)
run_test "Create ticket without summary" "$JIRA_SCRIPT create" 1

# Create ticket test with summary
run_test "Create ticket with summary" "$JIRA_SCRIPT create --summary 'Test ticket'"

# Sprint commands
run_test "List sprints" "$JIRA_SCRIPT sprint list"
run_test "View sprint" "$JIRA_SCRIPT sprint view 1"
run_test "Create sprint" "$JIRA_SCRIPT sprint create 'Test Sprint' --goal 'Testing'"

# Epic commands
run_test "List epics" "$JIRA_SCRIPT epic list"
run_test "View epic" "$JIRA_SCRIPT epic view TEST-100"
run_test "Create epic" "$JIRA_SCRIPT epic create 'Test Epic'"

# Test configuration
run_test "Configuration command" "$JIRA_SCRIPT config" 0

# Print summary
echo "===================================="
echo "  Test Summary"
echo "===================================="
echo -e "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    exit 1
else
    echo -e "Tests failed: $TESTS_FAILED"
    echo -e "${GREEN}All tests passed!${NC}"
fi