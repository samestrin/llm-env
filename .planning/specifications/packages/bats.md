# BATS - Bash Automated Testing System

## Documentation

- **Website:** https://github.com/bats-core/bats-core
- **Documentation:** https://bats-core.readthedocs.io/en/stable/
- **Installation:** https://github.com/bats-core/bats-core#installation

## Overview

BATS (Bash Automated Testing System) is a testing framework for Bash. It allows you to write executable tests that are also readable and maintainable.

## Key Concepts

### Test Structure

```bash
#!/usr/bin/env bats
# File: tests/unit/test_example.bats

@test "Example test description" {
    # Arrange
    local expected="hello"
    # Act
    local result="hello"
    # Assert
    [ "$result" = "$expected" ]
}

@test "Another test" {
    run some_command
    [ $status -eq 0 ]
    [ "$output" = "expected output" ]
}
```

### Special Variables
- `$status` - Exit code of last command
- `$output` - Combined stdout and stderr
- `$lines` - Array of output lines
- `$BATS_TEST_FILENAME` - Test file name

### Setup/Teardown

```bash
setup() {
    # Runs before each test
    export TEST_VAR="value"
}

teardown() {
    # Runs after each test
    unset TEST_VAR
}
```

## Usage in llm-env

- Test files located in `tests/unit/`, `tests/integration/`, `tests/system/`
- Run all tests: `./tests/run_tests.sh`
- Run specific suite: `bats tests/unit/test_validation.bats`
- Run with output: `bats --tap tests/unit/test_validation.bats`

## Best Practices

1. **Descriptive test names** - Use clear, complete sentences
2. **Arrange/Act/Assert** - Structure tests logically
3. **One assertion per test** - Keep tests focused
4. **Use helpers** - Reuse common test patterns
