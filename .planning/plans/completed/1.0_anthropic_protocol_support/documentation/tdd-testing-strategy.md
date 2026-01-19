# TDD & Testing Strategy [CRITICAL]

## Overview

Testing bash scripts is critical due to the lack of compile-time checks. The TDD approach for Bash uses the BATS (Bash Automated Testing System) framework alongside static analysis tools to ensure code quality and reliability.

> Source: implementation-standards.md:28

## Pragmatic TDD Cycle

The development process follows the classic RED-GREEN-REFACTOR cycle adapted for Bash scripting:

### 1. RED: Write Failing Test
- Create a `.bats` file
- Write a test case asserting the expected output or exit code
- Run `bats test.bats` -> Fail

> Source: implementation-standards.md:39-42

### 2. GREEN: Make Test Pass
- Implement the minimal logic in the script or function
- Ensure `shellcheck` passes
- Run `bats test.bats` -> Pass

> Source: implementation-standards.md:44-47

### 3. REFACTOR: Improve Code
- Clean up logic, improve variable names
- Extract complex logic into functions
- Ensure tests still pass

> Source: implementation-standards.md:49-52

## Test Structure

Test files are organized in the `tests/` directory with three categories:

```
tests/
├── unit/              # Test individual functions
│   ├── test_validation.bats
│   ├── test_bash_compatibility.bats
│   └── test_bash_versions.bats
├── integration/       # Test command execution
│   └── test_providers.bats
└── system/            # Cross-platform tests
    └── test_cross_platform.bats
```

> Source: architecture.md:234-247

## BATS Framework Usage

### Test Structure Pattern

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

> Source: packages/bats.md:17-35

### Special Variables

- `$status` - Exit code of last command
- `$output` - Combined stdout and stderr
- `$lines` - Array of output lines
- `$BATS_TEST_FILENAME` - Test file name

> Source: packages/bats.md:37-42

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

> Source: packages/bats.md:45-55

### Test Execution

- Run all tests: `./tests/run_tests.sh`
- Run specific suite: `bats tests/unit/test_validation.bats`
- Run with TAP output: `bats --tap tests/unit/test_validation.bats`

> Source: packages/bats.md:57-62

### BATS Framework Features Used

- `setup()` / `teardown()` for test lifecycle
- `run` command for executing shell commands
- `$status`, `$output`, `$lines` for assertions
- `@test` decorators for test functions
- File-scoped setup/teardown files

> Source: architecture.md:249-255

## Quality Standards

All code must meet the following quality criteria:

- **Linting**: Zero `shellcheck` warnings
- **Function Length**: Keep functions short (screen length)
- **Cognitive Complexity**: Avoid deeply nested `if/then/else` blocks. Use `return` early or `case` statements
- **DRY**: If you copy-paste code, refactor it into a function
- **Idempotency**: Scripts should be safe to run multiple times (e.g., check if directory exists before creating)
- **Fast Feedback**: Unit tests should run in milliseconds

> Source: implementation-standards.md:56-64

## Development Workflow

### Continuous Integration Process

1. **Lint**: `shellcheck **/*.sh`
2. **Format Check**: `shfmt -d .`
3. **Test**: `bats tests/`
4. **Deploy**: Copy/Sync scripts to target environment

> Source: implementation-standards.md:69-75

### Testing Tools

| Tool | Purpose | Command |
|------|---------|---------|
| BATS | Test framework | `bats tests/` |
| shellcheck | Static analysis | `shellcheck **/*.sh` |
| shfmt | Code formatting | `shfmt -d .` |

> Source: implementation-standards.md:32-35

### Best Practices

1. **Descriptive test names** - Use clear, complete sentences
2. **Arrange/Act/Assert** - Structure tests logically
3. **One assertion per test** - Keep tests focused
4. **Use helpers** - Reuse common test patterns

> Source: packages/bats.md:65-70

## Quick Reference

| Aspect | Pattern/Command | Source |
|--------|-----------------|--------|
| Test file extension | `*.bats` | packages/bats.md:19 |
| Test decorator | `@test "description"` | packages/bats.md:21 |
| Run command | `run some_command` | packages/bats.md:31 |
| Status assertion | `[ $status -eq 0 ]` | packages/bats.md:32 |
| Output assertion | `[ "$output" = "expected" ]` | packages/bats.md:33 |
| Setup function | `setup() { ... }` | packages/bats.md:46 |
| Teardown function | `teardown() { ... }` | packages/bats.md:51 |
| Run all tests | `bats tests/` | implementation-standards.md:73 |
 | Run single test | `bats tests/unit/test_validation.bats` | packages/bats.md:61 |
 | Lint shell scripts | `shellcheck **/*.sh` | implementation-standards.md:71 |
 | Check formatting | `shfmt -d .` | implementation-standards.md:72 |
