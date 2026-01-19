# Coding Standards & Security [IMPORTANT]

## Overview

This document defines code style and security considerations for the Anthropic protocol support implementation in llm-env. The codebase is primarily Bash with a focus on bash 3.2 compatibility (macOS default) and strict security practices for handling credentials.

> Source: coding-standards.md lines 3-10, codebase-discovery.json architecture_notes

## Naming Conventions

### Variable Naming

| Scope | Format | Example |
|-------|--------|---------|
| Local Variables | `snake_case` | `local user_name="alice"` |
| Environment/Global | `SCREAMING_SNAKE_CASE` | `export API_KEY="xyz"` |
| Functions | `snake_case` | `process_data()` |
| Constants | `SCREAMING_SNAKE_CASE` | `readonly MAX_RETRIES=3` |
| Files | `snake_case.sh` | `backup_script.sh` |

### Anthropic-Specific Variable Names

Following project conventions for OpenAI variables:

```bash
# Protocol identifier (new)
ANTHROPIC_PROTOCOL="anthropic"

# Authentication tokens (new - to be masked)
export ANTHROPIC_API_KEY="..."
export ANTHROPIC_AUTH_TOKEN="..."

# Configuration (follow existing pattern)
ANTHROPIC_BASE_URL="https://api.anthropic.com"
ANTHROPIC_DEFAULT_MODEL="claude-sonnet-4-20250514"
```

> Source: coding-standards.md lines 12-18, codebase-discovery.json integration_points

## Function Design

### Core Principles

- **Single Responsibility**: One function, one job.
- **Local Variables**: Always use `local` for variables inside functions to avoid polluting global scope.
- **Inputs/Outputs**:
  - Pass arguments to functions, don't rely on globals.
  - Return values via `echo` (for data) or exit codes (for status).
- **Usage**: Provide a `usage()` function for CLI scripts.

### Wrapper Function Pattern

The codebase uses wrapper functions for bash 3.2 associative array compatibility:

```bash
# Example existing pattern (llm-env:236-288)
set_provider_value() { ... }
get_provider_value() { ... }
```

> Source: coding-standards.md lines 39-46, codebase-discovery.json lines 30-34

## Error Handling

### Strict Mode

Executable scripts should use strict mode:

```bash
set -euo pipefail
```

**Key Exemption**: Sourced scripts (libraries or environment managers like `llm-env`) should **avoid** `set -e` as it can exit the user's interactive shell on error. Instead, use explicit error checking.

```bash
# Instead of relying on set -e
if ! some_command; then
  log_error "Command failed"
  return 1
fi
```

### Cleanup with Trap

```bash
trap 'rm -f "$temp_file"' EXIT
```

### Logging

Use logging functions that write to stderr (`>&2`):

```bash
log_info() {
  echo "[INFO] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}
```

> Source: coding-standards.md lines 48-62

## Formatting

- **Indentation**: 2 spaces
- **Line Length**: 80 characters preferred, 100 max
- **Blocks**: Put `then` and `do` on the same line

```bash
if [[ -z "$var" ]]; then
  echo "Empty"
fi

for item in "${array[@]}"; do
  echo "$item"
done
```

> Source: coding-standards.md lines 70-80

## Security Considerations

### Variable Quoting

**ALWAYS quote variables** `"$var"` to prevent word splitting and globbing. This is particularly critical when handling API keys and authentication tokens.

```bash
# Correct
curl -H "Authorization: Bearer $ANTHROPIC_API_KEY" "$ANTHROPIC_BASE_URL"

# Incorrect - vulnerable to word splitting
curl -H Authorization: Bearer $ANTHROPIC_API_KEY $ANTHROPIC_BASE_URL
```

### Input Validation

Validate arguments and environment variables early:

```bash
check_required_vars() {
  local missing=()
  for var in "$@"; do
    [[ -z "${!var}" ]] && missing+=("$var")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing required variables: ${missing[*]}"
    return 1
  fi
  return 0
}
```

### Linting Requirements

Run `shellcheck` on all scripts before committing. This catches security issues like unquoted variables, eval misuse, and other shell best practice violations.

```bash
shellcheck llm-env
```

> Source: coding-standards.md lines 109-116

## Variable Masking

### The mask() Function Pattern

The `mask()` function in `llm-env:643-662` masks sensitive values for display:

```bash
mask() {
  local input="$1"
  [[ -z "$input" ]] && { echo "∅"; return; }
  [[ ${#input} -le 2 ]] && { echo "$input"; return; }

  # For strings of 3-4 characters, mask first character only
  if [[ ${#input} -le 4 ]]; then
    echo "•${input:1}"
    return
  fi

  # For strings > 4 characters, mask all but last 4 characters
  local masked=""
  local i
  for ((i=0; i<${#input}-4; i++)); do
    masked+="•"
  done
  masked+="${input: -4}"
  echo "$masked"
}
```

### Applying mask() to Anthropic Variables

When implementing `cmd_show()`, apply masking to Anthropic variables:

```bash
cmd_show() {
  # ... existing code ...
  [[ -n "$ANTHROPIC_API_KEY" ]] && echo "ANTHROPIC_API_KEY: $(mask "$ANTHROPIC_API_KEY")"
  [[ -n "$ANTHROPIC_AUTH_TOKEN" ]] && echo "ANTHROPIC_AUTH_TOKEN: $(mask "$ANTHROPIC_AUTH_TOKEN")"
  # ... existing code ...
}
```

> Source: codebase-discovery.json lines 36-40, llm-env:643-662

## Quick Reference

| Category | Standard | Anthropic Application |
|----------|----------|----------------------|
| Variable Names | `snake_case` (local), `SCREAMING_SNAKE_CASE` (env) | `ANTHROPIC_API_KEY`, `local protocol_id` |
| Strict Mode | `set -euo pipefail` for executables | **Do NOT use** in sourced scripts |
| Quoting | Always quote: `"$var"` | Required for all API tokens |
| Credential Display | Use `mask()` function in `cmd_show()` | Apply to `ANTHROPIC_API_KEY` |
| Linting | Run `shellcheck` before commit | Verify all new code passes |
| Line Length | 80 preferred, 100 max | Keep headers readable |
| Indentation | 2 spaces | Consistent across files |
