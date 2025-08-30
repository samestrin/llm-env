#!/usr/bin/env bash

# CI Simulation Setup Script for GitHub Automation Regressions Resolution
# Simulates ubuntu-latest environment for local testing

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== CI Simulation Environment Setup ===${NC}"
echo "Date: $(date)"
echo "Platform: $(uname -s)"
echo "Architecture: $(uname -m)"
echo ""

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Setting up CI simulation environment...${NC}"

# Simulate CI environment variables (clean environment)
export CI=true
export GITHUB_ACTIONS=true
export RUNNER_OS=Linux
export RUNNER_ARCH=X64

# Clear any existing API keys to simulate CI environment
unset LLM_OPENAI_API_KEY 2>/dev/null || true
unset LLM_PROVIDER 2>/dev/null || true
unset OPENAI_API_KEY 2>/dev/null || true
unset OPENAI_BASE_URL 2>/dev/null || true
unset OPENAI_MODEL 2>/dev/null || true

echo -e "${GREEN}✅ Environment variables configured${NC}"

# Verify tool availability and versions
echo -e "${YELLOW}Checking tool availability...${NC}"

if command -v bats >/dev/null 2>&1; then
    echo -e "${GREEN}✅ BATS: $(bats --version)${NC}"
else
    echo -e "${RED}❌ BATS: not available${NC}"
    exit 1
fi

if command -v shellcheck >/dev/null 2>&1; then
    echo -e "${GREEN}✅ ShellCheck: $(shellcheck --version | head -2 | tail -1)${NC}"
else
    echo -e "${RED}❌ ShellCheck: not available${NC}"
    exit 1
fi

if command -v bash >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Bash: $BASH_VERSION${NC}"
else
    echo -e "${RED}❌ Bash: not available${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Running CI simulation tests...${NC}"

# Function to run tests with CI simulation
run_ci_test() {
    local test_file="$1"
    local test_name="$2"
    
    echo -e "${YELLOW}Testing: $test_name${NC}"
    
    if [[ -f "$test_file" ]]; then
        if bats "$test_file"; then
            echo -e "${GREEN}✅ $test_name: PASSED${NC}"
            return 0
        else
            echo -e "${RED}❌ $test_name: FAILED${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ $test_name: Test file not found${NC}"
        return 1
    fi
    
    echo ""
}

# Test execution results
FAILED_TESTS=0
TOTAL_TESTS=0

# Test 1: Bash versions unit test
((TOTAL_TESTS++))
if ! run_ci_test "$TEST_DIR/tests/unit/test_bash_versions.bats" "Unit: Bash Versions"; then
    ((FAILED_TESTS++))
fi

# Test 2: Multi-version system test
((TOTAL_TESTS++))
if ! run_ci_test "$TEST_DIR/tests/system/test_multi_version.bats" "System: Multi-Version"; then
    ((FAILED_TESTS++))
fi

# Test 3: Regression system test
((TOTAL_TESTS++))
if ! run_ci_test "$TEST_DIR/tests/system/test_regression.bats" "System: Regression"; then
    ((FAILED_TESTS++))
fi

# Test 4: ShellCheck linting
((TOTAL_TESTS++))
echo -e "${YELLOW}Testing: ShellCheck Linting${NC}"
if shellcheck "$TEST_DIR/llm-env"; then
    echo -e "${GREEN}✅ ShellCheck Linting: PASSED${NC}"
else
    echo -e "${RED}❌ ShellCheck Linting: FAILED${NC}"
    ((FAILED_TESTS++))
fi

echo ""
echo -e "${YELLOW}=== CI Simulation Results Summary ===${NC}"
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $((TOTAL_TESTS - FAILED_TESTS))"
echo "Failed: $FAILED_TESTS"

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}🎉 CI Simulation: ALL TESTS PASSED${NC}"
    echo "Local environment matches expected CI behavior!"
    exit 0
else
    echo -e "${RED}💥 CI Simulation: $FAILED_TESTS TESTS FAILED${NC}"
    echo "Issues detected that need resolution before CI deployment."
    exit 1
fi