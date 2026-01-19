# Sprint 1.0: Anthropic Protocol Support

---
executor: /execute-sprint
context_recovery: On context compaction, read .planning/sprints/active/1.0_anthropic_protocol_support/.context/context.env for phase state. Resume at first unchecked phase below.
---

**Directions:** Work through Sprint 1.0 step-by-step. Complete each step, check off work immediately. After completing a phase, proceed to the next without waiting.

Before each phase, review `/CLAUDE.md` (or AGENTS.md).

---

## Overview

This sprint implements protocol support for Anthropic API in the `llm-env` tool, extending its capabilities from OpenAI-compatible only to a universal AI environment switcher. The implementation involves modifying the bash-based `llm-env` script to parse a new `protocol` configuration field, export protocol-specific variables, and handle protocol-aware API testing.

**Key Deliverables:**
- Protocol configuration parsing with backward compatibility
- Protocol-specific variable export (OpenAI and Anthropic)
- Protocol-aware API testing with correct authentication headers
- Display updates (protocol column, credential masking)

**Total ACs:** 17 across 4 stories
- **Story 01:** Protocol Configuration Parsing (4 ACs)
- **Story 02: Protocol-Specific Variable Export (6 ACs)
- **Story 03:** Protocol-Aware API Testing (4 ACs)
- **Story 04:** Protocol Information Display (3 ACs)

**Complexity Score:** 21/60 points (Medium Sprint)
**Estimated Duration:** 5-9 days

---

## TDD Strategy

Based on the sprint design complexity analysis:
- **Phase 1:** Moderate mode (4 ACs, 6 points) - Configuration parsing requires careful Bash 3.2 compatibility
- **Phase 2:** Moderate mode (5 ACs, 8 points) - Variable export has integration complexity
- **Phase 3:** Moderate mode (4 ACs, 4 points) - API testing with external dependencies
- **Phase 4:** Pragmatic mode (3 ACs, 3 points) - Display updates are straightforward
- **Phase 5:** QA phase - No development work

**Adversarial Mode:** ENABLED - Each GREEN phase will be followed by a hostile code review

**Testing Framework:** BATS (Bash Automated Testing System)
- Test location: `tests/unit/test_protocols.bats`, `tests/integration/`
- Naming convention: `.<test_description>() { ... }`

---

## About This Document

| Document | Purpose |
|----------|---------|
| [sprint-design.md](plan/sprint-design.md) | Architecture, decomposition, test strategy |
| [original-requirements.md](plan/original-requirements.md) | User's actual request (source of truth) |
| [user-stories/](plan/user-stories/) | Feature requirements |
| [acceptance-criteria/](plan/acceptance-criteria/) | Validation requirements with DoD |

---

## Sprint Conventions

### Testing Tiers
| Tier | When | Command Pattern |
|------|------|-----------------|
| T1: Focused | After each small change | `bats --test-path-pattern="<test_name>"` |
| T2: Module | After completing element | `bats tests/unit/test_protocols.bats` |
| T3: Full | DoD validation, pre-commit | `bats tests/` |

### DoD Verification Checklist
1. **Tests (T3):** All BATS tests passing
2. **Coverage:** N/A for bash (use test coverage percentage)
3. **Lint:** Zero shellcheck warnings
4. **Format:** Consistent shfmt formatting
5. **Build:** N/A for bash script

### DoD Report Template
```
Story-{N} DoD Complete
Auto: {X}/5 | Story-Specific: {Y}/{Z}
Manual Review: [ ] Code reviewed
```

### Commit Process
```bash
git add .
git commit -m "<type>(<scope>): <message>"
```

Commit types:
- `feat` - New feature
- `refactor` - Code improvement without behavior change
- `fix` - Bug fix
- `docs` - Documentation only
- `test` - Adding or updating tests
- `chore` - Maintenance tasks

---

## Development Standards

### Bash Standards
- **Compatibility:** Must work with Bash 3.2+ (macOS default)
- **Associative Arrays:** Use `compat_assoc_set()` and `compat_assoc_get()` wrapper functions for Bash 3.2 compatibility
- **Quoting:** Always quote variable expansions to prevent word splitting
- **Error Handling:** Use `set -u` to catch undefined variables in sourced contexts

