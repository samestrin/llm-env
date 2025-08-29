#!/usr/bin/env bash

# LLM Environment Manager - Test Runner
# This script runs all test suites using the BATS framework

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 LLM Environment Manager                     ║"
    echo "║                     Test Suite Runner                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo -e "\n${YELLOW}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if BATS is available
check_bats() {
    if [[ ! -f "$SCRIPT_DIR/bats/bin/bats" ]]; then
        print_error "BATS framework not found!"
        echo "Please run: git submodule update --init --recursive"
        exit 1
    fi
    print_success "BATS framework found"
}

# Run a specific test suite
run_test_suite() {
    local suite_name="$1"
    local test_path="$2"
    
    print_section "Running $suite_name Tests"
    
    if [[ ! -d "$test_path" ]]; then
        print_error "$suite_name test directory not found: $test_path"
        return 1
    fi
    
    local test_files=("$test_path"/*.bats)
    if [[ ! -e "${test_files[0]}" ]]; then
        print_error "No test files found in $test_path"
        return 1
    fi
    
    local failed=0
    for test_file in "${test_files[@]}"; do
        if [[ -f "$test_file" ]]; then
            echo "Running $(basename "$test_file")..."
            if "$SCRIPT_DIR/bats/bin/bats" "$test_file"; then
                print_success "$(basename "$test_file") passed"
            else
                print_error "$(basename "$test_file") failed"
                ((failed++))
            fi
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        print_success "$suite_name tests completed successfully"
        return 0
    else
        print_error "$suite_name tests failed ($failed test files)"
        return 1
    fi
}

# Main test execution
main() {
    print_header
    
    print_info "Project root: $PROJECT_ROOT"
    print_info "Test directory: $SCRIPT_DIR"
    
    # Check prerequisites
    check_bats
    
    # Initialize test results
    local total_suites=0
    local failed_suites=0
    
    # Parse command line arguments
    local run_unit=true
    local run_integration=true
    local run_system=true
    local verbose=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit-only)
                run_integration=false
                run_system=false
                shift
                ;;
            --integration-only)
                run_unit=false
                run_system=false
                shift
                ;;
            --system-only)
                run_unit=false
                run_integration=false
                shift
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --unit-only        Run only unit tests"
                echo "  --integration-only Run only integration tests"
                echo "  --system-only      Run only system tests"
                echo "  --verbose, -v      Verbose output"
                echo "  --help, -h         Show this help"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Set BATS options based on verbosity
    if [[ "$verbose" == "true" ]]; then
        export BATS_VERBOSE_RUN=1
    fi
    
    echo "Starting test execution..."
    
    # Run unit tests
    if [[ "$run_unit" == "true" ]]; then
        ((total_suites++))
        if ! run_test_suite "Unit" "$SCRIPT_DIR/unit"; then
            ((failed_suites++))
        fi
    fi
    
    # Run integration tests
    if [[ "$run_integration" == "true" ]]; then
        ((total_suites++))
        if ! run_test_suite "Integration" "$SCRIPT_DIR/integration"; then
            ((failed_suites++))
        fi
    fi
    
    # Run system tests
    if [[ "$run_system" == "true" ]]; then
        ((total_suites++))
        if ! run_test_suite "System" "$SCRIPT_DIR/system"; then
            ((failed_suites++))
        fi
    fi
    
    # Print summary
    print_section "Test Summary"
    echo "Total test suites: $total_suites"
    echo "Passed: $((total_suites - failed_suites))"
    echo "Failed: $failed_suites"
    
    if [[ $failed_suites -eq 0 ]]; then
        print_success "All tests passed! 🎉"
        exit 0
    else
        print_error "Some tests failed! 💥"
        exit 1
    fi
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}Test execution interrupted${NC}"; exit 130' INT TERM

# Run main function
main "$@"