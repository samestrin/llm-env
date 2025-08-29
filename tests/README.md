# LLM Environment Manager - Test Suite

This directory contains comprehensive tests for the LLM Environment Manager using the [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) framework.

## Test Structure

```
tests/
├── bats/                    # BATS framework (git submodule)
├── unit/                    # Unit tests for individual functions
│   └── test_validation.bats # Input validation and core function tests
├── integration/             # Integration tests for feature workflows
│   └── test_providers.bats  # Provider management and configuration tests  
├── system/                  # System-level and cross-platform tests
│   └── test_cross_platform.bats # Environment isolation and compatibility
├── run_tests.sh            # Test runner script
└── README.md               # This file
```

## Running Tests

### Prerequisites

1. **Initialize BATS submodule** (first time only):
   ```bash
   git submodule update --init --recursive
   ```

2. **Make test runner executable**:
   ```bash
   chmod +x tests/run_tests.sh
   ```

### Test Execution

**Run all tests:**
```bash
./tests/run_tests.sh
```

**Run specific test suites:**
```bash
./tests/run_tests.sh --unit-only        # Unit tests only
./tests/run_tests.sh --integration-only # Integration tests only  
./tests/run_tests.sh --system-only      # System tests only
```

**Verbose output:**
```bash
./tests/run_tests.sh --verbose
```

**Run individual test files:**
```bash
tests/bats/bin/bats tests/unit/test_validation.bats
tests/bats/bin/bats tests/integration/test_providers.bats
tests/bats/bin/bats tests/system/test_cross_platform.bats
```

## Test Categories

### Unit Tests (`tests/unit/`)

Tests individual functions in isolation:

- **Input Validation**: `validate_provider_name()` function with valid/invalid inputs
- **Debug Functionality**: Debug output behavior with different `LLM_ENV_DEBUG` settings
- **Version Information**: Ensures VERSION constant is properly defined
- **Core Utilities**: Individual helper functions and error handling

**Coverage:**
- ✅ Provider name validation (regex patterns, edge cases)
- ✅ Debug logging functionality
- ✅ Version constant verification
- ✅ Error handling for invalid inputs

### Integration Tests (`tests/integration/`)

Tests feature workflows and provider management:

- **Configuration Management**: Reading, parsing, and validating configuration files
- **Provider Operations**: Setting, unsetting, and switching between providers
- **Environment Variables**: Correct setting and clearing of OpenAI-compatible variables
- **Backup/Restore**: Configuration backup and restore functionality
- **Error Scenarios**: Handling missing API keys, disabled providers, invalid configurations

**Coverage:**
- ✅ Provider listing (enabled/disabled filtering)
- ✅ Provider setting with environment variable export
- ✅ Configuration backup and restore operations
- ✅ Error handling for missing providers and API keys
- ✅ Malformed configuration file handling

### System Tests (`tests/system/`)

Tests cross-platform compatibility and system-level behavior:

- **Environment Isolation**: Tests in isolated temporary environments
- **Configuration Discovery**: XDG Base Directory specification compliance
- **Cross-Platform Compatibility**: Path handling, permission management
- **Command-Line Interface**: Argument parsing, help system, version display
- **Concurrency Safety**: Multiple simultaneous process handling
- **Resource Limits**: Large configuration files, memory usage

**Coverage:**
- ✅ Configuration directory creation and fallback behavior
- ✅ Command-line argument processing
- ✅ Environment variable isolation between processes
- ✅ Permission handling for configuration files
- ✅ Large configuration file performance
- ✅ Concurrent access safety

## Test Environment

Tests run in isolated environments to prevent interference with user configurations:

- **Temporary Directories**: Each test gets a unique temporary directory
- **Environment Isolation**: `$HOME`, `$XDG_CONFIG_HOME` redirected to test directories
- **Clean State**: All environment variables cleared between tests
- **No Side Effects**: Tests don't modify system files or user configurations

## Continuous Integration

Tests run automatically on:

- **GitHub Actions**: Ubuntu and macOS with bash/zsh shells
- **Pull Requests**: All tests must pass before merging
- **Push to Main**: Regression testing on main branch updates

Additional CI checks:

- **ShellCheck**: Static analysis for shell scripting best practices
- **Security Scanning**: Basic checks for secrets and file permissions
- **Installation Testing**: Verifies installer script functionality

## Adding New Tests

### Unit Test Example

```bash
@test "new_function: handles valid input" {
    run new_function "valid_input"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected_output" ]]
}

@test "new_function: rejects invalid input" {
    run new_function "invalid_input"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "error_message" ]]
}
```

### Integration Test Example

```bash
setup() {
    source "$BATS_TEST_DIRNAME/../../llm-env"
    export TEST_CONFIG_DIR="$BATS_TMPDIR/test-$$"
    mkdir -p "$TEST_CONFIG_DIR"
    export XDG_CONFIG_HOME="$TEST_CONFIG_DIR"
}

teardown() {
    rm -rf "$TEST_CONFIG_DIR"
    unset LLM_PROVIDER OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
}

@test "feature: works with test configuration" {
    # Create test config
    cat > "$TEST_CONFIG_DIR/config.conf" << 'EOF'
[test_provider]
base_url=https://api.test.com/v1
api_key_var=LLM_TEST_API_KEY
default_model=test-model
description=Test provider
enabled=true
EOF
    
    export LLM_TEST_API_KEY="test-key"
    
    run cmd_set "test_provider"
    [ "$status" -eq 0 ]
    [ "$OPENAI_API_KEY" = "test-key" ]
}
```

## Debugging Tests

**Run with verbose output:**
```bash
tests/bats/bin/bats --verbose-run tests/unit/test_validation.bats
```

**Run single test:**
```bash
tests/bats/bin/bats --filter "validate_provider_name: accepts valid" tests/unit/test_validation.bats
```

**Debug test environment:**
```bash
# Add debug statements to test files
echo "DEBUG: $variable_name" >&3  # BATS debug output
```

## Test Coverage Goals

- **Unit Tests**: 100% coverage of individual functions
- **Integration Tests**: All major user workflows and error paths
- **System Tests**: Cross-platform compatibility and edge cases
- **Regression Tests**: All reported bugs should have corresponding tests

## Performance Considerations

- Tests should complete in under 30 seconds total
- Use minimal external dependencies (only curl for API testing)
- Avoid sleep statements; use proper synchronization
- Clean up temporary files and processes

## Contributing

When adding new features:

1. **Write tests first** (TDD approach recommended)
2. **Update existing tests** if behavior changes
3. **Add integration tests** for new user-facing features
4. **Test cross-platform** compatibility if touching system interactions
5. **Update this README** if adding new test categories

For questions or suggestions about the test suite, please open an issue or discussion on the GitHub repository.