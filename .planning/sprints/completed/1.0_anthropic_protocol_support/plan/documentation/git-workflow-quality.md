# Git Workflow & Quality Tools [REFERENCE]

## Overview

This document outlines the git workflow strategy and quality tools used for the Anthropic protocol support feature plan. It covers branching conventions, commit patterns, pull request processes, and static analysis tools for maintaining code quality.

> Source: [git-strategy.md:Branching Strategy]

## Branch Format for Features

Feature branches follow a specific naming convention that includes issue reference and description:

**Format:** `feature/<issue-id>-<short-description>`

**Examples:**
- `feature/42-backup-script`
- `feature/101-add-logging`

> Source: [git-strategy.md:Feature Branches]

## TDD Commit Pattern

The Test-Driven Development commit pattern follows the Red-Green-Refactor cycle:

- **RED:** `test: add failing bats test for [behavior]`
- **GREEN:** `feat: implement [behavior]`
- **REFACTOR:** `refactor: improve [function] logic`

> Source: [git-strategy.md:TDD Commit Pattern]

## Conventional Commit Types

Commit messages follow Conventional Commits format with specific semantic types:

| Type | Purpose |
|------|---------|
| **feat** | New script or function |
| **fix** | Bug fix in script |
| **refactor** | Code restructuring (no behavior change) |
| **test** | Adding or updating bats tests |
| **docs** | Documentation updates (README, comments) |
| **style** | Formatting changes (shfmt) |
| **chore** | Maintenance (updating .gitignore, CI config) |
| **ci** | CI/CD pipeline changes |

**Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

> Source: [git-strategy.md:Commit Message Format]

## Pull Request Process

### Creating PRs

1. **Lint First:** Ensure `shellcheck` passes locally
2. **Format:** Run `shfmt -w .`
3. **Test:** Ensure `bats` tests pass
4. **Description:** Explain changes and provide usage examples

### Review Guidelines

- **Safety:** Check for unquoted variables and lack of error handling (`set -e`)
- **Clarity:** Are variable names descriptive?
- **Idempotency:** Will this break if run twice?

> Source: [git-strategy.md:Pull Request Process]

## Quality Tools

### shellcheck - Static Analysis

**Overview:**
- Static analysis tool for shell scripts
- Provides warnings and suggestions for bash/sh scripts
- Detects syntax errors, bugs, code style issues, portability problems, typographical mistakes, and security best practices

**Usage:**
```bash
# Check a single file
shellcheck llm-env

# Check all shell files
shellcheck **/*.sh

# Generate format for CI
shellcheck -f gcc llm-env
```

**CI Integration:**
```yaml
- name: Lint with shellcheck
  run: |
    shellcheck **/*.sh
```

**Common Rules Used in llm-env:**
- **SC2296** - Parameter Expansion in Zsh (used in bash/zsh compatibility layer)
- **SC2155** - Declare and Assign Separately (when variables need declaration before assignment)
- **SC2034** - Variable Appears Unused (for compatibility arrays referenced by wrapper functions)

**Best Practices:**
1. Zero warnings - All shell scripts should pass without warnings
2. Fix or ignore - Use `# shellcheck disable=SCXXXX` only when necessary
3. CI gating - Fail builds on new shellcheck warnings

> Source: [shellcheck.md]

### shfmt - Shell Formatter

**Overview:**
- Shell parser, formatter, and interpreter
- Reformats shell scripts to consistent style
- Improves readability and maintainability

**Usage:**
```bash
# Format a file (in-place)
shfmt -w llm-env

# Format all shell files
shfmt -w **/*.sh

# Check if files are formatted (dry run)
shfmt -d **/*.sh
```

**Options Used in llm-env:**

| Option | Purpose |
|--------|---------|
| `-w, -write` | Write result to file instead of stdout |
| `-d, -diff` | Print diff of formatting changes |
| `-s, -simplify` | Simplify the code |
| `-i, -indent` | Number of spaces (llm-env uses 2) |

**CI Integration:**
```yaml
- name: Check formatting
  run: shfmt -d **/*.sh
```

**Best Practices:**
1. Consistent style - All scripts should follow the same formatting
2. Pre-commit hooks - Run shfmt before committing
3. 2-space indentation - Matches project coding standards
4. No trailing whitespace - shfmt handles this automatically

> Source: [shfmt.md]

## Standard Feature Workflow

```bash
## 1. Create feature branch
git checkout main
git pull origin main
git checkout -b feature/1.0-backup-logic

## 2. Make changes with TDD
## RED: Write failing test
git add tests/
git commit -m "test: add failing test for backup rotation"

## GREEN: Make test pass
git add bin/backup.sh
git commit -m "feat(backup): implement rotation logic"

## REFACTOR: Improve code
git add bin/backup.sh
git commit -m "refactor(backup): extract cleanup function"

## 3. Push and create PR
git push -u origin feature/1.0-backup-logic
```

> Source: [git-strategy.md:Workflow Summary]

## Quick Reference

| Aspect | Details |
|--------|---------|
| **Feature Branch Format** | `feature/<issue-id>-<short-description>` |
| **TDD Pattern** | test (RED) → feat (GREEN) → refactor |
| **Lint Tool** | `shellcheck **/*.sh` |
| **Format Tool** | `shfmt -w **/*.sh` |
| **CI Check** | shellcheck must pass before merge |
| **Commit Types** | feat, fix, refactor, test, docs, style, chore, ci |

> Source: [git-strategy.md]
