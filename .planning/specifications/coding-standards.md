## Coding Standards

#### Code Style

###### General Principles

- **Readability First**: Code is read 10x more than it's written.
- **Consistency**: Follow established patterns (Google Shell Style Guide inspired).
- **Safety**: Robustness is key in shell scripts (`set -euo pipefail`).
- **Explicit over Implicit**: Quote variables, use long flags for clarity in scripts.

###### Naming Conventions

- **Variables (Local)**: `snake_case` (e.g., `local user_name="alice"`)
- **Variables (Environment/Global)**: `SCREAMING_SNAKE_CASE` (e.g., `export API_KEY="xyz"`)
- **Functions**: `snake_case` (e.g., `process_data()`)
- **Constants**: `SCREAMING_SNAKE_CASE` (e.g., `readonly MAX_RETRIES=3`)
- **Files**: `snake_case.sh` (e.g., `backup_script.sh`)

###### File Organization

- **Shebang**: Always start with `##!/usr/bin/env bash`
- **Header**: Description of script purpose
- **Imports**: `source` dependencies relative to the script location
- **Constants**: Define global constants early
- **Functions**: Define all functions before the main execution logic
- **Main**: Use a `main()` function and call it at the end:
  ```bash
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
  fi
  ```
  *(Exception: Sourced scripts (libraries or environment managers) should not use this wrapper if they need to execute in the current shell context.)*

---

#### Code Quality

###### Function Design

- **Single Responsibility**: One function, one job.
- **Local Variables**: Always use `local` for variables inside functions to avoid polluting global scope.
- **Inputs/Outputs**:
  - Pass arguments to functions, don't rely on globals.
  - Return values via `echo` (for data) or exit codes (for status).
- **Usage**: Provide a `usage()` function for CLI scripts.

###### Error Handling

- **Strict Mode**: Start all executable scripts with:
  ```bash
  set -euo pipefail
  ```
  - `-e`: Exit immediately if a command exits with a non-zero status.
  - `-u`: Treat unset variables as an error.
  - `-o pipefail`: Return value of a pipeline is the status of the last command to exit with a non-zero status.
  *(Exception: Sourced scripts should generally avoid `set -e` as it can exit the user's interactive shell on error. Instead, use explicit error checking.)*
- **Cleanup**: Use `trap` for cleanup tasks (deleting temp files).
  ```bash
  trap 'rm -f "$temp_file"' EXIT
  ```
- **Logging**: Use a logging function (e.g., `log_info`, `log_error`) that writes to stderr (`>&2`).

###### Comments

- **Doc Comments**: Use `####` for function documentation (params, returns).
- **Why, not What**: Explain complex logic or regex.
- **TODOs**: Mark incomplete work with `## TODO: description`.

###### Formatting

- **Indentation**: 2 spaces.
- **Line Length**: 80 characters preferred, 100 max.
- **Blocks**: Put `then` and `do` on the same line.
  ```bash
  if [[ -z "$var" ]]; then
    echo "Empty"
  fi
  ```

---

#### Testing Standards

###### Test Structure

- Use a testing framework like `bats-core` (Bash Automated Testing System).
- **Unit Tests**: Test individual functions by sourcing the script (wrapped in `if [[ "${BASH_SOURCE[0]}"...`).
- **Integration Tests**: Test the script execution as a black box.

###### Test Coverage

- Test success paths (exit code 0).
- Test failure paths (exit codes > 0).
- Test edge cases (empty inputs, spaces in filenames).

---

#### Performance Guidelines

- **Built-ins**: Prefer Bash built-ins over external processes (subshells) where possible.
  - Use `${string//pattern/replacement}` instead of `sed`.
  - Use `[[ ]]` instead of `[ ]` or `test`.
- **Subshells**: Avoid unnecessary subshells `$(...)` in loops.
- **Pipes**: Minimize long pipes in critical loops.

---

#### Security Considerations

- **Quoting**: ALWAYS quote variables `"$var"` to prevent word splitting and globbing.
- **Eval**: Avoid `eval` unless absolutely necessary and inputs are strictly controlled.
- **Input Validation**: Validate arguments and environment variables early.
- **Linting**: Run `shellcheck` on all scripts before committing.

---

**Note**: Adapt these standards to your project's specific needs. Consistency within the codebase is more important than strict adherence to any standard.
