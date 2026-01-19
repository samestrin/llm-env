# llm-env Specifications

This directory contains technical specifications for the llm-env project.

## Contents

| Directory/File | Description |
|----------------|-------------|
| [architecture.md](architecture.md) | System architecture, design patterns, data flow |
| [packages/](packages/) | Third-party package documentation |
| [standards/](standards/) | Coding and implementation standards |
| [coding-standards.md](coding-standards.md) | Code style and formatting guidelines |
| [implementation-standards.md](implementation-standards.md) | TDD approach and quality standards |
| [git-strategy.md](git-strategy.md) | Git workflow and commit conventions |

## Quick Reference

### Architecture

- **Core:** Single Bash script (~1500 lines) with zero runtime dependencies
- **Compatibility:** Bash 3.2+ (macOS default) through wrapper functions
- **Design:** Unix philosophy, associative array wrappers, sourced entry point

### Packages (Development Only)

| Package | Purpose |
|---------|---------|
| [BATS](packages/bats.md) | Testing framework |
| [shellcheck](packages/shellcheck.md) | Static analysis |
| [shfmt](packages/shfmt.md) | Code formatter |

### Standards

Follow these when contributing:
- Zero shellcheck warnings
- Functions <50 lines
- 2-space indentation
- Clear commit messages (Conventional Commits)

## Documentation Structure

```
.planning/specifications/
├── README.md                  # This file
├── architecture.md            # System architecture
├── coding-standards.md        # Code style guidelines
├── implementation-standards.md # TDD and quality standards
├── git-strategy.md            # Git workflow
├── packages/                  # Third-party package docs
│   ├── README.md
│   ├── bats.md
│   ├── shellcheck.md
│   └── shfmt.md
└── standards/                 # Standards reference
    └── README.md
```

## For Contributors

1. Read [coding-standards.md](coding-standards.md) before making changes
2. Review [implementation-standards.md](implementation-standards.md) for TDD approach
3. Check [packages/](packages/) for tool documentation
4. Follow [git-strategy.md](git-strategy.md) for commits and PRs

## Links

- [Project README](../../README.md)
- [User Documentation](../../docs/)
- [Test Documentation](../../tests/README.md)