### Coding Standards
- **Naming:** Use snake_case for variables and functions
- **Comments:** Explain WHY, not WHAT
- **Functions:** Keep under 50 lines when possible
- **Consistency:** Follow existing patterns in llm-env script

### Git Strategy
- **Branch:** `feature/1.0_anthropic_protocol_support`
- **PR Title:** Use conventional commits
- **Squash:** Commit frequently during TDD, squash before PR

---

## External Resources

### Critical Documentation
- **Architecture & Bash Compatibility** 🔴 CRITICAL
- **TDD & Testing Strategy** 🔴 CRITICAL
- **Coding Standards & Security** 🟡 IMPORTANT
- **Git Workflow & Quality Tools** 🟢 REFERENCE

### Key Code Patterns
- **Bash 3.2 Compatibility:** Patterns at llm-env:236-288
- **INI Config Parsing:** Patterns at llm-env:309-380
- **Variable Masking:** `mask()` function at llm-env:513-532

---

## Sprint Phases

**REMINDER:** Working on acceptance-criteria. Each AC must be tested independently.

---

## Phase 1: Configuration Layer (Foundation)

**REMINDER:** Working on acceptance-criteria. Each AC must be tested independently.

**Purpose:** Establish protocol configuration parsing and storage infrastructure
**Estimated Effort:** 1-2 days
**Dependency:** None

### 1.1 [x] **[🟢 GREEN - Default Protocol Values](plan/user-stories/01-protocol-configuration.md)**

**Mode:** Moderate | **AC:** [01-02 Default Protocol Values](plan/acceptance-criteria/01-02-default-protocol-values.md)

**RED Phase (Tests):**
1. Write test: Config without protocol field defaults to "openai"
2. Write test: Empty provider section defaults to "openai"
3. Write test: Backward compatibility - existing configs work unchanged

**GREEN Phase (Implementation):**
1. Modify `load_config()` to add default protocol logic
2. Implement: `PROVIDER_PROTOCOLS[provider]` defaults to "openai" when not specified
3. Run tests (T1 after each change)
4. Verify all passing (T2)
5. COMMIT: `git commit -m "feat(config): add default protocol to openai"`

**Files:** `llm-env`, `tests/unit/test_protocols.bats` | **Duration:** ~30 min

### 1.1.A [x] **[🎯 ADVERSARIAL REVIEW](plan/user-stories/01-protocol-configuration.md)**

**Changed Files:** `llm-env`

**Review as hostile critic - find every flaw:**
- [x] SECURITY: Can malicious config inject shell commands via protocol field?
- [x] EDGE CASES: Empty config, malformed sections, trailing whitespace?
- [x] ERROR HANDLING: What happens if config is corrupted?
- [x] PERFORMANCE: Does defaulting add measurable startup delay?

**Findings documented in:** `plan/clarifications/tech-debt-captured.md`

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 8 |
| LOW | 1 |

✅ **Adversarial review passed** - No CRITICAL/HIGH issues. 9 MEDIUM/LOW items logged to tech-debt.

### 1.2 [x] **[🔵 REFACTOR](plan/user-stories/01-protocol-configuration.md)**

1. Fix CRITICAL/HIGH issues from 1.1.A (if any) - **Not applicable**
2. Address MEDIUM severity items from tech-debt where practical
3. Improve code quality - extract defaulting logic to function
4. Ensure Bash 3.2 compatibility
5. Validate all tests still pass (T3)
6. COMMIT: `git commit -m "refactor(config): clean up default protocol logic"`

**Duration:** ~20 min

**Refactoring completed:**
- Added `normalize_protocol()` helper function (Bash 3.2 compatible parameter expansion)
- Added `apply_default_protocols()` function to handle defaulting logic
- Reduced subprocess calls by using bash built-in parameter expansion for whitespace trimming
- Only applies default protocol to enabled providers (efficiency improvement)
- Extracted defaulting logic into reusable function for maintainability

