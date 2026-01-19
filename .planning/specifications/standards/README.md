# Standards Reference

This directory contains standards and guidelines for the llm-env project.

## Overview

These standards ensure code quality, consistency, and maintainability across the project.

## Available Standards

| Standard | Description |
|----------|-------------|
| [coding-standards.md](../coding-standards.md) | Code style, naming conventions, formatting |
| [implementation-standards.md](../implementation-standards.md) | Architecture patterns, TDD, quality standards |
| [git-strategy.md](../git-strategy.md) | Git workflow, commit conventions, branching |

## Standards Summary

### Code Style

- **Bash 3.2+ Compatibility** - Use compatibility wrapper for associative arrays
- **Naming:** `snake_case` for functions/locals, `SCREAMING_SNAKE_CASE` for globals
- **Indentation:** 2 spaces
- **Line Length:** 80 preferred, 100 max
- **Shebang:** `#!/usr/bin/env bash`

### Quality Standards

- **Zero shellcheck warnings**
- **Function Length:** Screen length (~50 lines max)
- **Single Responsibility:** One function, one job
- **DRY Principle:** Extract repeated logic to functions

### Testing Standards

- **Framework:** BATS (Bash Automated Testing System)
- **Coverage:** Test all functions, success/failure paths, edge cases
- **Structure:** Unit, Integration, System test suites
- **CI/CD:** All tests must pass before merging

### Git Standards

- **Branching:** `feature/`, `bugfix/`, `hotfix/` prefixes
- **Commit Messages:** Conventional Commits format
- **PR Template:** Describe changes, testing, breaking changes

## Adding New Standards

When adding new standards:

1. Create a new file in this directory
2. Update this README with a reference
3. Get team approval
4. Update existing code to comply
5. Document rationale for the standard

## Enforcement

- **Pre-commit hooks** (if configured)
- **CI/CD checks** for shellcheck, shfmt, bats
- **Code review** for style guidelines
- **Linting** on all shell files

## Resources

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Bash Pitfalls](http://mywiki.wooledge.org/BashPitfalls)
- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
