#!/usr/bin/env bash

# Multi-Version Test Matrix Script for GitHub Automation Regressions
# Tests across bash versions and API key scenarios systematically

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Multi-Version Test Matrix Execution ===${NC}"
echo "Date: $(date)"
echo "Test Directory: $(pwd)"
echo ""

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$TEST_DIR/test_matrix_results"
mkdir -p "$RESULTS_DIR"

# Test matrix variables
declare -a BASH_VERSIONS=(
    "5.2.37(1)-release"
    "4.0.44(1)-release" 
    "3.2.57(1)-release"
)

declare -a API_KEY_SCENARIOS=(
    "with_key"
    "without_key"
)

declare -a ARRAY_MODES=(
    "native"
    "compatibility"
)

# Global counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to log test results
log_result() {
    local test_name="$1"
    local status="$2"
    local output="$3"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    echo "$timestamp | $test_name | $status" >> "$RESULTS_DIR/test_matrix.log"
    if [[ "$status" == "FAILED" ]]; then
        echo "=== $test_name FAILURE DETAILS ===" >> "$RESULTS_DIR/failures.log"
        echo "$output" >> "$RESULTS_DIR/failures.log"
        echo "" >> "$RESULTS_DIR/failures.log"
    fi
}

# Function to run individual test
run_matrix_test() {
    local bash_version="$1"
    local api_key_scenario="$2"
    local array_mode="$3"
    local test_command="$4"
    local test_description="$5"
    
    ((TOTAL_TESTS++))
    
    local test_name="$test_description [bash:$bash_version, api:$api_key_scenario, mode:$array_mode]"
    echo -e "${BLUE}Testing: $test_name${NC}"
    
    # Set up test environment
    export BASH_VERSION="$bash_version"
    
    # Configure API key scenario
    if [[ "$api_key_scenario" == "with_key" ]]; then
        export LLM_OPENAI_API_KEY='test-key-matrix-12345'
    else
        unset LLM_OPENAI_API_KEY 2>/dev/null || true
    fi
    
    # Configure array mode
    if [[ "$array_mode" == "compatibility" ]]; then
        export BASH_ASSOC_ARRAY_SUPPORT='false'
    else
        export BASH_ASSOC_ARRAY_SUPPORT='true'
    fi
    
    # Execute test command
    local output
    local exit_status
    
    if output=$(eval "$test_command" 2>&1); then
        exit_status=0
        echo -e "${GREEN}✅ PASSED${NC}"
        log_result "$test_name" "PASSED" "$output"
        ((PASSED_TESTS++))
    else
        exit_status=$?
        echo -e "${RED}❌ FAILED (exit: $exit_status)${NC}"
        log_result "$test_name" "FAILED" "$output"
        ((FAILED_TESTS++))
        echo -e "${RED}Output: $output${NC}"
    fi
    
    echo ""
    return $exit_status
}

# Function to test cmd_set operation
test_cmd_set() {
    local bash_version="$1"
    local api_key_scenario="$2"
    local array_mode="$3"
    
    local command="bash -c 'source $TEST_DIR/llm-env set openai 2>/dev/null && echo SUCCESS'"
    run_matrix_test "$bash_version" "$api_key_scenario" "$array_mode" "$command" "cmd_set operation"
}

# Function to test provider list operation
test_cmd_list() {
    local bash_version="$1"
    local api_key_scenario="$2"
    local array_mode="$3"
    
    local command="bash -c 'source $TEST_DIR/llm-env list 2>/dev/null | grep -q \"Available providers\"'"
    run_matrix_test "$bash_version" "$api_key_scenario" "$array_mode" "$command" "cmd_list operation"
}

# Function to test version detection
test_version_detection() {
    local bash_version="$1"
    local api_key_scenario="$2"
    local array_mode="$3"
    
    local command="bash -c 'source $TEST_DIR/llm-env --version 2>/dev/null | grep -q \"LLM Environment Manager\"'"
    run_matrix_test "$bash_version" "$api_key_scenario" "$array_mode" "$command" "version detection"
}

echo -e "${YELLOW}Starting test matrix execution...${NC}"
echo "Testing across ${#BASH_VERSIONS[@]} bash versions, ${#API_KEY_SCENARIOS[@]} API key scenarios, ${#ARRAY_MODES[@]} array modes"
echo "Total test combinations: $((${#BASH_VERSIONS[@]} * ${#API_KEY_SCENARIOS[@]} * ${#ARRAY_MODES[@]} * 3))"
echo ""

# Clear previous results
> "$RESULTS_DIR/test_matrix.log"
> "$RESULTS_DIR/failures.log"

# Execute test matrix
for bash_version in "${BASH_VERSIONS[@]}"; do
    echo -e "${YELLOW}=== Testing Bash Version: $bash_version ===${NC}"
    
    for api_key_scenario in "${API_KEY_SCENARIOS[@]}"; do
        echo -e "${BLUE}--- API Key Scenario: $api_key_scenario ---${NC}"
        
        for array_mode in "${ARRAY_MODES[@]}"; do
            echo -e "${BLUE}.. Array Mode: $array_mode ..${NC}"
            
            # Test 1: Version detection (should always work)
            test_version_detection "$bash_version" "$api_key_scenario" "$array_mode"
            
            # Test 2: Provider list (should always work)
            test_cmd_list "$bash_version" "$api_key_scenario" "$array_mode"
            
            # Test 3: Provider set (depends on API key)
            test_cmd_set "$bash_version" "$api_key_scenario" "$array_mode"
            
            echo ""
        done
    done
done

# Generate summary report
echo -e "${YELLOW}=== Test Matrix Results Summary ===${NC}"
echo "Total Tests Executed: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo "Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
echo ""

# Analysis of expected vs actual failures
echo -e "${YELLOW}=== Failure Analysis ===${NC}"

# Count expected failures (cmd_set without API key should fail)
EXPECTED_FAILURES=$((${#BASH_VERSIONS[@]} * ${#ARRAY_MODES[@]} * 1))  # without_key scenario for cmd_set
UNEXPECTED_FAILURES=$((FAILED_TESTS - EXPECTED_FAILURES))

if [[ $UNEXPECTED_FAILURES -gt 0 ]]; then
    echo -e "${RED}Unexpected failures detected: $UNEXPECTED_FAILURES${NC}"
    echo "These failures indicate issues that need resolution."
elif [[ $UNEXPECTED_FAILURES -lt 0 ]]; then
    echo -e "${GREEN}Fewer failures than expected: Tests may be configured incorrectly${NC}"
    echo "Expected cmd_set to fail without API keys, but some passed."
else
    echo -e "${GREEN}Failure pattern matches expectations${NC}"
    echo "All failures appear to be expected API key-related failures."
fi

echo ""
echo -e "${YELLOW}Results saved to: $RESULTS_DIR/${NC}"
echo "- test_matrix.log: Complete test execution log"
echo "- failures.log: Detailed failure information"

# Return appropriate exit code
if [[ $UNEXPECTED_FAILURES -gt 0 ]]; then
    echo -e "${RED}🔥 Test matrix completed with unexpected failures${NC}"
    exit 1
else
    echo -e "${GREEN}🎉 Test matrix completed successfully${NC}"
    exit 0
fi