### 1.3 [ ] **[🟢 GREEN + 🔵 REFACTOR - Protocol Field Parsing](plan/user-stories/01-protocol-configuration.md)**

**Mode:** Moderate | **AC:** [01-01 Protocol Field Parsing](plan/acceptance-criteria/01-01-protocol-field-parsing.md)

**RED Phase (Tests):**
1. Write test: Config with protocol=anthropic is parsed correctly
2. Write test: Protocol field with extra whitespace is trimmed
3. Write test: Protocol values are normalized to lowercase
4. Write test: Malformed config lines are skipped with warning

**GREEN + REFACTOR Phase (Implementation):**
1. Extend config parser to recognize `protocol` key
2. Implement trimming and lowercasing
3. Add warning for malformed lines
4. Run tests (T1)
5. Commit: `git commit -m "feat(config): parse protocol field with validation"`

**Files:** `llm-env`, `tests/unit/test_protocols.bats` | **Duration:** ~45 min

### 1.4 [ ] **[🟢 GREEN + 🔵 REFACTOR - PROVIDER_PROTOCOLS Storage](plan/user-stories/01-protocol-configuration.md)**

**Mode:** Moderate | **AC:** [01-03 Protocol Storage](plan/acceptance-criteria/01-03-protocol-storage-provider-protocols.md)

**RED Phase (Tests):**
1. Write test: Protocol value is stored in PROVIDER_PROTOCOLS
2. Write test: Protocol can be retrieved via compat_assoc_get
3. Write test: Multiple providers have separate protocol values
4. Write test: Provider names with special characters work

**GREEN + REFACTOR Phase (Implementation):**
1. Add `PROVIDER_PROTOCOLS` associative array declaration
2. Implement storage using compat_assoc_set_wrapper
3. Implement retrieval using compat_assoc_get_wrapper
4. Run tests (T1)
5. Commit: `git commit -m "feat(config): add PROVIDER_PROTOCOLS storage with bash-3.2 compatibility"`

**Files:** `llm-env`, `tests/unit/test_protocols.bats` | **Duration:** ~60 min

### 1.5 [ ] **[🟢 GREEN + 🔵 REFACTOR - Invalid Protocol Validation](plan/user-stories/01-protocol-configuration.md)**

**Mode:** Moderate | **AC:** [01-04 Invalid Protocol Validation](plan/acceptance-criteria/01-04-invalid-protocol-validation.md)

**RED Phase (Tests):**
1. Write test: Valid protocol "anthropic" accepted
2. Write test: Valid protocol "openai" accepted
3. Write test: Case variations normalized to lowercase
4. Write test: Invalid protocol defaults to "openai" with warning
5. Write test: Empty protocol defaults to "openai" with warning

**GREEN + REFACTOR Phase (Implementation):**
1. Add protocol validation (whitelist: "openai", "anthropic")
2. Generate warning for invalid values
3. Default to "openai" on invalid
4. Run tests (T1)
5. Commit: `git commit -m "feat(config): add protocol validation with whitelist"`

**Files:** `llm-env`, `tests/unit/test_protocols.bats` | **Duration:** ~30 min

**Phase 1 Exit Criteria:**
- [ ] All Story 01 unit tests passing
- [ ] Config files with/without protocol field parse correctly
- [ ] Invalid protocol values default to `openai` with warning
- [ ] shellcheck and shfmt pass

---

## Phase 2: Variable Export Logic

**REMINDER:** Working on acceptance-criteria. Each AC must be tested independently.

**Purpose:** Implement protocol-specific variable export and cleanup
**Estimated Effort:** 2-3 days
**Dependency:** Phase 1

### 2.1 [ ] **[🟢 GREEN + 🔵 REFACTOR - OpenAI Protocol Export](plan/user-stories/02-variable-switching.md)**

**Mode:** Moderate | **AC:** [02-01 OpenAI Protocol Export](plan/acceptance-criteria/02-01-openai-protocol-export.md)

