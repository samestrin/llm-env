# Plan Documentation References

**Created:** January 18, 2026 05:27:14PM
**Plan:** [../plan.md](../plan.md)
**Grounded Against:** ../codebase-discovery.json, .planning/specifications/

---

## Priority Legend

- **[CRITICAL]** - Must read before starting implementation
- **[IMPORTANT]** - Should review during development
- **[REFERENCE]** - Consult as needed

---

## Documentation Files

| File | Priority | Description |
|------|----------|-------------|
| [architecture-bash-compat.md](architecture-bash-compat.md) | [CRITICAL] | Bash 3.2 compatibility layer, INI config parsing, wrapper functions, data structures pattern |
| [tdd-testing-strategy.md](tdd-testing-strategy.md) | [CRITICAL] | RED-GREEN-REFACTOR cycle, BATS framework usage, quality standards |
| [coding-standards-security.md](coding-standards-security.md) | [IMPORTANT] | Naming conventions, function design, security, variable masking for ANTHROPIC_* variables |
| [git-workflow-quality.md](git-workflow-quality.md) | [REFERENCE] | TDD commit pattern, Conventional Commits, shellcheck/shfmt tools |

---

## Recommended Reading Order

For Anthropic protocol support implementation:

1. **Start with [architecture-bash-compat.md](architecture-bash-compat.md)** - Understand the Bash 3.2 compatibility layer and wrapper functions that must be used for the new `PROVIDER_PROTOCOLS` array
2. **Review [tdd-testing-strategy.md](tdd-testing-strategy.md)** - Learn the RED-GREEN-REFACTOR cycle and BATS testing patterns
3. **Read [coding-standards-security.md](coding-standards-security.md)** - Apply naming conventions, security practices, and variable masking for `ANTHROPIC_*` variables
4. **Reference [git-workflow-quality.md](git-workflow-quality.md)** during development for commit format and tooling

---

## Source Attribution

All documentation is grounded in:
- **Original Requirements:** [../original-requirements.md](../original-requirements.md)
- **Plan:** [../plan.md](../plan.md)
- **Codebase Discovery:** [../codebase-discovery.json](../codebase-discovery.json)
- **Architecture:** [.planning/specifications/architecture.md](../../specifications/architecture.md)
- **Implementation Standards:** [.planning/specifications/implementation-standards.md](../../specifications/implementation-standards.md)
- **Coding Standards:** [.planning/specifications/coding-standards.md](../../specifications/coding-standards.md)
- **Packages:**
  - [.planning/specifications/packages/bats.md](../../specifications/packages/bats.md)
  - [.planning/specifications/packages/shellcheck.md](../../specifications/packages/shellcheck.md)
  - [.planning/specifications/packages/shfmt.md](../../specifications/packages/shfmt.md)
- **Git Strategy:** [.planning/specifications/git-strategy.md](../../specifications/git-strategy.md)

---

## Quick Start: Implementation Sequence

Following the TDD approach:

1. **Write Tests:** Create BATS tests for protocol parsing behavior
   ```bash
   test: add failing bats test for protocol parsing
   ```

2. **Implement Config Parsing:** Add `protocol` case to `load_config()` and `PROVIDER_PROTOCOLS` array
   ```bash
   feat(config): parse protocol field from provider config
   ```

3. **Implement Variable Export:** Update `cmd_set()` for OpenAI vs Anthropic variables
   ```bash
   feat(set): export ANTHROPIC_* variables for anthropic protocol
   ```

4. **Apply Variable Masking:** Extend `cmd_show()` with `mask()` for ANTHROPIC_* variables
   ```bash
   feat(show): mask ANTHROPIC_API_KEY and ANTHROPIC_AUTH_TOKEN
   ```

5. **Refactor and Clean Up:** Improve readability, extract helper functions
   ```bash
   refactor(config): extract protocol validation to helper function
   ```

6. **Quality Gates:** Ensure all changes pass:
   - `shellcheck **/*.sh` - zero warnings
   - `shfmt -d .` - consistent formatting
   - `bats tests/` - all tests pass

---

**Navigation:** [← Back to Plan](../README.md)
