## Implementation Standards

#### Core Principles

###### Black Box Architecture

Scripts and functions should be modular and composable:

- **Unix Philosophy**: Write programs that do one thing and do it well. Write programs to work together.
- **Standard Streams**: Use STDIN for input and STDOUT for data output. Use STDERR for logs/status.
- **Environment Config**: Use environment variables for configuration (12-factor app style).
- **Replaceability**: Functions should have clear interfaces (arguments) so implementation can change without breaking callers.

###### Architecture Framework

1. **Library Pattern**: Identify reusable logic and place in `lib/` or `utils/`.
2. **Entry Points**: Scripts in `bin/` should be thin wrappers around library functions.
3. **Dependency Check**: Verify required external tools (`jq`, `curl`, etc.) exist at startup.
4. **Interface Design**:
   - CLI flags for runtime options.
   - Environment variables for secrets/config.
   - Exit codes for status (0 = success, >0 = error).

---

#### Test-Driven Development (TDD)

###### Pragmatic TDD Approach for Bash

Testing shell scripts is critical due to the lack of compile-time checks.

######## Tools
- **Framework**: `bats-core` (Bash Automated Testing System).
- **Linting**: `shellcheck` (Static Analysis).
- **Formatting**: `shfmt`.

######## TDD Cycle

1. **RED: Write Failing Test**
   - Create a `.bats` file.
   - Write a test case asserting the expected output or exit code.
   - Run `bats test.bats` -> Fail.

2. **GREEN: Make Test Pass**
   - Implement the minimal logic in the script or function.
   - Ensure `shellcheck` passes.
   - Run `bats test.bats` -> Pass.

3. **REFACTOR: Improve Code**
   - Clean up logic, improve variable names.
   - Extract complex logic into functions.
   - Ensure tests still pass.

---

#### Quality Standards

- **Linting**: Zero `shellcheck` warnings.
- **Function Length**: Keep functions short (screen length).
- **Cognitive Complexity**: Avoid deeply nested `if/then/else` blocks. Use `return` early or `case` statements.
- **DRY**: If you copy-paste code, refactor it into a function.
- **Idempotency**: Scripts should be safe to run multiple times (e.g., check if directory exists before creating).
- **Fast Feedback**: Unit tests should run in milliseconds.

---

#### Development Workflow

###### Continuous Integration

1. **Lint**: `shellcheck **/*.sh`
2. **Format Check**: `shfmt -d .`
3. **Test**: `bats tests/`
4. **Deploy**: Copy/Sync scripts to target environment.

---

#### Language-Specific Notes

**Bash Specifics:**

- **Arrays**: Use Bash arrays `my_array=("a" "b")` instead of space-separated strings when possible.
- **Parameter Expansion**: Use `${parameter:-default}` for defaults and `${parameter:?error}` for required variables.
- **Arithmetic**: Use `(( ))` for arithmetic operations.
- **Tests**: Prefer `[[ ... ]]` over `[ ... ]` for more features and safety.
- **Global Namespace**: Bash has a single global namespace. mitigate this by:
  - Using `local` in functions.
  - Prefixing global variables (e.g., `MYAPP_CONFIG_PATH`).
  - Unsetting variables when done if strictly necessary.