**RED Phase (Tests):**
1. Write test: OPENAI_API_KEY exported correctly
2. Write test: OPENAI_BASE_URL exported correctly
3. Write test: OPENAI_MODEL exported correctly
4. Write test: Partial config exports only available variables

**GREEN + REFACTOR Phase (Implementation):**
1. Modify `cmd_set()` to read protocol from PROVIDER_PROTOCOLS
2. Implement OpenAI export branch
3. Handle partial configuration
4. Run tests (T1)
5. Commit: `git commit -m "feat(export): add OpenAI protocol variable export"`

**Files:** `llm-env`, `tests/integration/` | **Duration:** ~45 min

### 2.2 [ ] **[🟢 GREEN + 🔵 REFACTOR - Anthropic Protocol Export](plan/user-stories/02-variable-switching.md)**

**Mode:** Moderate | **AC:** [02-02 Anthropic Protocol Export](plan/acceptance-criteria/02-02-anthropic-protocol-export.md)

**RED Phase (Tests):**
1. Write test: ANTHROPIC_API_KEY exported correctly
2. Write test: ANTHROPIC_AUTH_TOKEN exported correctly
3. Write test: ANTHROPIC_BASE_URL exported correctly
4. Write test: ANTHROPIC_MODEL exported correctly
5. Write test: Partial config exports only available variables

**GREEN + REFACTOR Phase (Implementation):**
1. Add Anthropic export branch to `cmd_set()`
2. Handle partial configuration
3. Ensure variables are exported, not printed
4. Run tests (T1)
5. Commit: `git commit -m "feat(export): add Anthropic protocol variable export"`

**Files:** `llm-env`, `tests/integration/` | **Duration:** ~45 min

### 2.3 [ ] **[🟢 GREEN + 🔵 REFACTOR - Protocol Cleanup](plan/user-stories/02-variable-switching.md)**

**Mode:** Moderate | **AC:** [02-03 Protocol Cleanup](plan/acceptance-criteria/02-03-protocol-cleanup.md)

**RED Phase (Tests):**
1. Write test: Switching openai→anthropic unsets OPENAI_* variables
2. Write test: Switching anthropic→openai unsets ANTHROPIC_* variables
3. Write test: Environment clean after switch (grep shows only active)
4. Write test: Multiple switches maintain clean environment
5. Write test: Externally set variables are properly unset

**GREEN + REFACTOR Phase (Implementation):**
1. Add cleanup logic to unset inactive protocol variables
2. Ensure all protocol variables cleared on switch
3. Run tests (T1)
4. Commit: `git commit -m "feat(export): add protocol cleanup on switch"`

**Files:** `llm-env`, `tests/integration/` | **Duration:** ~45 min

### 2.4 [ ] **[🟢 GREEN + 🔵 REFACTOR - Confirmation Message](plan/user-stories/02-variable-switching.md)**

**Mode:** Moderate | **AC:** [02-04 Protocol Confirmation](plan/acceptance-criteria/02-04-protocol-confirmation-message.md)

**RED Phase (Tests):**
1. Write test: OpenAI message identifies "openai" protocol
2. Write test: Anthropic message identifies "anthropic" protocol
3. Write test: Message lists exported variables
4. Write test: Message does NOT print actual variable values

**GREEN + REFACTOR Phase (Implementation):**
1. Update confirmation message to include protocol
2. List only exported variables
3. Ensure no sensitive values displayed
4. Run tests (T1)
5. Commit: `git commit -m "feat(export): add protocol to confirmation message"`

**Files:** `llm-env`, `tests/integration/` | **Duration:** ~20 min

### 2.5 [ ] **[🟢 GREEN + 🔵 REFACTOR - Sourced Script Behavior](plan/user-stories/02-variable-switching.md)**

**Mode:** Moderate | **AC:** [02-05 Sourced Script Behavior](plan/acceptance-criteria/02-05-sourced-script-behavior.md)

**RED Phase (Tests):**
1. Write test: Exported variables persist in parent shell
2. Write test: No set -e interferes with operations
3. Write test: Multiple set commands work in same session

