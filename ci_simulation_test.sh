#!/usr/bin/env bash

# CI Simulation Test Script for GitHub Automation Test Failure Resolution
# Simulates ubuntu-latest environment for local testing

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== CI Environment Simulation Test ===${NC}"
echo "Date: $(date)"
echo "Platform: $(uname -s)"
echo "Shell: $SHELL"
echo "Bash Version: $BASH_VERSION"
echo ""

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LLM_ENV_SCRIPT="$TEST_DIR/llm-env"

# Simulate CI environment variables (typically unset in CI)
unset LLM_OPENAI_API_KEY 2>/dev/null || true
unset LLM_PROVIDER 2>/dev/null || true
unset OPENAI_API_KEY 2>/dev/null || true
unset OPENAI_BASE_URL 2>/dev/null || true
unset OPENAI_MODEL 2>/dev/null || true

echo -e "${YELLOW}Testing: BATS test_bash_versions.bats${NC}"

# Run the specific failing test
echo "Running BATS test suite..."
if bats "$TEST_DIR/tests/unit/test_bash_versions.bats"; then
    echo -e "${GREEN}✅ All tests PASSED${NC}"
    TEST_RESULT="PASSED"
else
    echo -e "${RED}❌ Some tests FAILED${NC}" 
    TEST_RESULT="FAILED"
fi

echo ""
echo -e "${YELLOW}Testing: Direct cmd_set execution without API key${NC}"

# Test cmd_set behavior without API key (simulating CI environment)
echo "Testing native array mode:"
if OUTPUT=$(bash -c "
    export BASH_ASSOC_ARRAY_SUPPORT='true'
    source '$LLM_ENV_SCRIPT' set openai 2>&1
"); then
    echo -e "${GREEN}✅ Native mode: Exit status 0${NC}"
    echo "Output: $OUTPUT"
    NATIVE_RESULT="SUCCESS" 
else
    echo -e "${RED}❌ Native mode: Exit status $?${NC}"
    echo "Output: $OUTPUT"
    NATIVE_RESULT="FAILURE"
fi

echo ""
echo "Testing compatibility array mode:"
if OUTPUT=$(bash -c "
    export BASH_ASSOC_ARRAY_SUPPORT='false'
    source '$LLM_ENV_SCRIPT' set openai 2>&1
"); then
    echo -e "${GREEN}✅ Compatibility mode: Exit status 0${NC}"
    echo "Output: $OUTPUT"
    COMPAT_RESULT="SUCCESS"
else
    echo -e "${RED}❌ Compatibility mode: Exit status $?${NC}" 
    echo "Output: $OUTPUT"
    COMPAT_RESULT="FAILURE"
fi

echo ""
echo -e "${YELLOW}Testing: With API key configured${NC}"

# Test cmd_set behavior with API key (fixed test scenario)
echo "Testing native array mode with API key:"
if OUTPUT=$(bash -c "
    export LLM_OPENAI_API_KEY='test-key-12345'
    export BASH_ASSOC_ARRAY_SUPPORT='true'
    source '$LLM_ENV_SCRIPT' set openai 2>&1
"); then
    echo -e "${GREEN}✅ Native mode with API key: Exit status 0${NC}"
    echo "Output: $OUTPUT"
    NATIVE_KEY_RESULT="SUCCESS"
else
    echo -e "${RED}❌ Native mode with API key: Exit status $?${NC}"
    echo "Output: $OUTPUT"
    NATIVE_KEY_RESULT="FAILURE"
fi

echo ""
echo "Testing compatibility array mode with API key:"
if OUTPUT=$(bash -c "
    export LLM_OPENAI_API_KEY='test-key-12345'
    export BASH_ASSOC_ARRAY_SUPPORT='false'
    source '$LLM_ENV_SCRIPT' set openai 2>&1
"); then
    echo -e "${GREEN}✅ Compatibility mode with API key: Exit status 0${NC}"
    echo "Output: $OUTPUT"
    COMPAT_KEY_RESULT="SUCCESS"
else
    echo -e "${RED}❌ Compatibility mode with API key: Exit status $?${NC}"
    echo "Output: $OUTPUT"
    COMPAT_KEY_RESULT="FAILURE"
fi

# Summary report
echo ""
echo -e "${YELLOW}=== CI Simulation Results Summary ===${NC}"
echo "BATS Test Suite: $TEST_RESULT"
echo "Native Mode (no API key): $NATIVE_RESULT"
echo "Compatibility Mode (no API key): $COMPAT_RESULT"
echo "Native Mode (with API key): $NATIVE_KEY_RESULT"  
echo "Compatibility Mode (with API key): $COMPAT_KEY_RESULT"

# Determine overall result
if [[ "$TEST_RESULT" == "PASSED" && "$NATIVE_KEY_RESULT" == "SUCCESS" && "$COMPAT_KEY_RESULT" == "SUCCESS" ]]; then
    echo -e "${GREEN}🎉 CI Simulation: ALL TESTS PASSED${NC}"
    echo "The GitHub automation test failure has been resolved!"
    exit 0
else
    echo -e "${RED}💥 CI Simulation: ISSUES DETECTED${NC}"
    echo "Further investigation needed for CI pipeline success."
    exit 1
fi