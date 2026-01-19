# Packages Documentation

This directory contains documentation for third-party packages used in the llm-env project.

## Overview

llm-env is a **pure Bash** project with **zero runtime dependencies**. All third-party packages listed here are used only for development and testing purposes.

## Development Packages

| Package | Type | Purpose | Documentation |
|---------|------|---------|---------------|
| [BATS](bats.md) | Testing | Bash Automated Testing System | [GitHub](https://github.com/bats-core/bats-core) |
| [shellcheck](shellcheck.md) | Linting | Static analysis for shell scripts | [Website](https://www.shellcheck.net/) |
| [shfmt](shfmt.md) | Formatting | Shell script formatter | [GitHub](https://github.com/mvdan/sh) |

## Runtime Requirements

**None** - The core `llm-env` script runs on any system with Bash 3.2+.

### Optional Runtime Dependencies

These tools may be used by various commands but are not required for core functionality:

| Tool | Used By | Required |
|------|---------|----------|
| `curl` | `llm-env test`, `install.sh` | No (test connectivity only) |
| `awk` | Various parsing operations | No (built-in on most systems) |
| `sed` | Text manipulation | No (built-in on most systems) |

## Installation Summary

For development environment setup:

```bash
# macOS
brew install bats shellcheck shfmt

# Ubuntu/Debian
sudo apt-get install bats-core shellcheck
# shfmt via go: go install mvdan.cc/sh/v3/cmd/shfmt@latest
```

## CI/CD Integration

All packages are integrated in the GitHub Actions workflow (`.github/workflows/test.yml`):

1. **shellcheck** - Lints all `.sh` files
2. **shfmt** - Checks code formatting
3. **bats** - Runs test suites across multiple Bash versions

## Adding New Packages

When adding a new development package:

1. Update this README with package information
2. Create a dedicated markdown file (e.g., `new-tool.md`)
3. Update CI/CD workflow if needed
4. Document installation instructions
5. Update `install.sh` if it's a runtime dependency