**GREEN + REFACTOR Phase (Implementation):**
1. Verify export behavior works in sourced mode
2. Ensure no subshell spawn in normal path
3. Run tests (T1)
4. Commit: `git commit -m "test(export): verify sourced script behavior"`

**Files:** `tests/integration/` | **Duration:** ~20 min

**Phase 2 Exit Criteria:**
- [ ] All Story 02 integration tests passing
- [ ] Protocol switches export/cleanup correct variables
- [ ] No variable leakage between protocols
- [ ] Confirmation messages include protocol information

---

## Phase 3: API Testing Protocol Support

**REMINDER:** Working on acceptance-criteria. Each AC must be tested independently.

**Purpose:** Implement protocol-aware authentication and endpoint routing
**Estimated Effort:** 1-2 days
**Dependency:** Phase 1, Phase 2

### 3.1 [ ] **[🟢 GREEN + 🔵 REFACTOR - OpenAI Authentication](plan/user-stories/03-api-testing.md)**

**Mode:** Moderate | **AC:** [03-01 OpenAI Auth Header](plan/acceptance-criteria/03-01-openai-authentication-header.md)

**RED Phase (Tests):**
1. Write test: OpenAI test uses Authorization: Bearer header
2. Write test: Bearer format includes space after "Bearer"
3. Write test: Valid credentials return success

**GREEN + REFACTOR Phase (Implementation):**
1. Modify `cmd_test()` protocol-aware header construction
2. Implement OpenAI: `Authorization: Bearer $OPENAI_API_KEY`
3. Run tests (T1)
4. Commit: `git commit -m "feat(test): add OpenAI protocol authentication"`

**Files:** `llm-env`, `tests/integration/` | **Duration:** ~30 min

### 3.2 [ ] **[🟢 GREEN + 🔵 REFACTOR - Anthropic Authentication](plan/user-stories/03-api-testing.md)**

**Mode:** Moderate | **AC:** [03-02 Anthropic Auth Header](plan/acceptance-criteria/03-02-anthropic-authentication-header.md)

**RED Phase (Tests):**
1. Write test: Anthropic test uses x-api-key header
2. Write test: No Bearer prefix for Anthropic
3. Write test: Valid credentials return success
4. Write test: No Authorization header sent

**GREEN + REFACTOR Phase (Implementation):**
1. Add Anthropic: `x-api-key: $ANTHROPIC_API_KEY` header
2. Ensure Authorization header not sent
3. Run tests (T1)
4. Commit: `git commit -m "feat(test): add Anthropic protocol authentication"`

**Files:** `llm-env`, `tests/integration/` | **Duration:** ~30 min

### 3.3 [ ] **[🟢 GREEN + 🔵 REFACTOR - Endpoint Routing](plan/user-stories/03-api-testing.md)**

**Mode:** Moderate | **AC:** [03-03 Test Endpoint Routing](plan/acceptance-criteria/03-03-test-endpoint-routing.md)

**RED Phase (Tests):**
1. Write test: OpenAI uses correct endpoint path
2. Write test: Anthropic uses correct endpoint path
3. Write test: Provider-specific endpoint override works
4. Write test: Trailing slash handled correctly
5. Write test: Unknown protocol falls back gracefully

**GREEN + REFACTOR Phase (Implementation):**
1. Add protocol-aware endpoint path selection
2. Implement provider-specific override
3. Handle trailing slashes
4. Run tests (T1)
5. Commit: `git commit -m "feat(test): add protocol-aware endpoint routing"`

**Files:** `llm-env`, `tests/integration/` | **Duration:** ~45 min

### 3.4 [ ] **[🟢 GREEN + 🔵 REFACTOR - Result Messaging](plan/user-stories/03-api-testing.md)**

**Mode:** Moderate | **AC:** [03-04 Test Result Messaging](plan/acceptance-criteria/03-04-test-result-messaging.md)

**RED Phase (Tests):**
1. Write test: Success messages include provider name and protocol
2. Write test: Failure messages include protocol and error details
3. Write test: Exit code 0 for success, non-zero for failure
4. Write test: Protocol always displayed in output

**GREEN + REFACTOR Phase (Implementation):**
1. Update test result messages with protocol info
2. Ensure proper exit codes
3. Run tests (T1)
4. Commit: `git commit -m "feat(test): add protocol to test result messages"`

**Files:** `llm-env`, `tests/integration/` | **Duration:** ~20 min

**Phase 3 Exit Criteria:**
- [ ] All Story 03 integration tests passing
- [ ] Both protocols authenticate with correct headers
- [ ] Test endpoint routing uses protocol-specific paths
- [ ] Result messages clearly indicate protocol used

---

## Phase 4: Display and Security Updates

**REMINDER:** Working on acceptance-criteria. Each AC must be tested independently.

**Purpose:** Update user-facing display commands for protocol information and credential masking
**Estimated Effort:** 0.5-1 day
**Dependency:** Phase 1, Phase 2

### 4.1 [ ] **[⚡ TDD - Protocol Column in List](plan/user-stories/04-protocol-display.md)**

**Mode:** Pragmatic | **AC:** [04-01 Protocol Column](plan/acceptance-criteria/04-01-protocol-list-display.md)

1. **RED:** Write failing test for protocol column in list output
2. **GREEN:** Modify `cmd_list()` to display protocol column, verify tests pass (T1)
3. **COMMIT:** `git commit -m "feat(list): add protocol column to list display"`
4. **REFACTOR:** Improve column formatting if needed (T1)
5. **COMMIT:** `git commit -m "refactor(list): improve protocol column formatting"`

**Files:** `llm-env`, `tests/unit/test_protocols.bats` | **Duration:** ~30 min

### 4.2 [ ] **[⚡ TDD - Anthropic Credential Masking](plan/user-stories/04-protocol-display.md)**

**Mode:** Pragmatic | **AC:** [04-02 Credential Masking](plan/acceptance-criteria/04-02-anthropic-credential-masking.md)

1. **RED:** Write failing tests for ANTHROPIC_API_KEY and ANTHROPIC_AUTH_TOKEN masking
2. **GREEN:** Apply mask() to ANTHROPIC_* variables in `cmd_show()`, verify tests pass (T1)
3. **COMMIT:** `git commit -m "feat(show): mask Anthropic credentials in display"`
4. **REFACTOR:** Ensure masking format matches existing (••••last4) (T1)
5. **COMMIT:** `git commit -m "refactor(show): normalize credential masking format"`

**Files:** `llm-env`, `tests/unit/test_protocols.bats` | **Duration:** ~20 min

### 4.3 [ ] **[⚡ TDD - Empty Value Display](plan/user-stories/04-protocol-display.md)**

**Mode:** Pragmatic | **AC:** [04-03 Empty Value Display](plan/acceptance-criteria/04-03-empty-value-display.md)

1. **RED:** Write failing tests for empty/null value display as "∅"
2. **GREEN:** Handle empty values in `cmd_show()`, verify tests pass (T1)
3. **COMMIT:** `git commit -m "feat(show): display ∅ for empty values"`
4. **REFACTOR:** Handle whitespace-only values (T1)
5. **COMMIT:** `git commit -m "refactor(show): improve empty value handling"`

**Files:** `llm-env`, `tests/unit/test_protocols.bats` | **Duration:** ~15 min

**Phase 4 Exit Criteria:**
- [ ] All Story 04 unit tests passing
- [ ] `llm-env list` shows protocol column
- [ ] `llm-env show` masks Anthropic credentials
- [ ] Empty values display as "∅"

---

## Phase 5: Integration and Quality Assurance

**REMINDER:** Working on acceptance-criteria. Each AC must be tested independently.

**Purpose:** End-to-end testing, documentation updates, and sprint finalization
**Estimated Effort:** 0.5-1 day
**Dependency:** Phases 1-4

### 5.1 [ ] **Run Full Test Suite**

1. Run all BATS tests: `bats tests/`
2. Verify all 16 AC tests passing
3. Document any failures
4. Fix critical failures immediately
5. Log non-critical issues as tech debt

**Duration:** ~30 min

### 5.2 [ ] **Shell Linting**

1. Run `shellcheck llm-env`
2. Fix any warnings (especially SC2296, SC2155)
3. Run `shfmt -w llm-env`
4. Verify formatting consistency

**Duration:** ~15 min

### 5.3 [ ] **Cross-Platform Testing**

1. Test on macOS (bash 3.2)
2. Test on Linux (bash 4+)
3. Verify Bash 3.2 compatibility for all changes
4. Document any platform-specific issues

**Duration:** ~30 min

### 5.4 [ ] **Update Documentation**

1. Add Anthropic provider example to `config/llm-env.conf`:
   ```ini
   [anthropic]
   api_key = ANTHROPIC_API_KEY
   auth_token = ANTHROPIC_AUTH_TOKEN
   base_url = https://api.anthropic.com
   model = claude-3-opus-20240229
   protocol = anthropic
   ```
2. Update project README.md with protocol examples
3. Verify documentation examples work

**Duration:** ~30 min

### 5.5 [ ] **Backward Compatibility**

1. Test with existing config (no protocol field)
2. Verify defaults to "openai" behavior
3. Test with mixed OpenAI/Anthropic configs
4. Verify no breaking changes

**Duration:** ~20 min

### 5.6 [ ] **Verification Checklist**

- [ ] All 16 ACs verified complete
- [ ] All tests passing (T3)
- [ ] Zero shellcheck warnings
- [ ] Consistent shfmt formatting
- [ ] Backward compatibility verified
- [ ] Documentation updated

**Phase 5 Exit Criteria:**
- [ ] All 16 ACs verified complete
- [ ] All tests passing
- [ ] Zero linting warnings
- [ ] Backward compatibility verified
- [ ] Documentation updated

---

## Pre-Final Phase: Learning Capture (Feature Plans Only)

**REMINDER:** Use the skill memory system to capture any important learnings from this sprint for future reuse.

**Note:** This phase is generated for feature plans only. Non-feature plans (bugfix, tech-debt, infrastructure) skip this phase.

### Learning Capture [ ] **Analyze Implementation for Learnings**

**Purpose:** Identify implicit decisions, patterns, and conventions discovered during implementation to capture as project memories.

#### Step 1: Gather Implementation Context

Run: `git diff main...HEAD --stat`

Review the diff to understand what was changed in this sprint.

#### Step 2: Analyze for Patterns

Look for these learning categories:
- **Architectural decisions** - Why code is structured this way
- **Pattern choices** - Consistent patterns across files
- **Integration approaches** - How components connect
- **Debugging insights** - Non-obvious problem solutions
- **Convention discoveries** - Project-specific naming or organization

#### Step 3: Store Confirmed Learnings

For each confirmed learning:
1. Generate memory ID: `mem-YYYYMMDD-<hash>`
2. Use `/memory --add="QUESTION" --answer="ANSWER"` to store
3. Update sprint-memories.yaml with created ID
4. Display: "💾 Captured: $ENTRY_ID"

---

## Final Phase: Validation & PR

### Validation Checklist
- [ ] All tests passing (T3)
- [ ] Coverage meets threshold
- [ ] Lint/format clean
- [ ] Build succeeds

### Optional: Targeted Mutation Testing
If high-risk code was modified, consider running mutation testing on CHANGED FILES ONLY:
```
# Mutation testing not configured for this project
# Install mutmut: pip3 install mutmut
# Run: mutmut run --paths-to-mutate llm-env
```
**WARNING:** Do NOT run full codebase mutation - it can take hours. Target specific files.

### Drift Analysis
Compare implementation against [original-requirements.md](plan/original-requirements.md)

### Create PR

1. Create PR with summary
2. Include implementation notes
3. Reference sprint design document

---

**Branch:** `feature/1.0_anthropic_protocol_support`
**Complexity:** 21/60 points (Medium)
**Phases:** 5
**Location:** `.planning/sprints/active/1.0_anthropic_protocol_support/`
