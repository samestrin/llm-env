# Sprint Design Document

**Plan:** 1.0: Anthropic Protocol Support
**Generated:** January 18, 2026 06:06:42PM
**Sprint Type:** Feature Implementation
**Complexity Level:** Medium

---

## Executive Summary

This sprint implements protocol support for Anthropic API in the `llm-env` tool, extending its capabilities from OpenAI-compatible only to a universal AI environment switcher. The implementation involves modifying the bash-based `llm-env` script to parse a new `protocol` configuration field, export protocol-specific variables, and handle protocol-aware API testing.

**Key Deliverables:**
- Protocol configuration parsing with backward compatibility
- Protocol-specific variable export (OpenAI and Anthropic)
- Protocol-aware API testing with correct authentication headers
- Display updates (protocol column, credential masking)

**Total ACs:** 16 across 4 stories
- **Story 01:** Protocol Configuration Parsing (4 ACs)
- **Story 02:** Protocol-Specific Variable Export (5 ACs)
- **Story 03:** Protocol-Aware API Testing (4 ACs)
- **Story 04:** Protocol Information Display (3 ACs)

---

## Implementation Phases

The sprint is organized into 5 sequential phases based on natural implementation order and dependencies:

### Phase 1: Configuration Layer (Foundation)
**Purpose:** Establish protocol configuration parsing and storage infrastructure
**Estimated Effort:** Medium
**Dependency:** None
**Complexity Score:** 6/12

| AC ID | Title | Effort (S/M/L/XL) | Status |
|-------|-------|-------------------|--------|
| 01-01 | Protocol Field Parsing | S (1) | Pending |
| 01-02 | Default Protocol Values | S (1) | Pending |
| 01-03 | Protocol Storage in PROVIDER_PROTOCOLS | M (3) | Pending |
| 01-04 | Invalid Protocol Validation | S (1) | Pending |

**Phase Tasks:**
1. Modify `load_config()` function (llm-env:309-380) to parse `protocol` field
2. Add `PROVIDER_PROTOCOLS` associative array with Bash 3.2 compatibility wrappers
3. Implement protocol validation (whitelist: `openai`, `anthropic`)
4. Ensure backward compatibility (default to `openai` when not specified)
5. Add example protocol configurations to `config/llm-env.conf`

**Exit Criteria:**
- All Story 01 unit tests passing
- Config files with/without protocol field parse correctly
- Invalid protocol values default to `openai` with warning
- shellcheck and shfmt pass

---

### Phase 2: Variable Export Logic
**Purpose:** Implement protocol-specific variable export and cleanup
**Estimated Effort:** Medium
**Dependency:** Phase 1
**Complexity Score:** 7/12

| AC ID | Title | Effort (S/M/L/XL) | Status |
|-------|-------|-------------------|--------|
| 02-01 | OpenAI Protocol Variable Export | M (2) | Pending |
| 02-02 | Anthropic Protocol Variable Export | M (2) | Pending |
| 02-03 | Protocol Cleanup on Provider Switch | M (2) | Pending |
| 02-04 | Protocol Confirmation Output Message | S (1) | Pending |
| 02-05 | Sourced Script Environment Behavior | S (1) | Pending |

**Phase Tasks:**
1. Modify `cmd_set()` function to read protocol from `PROVIDER_PROTOCOLS`
2. Implement branching logic: export `OPENAI_*` for openai, `ANTHROPIC_*` for anthropic
3. Add cleanup logic to unset variables from inactive protocol
4. Update confirmation message to show active protocol
5. Verify sourced script behavior (no subshell spawn)
6. Modify `cmd_unset()` to clear all protocol variables

**Exit Criteria:**
- All Story 02 integration tests passing
- Protocol switches export/cleanup correct variables
- No variable leakage between protocols
- Confirmation messages include protocol information

---

### Phase 3: API Testing Protocol Support
**Purpose:** Implement protocol-aware authentication and endpoint routing
**Estimated Effort:** Medium
**Dependency:** Phase 1, Phase 2
**Complexity Score:** 5/12

| AC ID | Title | Effort (S/M/L/XL) | Status |
|-------|-------|-------------------|--------|
| 03-01 | OpenAI Protocol Authentication Header | S (1) | Pending |
| 03-02 | Anthropic Protocol Authentication Header | S (1) | Pending |
| 03-03 | Protocol-Aware Test Endpoint Routing | M (2) | Pending |
| 03-04 | Clear Test Result Messaging | S (1) | Pending |

**Phase Tasks:**
1. Modify `cmd_test()` function to read provider protocol
2. Implement OpenAI authentication: `Authorization: Bearer {api_key}`
3. Implement Anthropic authentication: `x-api-key: {api_key}`
4. Add protocol-aware endpoint routing (paths may vary by protocol)
5. Update test result messages to include protocol information

**Exit Criteria:**
- All Story 03 integration tests passing
- Both protocols authenticate with correct headers
- Test endpoint routing uses protocol-specific paths
- Result messages clearly indicate protocol used

---

### Phase 4: Display and Security Updates
**Purpose:** Update user-facing display commands for protocol information and credential masking
**Estimated Effort:** Small
**Dependency:** Phase 1, Phase 2
**Complexity Score:** 3/12

| AC ID | Title | Effort (S/M/L/XL) | Status |
|-------|-------|-------------------|--------|
| 04-01 | Protocol Column in List Display | S (1) | Pending |
| 04-02 | Anthropic Credential Masking | S (1) | Pending |
| 04-03 | Empty Value Display | S (1) | Pending |

**Phase Tasks:**
1. Modify `cmd_list()` to display protocol column from `PROVIDER_PROTOCOLS`
2. Extend `cmd_show()` to apply `mask()` to `ANTHROPIC_API_KEY` and `ANTHROPIC_AUTH_TOKEN`
3. Handle empty/null values with `∅` placeholder
4. Ensure masking format matches existing `mask()` function output (••••last4)

**Exit Criteria:**
- All Story 04 unit tests passing
- `llm-env list` shows protocol column
- `llm-env show` masks Anthropic credentials
- Empty values display as `∅`

---

### Phase 5: Integration and Quality Assurance
**Purpose:** End-to-end testing, documentation updates, and sprint finalization
**Estimated Effort:** Small
**Dependency:** Phases 1-4
**Complexity Score:** 3/12

**Phase Tasks:**
1. Run all BATS tests (16 ACs) - ensure all passing
2. Run shellcheck with zero warnings
3. Run shfmt to ensure consistent formatting
4. Test on both macOS (bash 3.2) and Linux (bash 4+)
5. Update user documentation with protocol examples
6. Add Anthropic provider example to `config/llm-env.conf`
7. Verify backward compatibility with existing configs
8. Final code review and approval

**Exit Criteria:**
- All 16 ACs verified complete
- All tests passing
- Zero linting warnings
- Backward compatibility verified
- Documentation updated

---

## Complexity Analysis by Phase

| Phase | AC Count | S Points | M Points | L Points | XL Points | Total Points | Days Est |
|-------|----------|----------|----------|----------|-----------|--------------|----------|
| Phase 1 | 4 | 3 | 0 | 0 | 0 | 3 | 1-2 |
| Phase 2 | 5 | 2 | 3 | 0 | 0 | 8 | 2-3 |
| Phase 3 | 4 | 2 | 1 | 0 | 0 | 4 | 1-2 |
| Phase 4 | 3 | 3 | 0 | 0 | 0 | 3 | 0.5-1 |
| Phase 5 | QA | 0 | 0 | 0 | 0 | 3 | 0.5-1 |
| **TOTAL** | **16** | **10** | **4** | **0** | **0** | **21** | **5-9** |

**Complexity Score Calculation:**
- S (Small): 1 point per AC with S estimate
- M (Medium): 2 points per AC with M estimate
- L (Large): 3 points per AC with L estimate
- XL (Extra Large): 4 points per AC with XL estimate

**Overall Sprint Complexity:** 21/60 points (35% of max) = **Medium Sprint**

---

## Risk Analysis

### Identified Risks

| ID | Risk | Likelihood | Impact | Severity | Mitigation Strategy |
|----|------|------------|--------|----------|---------------------|
| R-1 | Breaking existing configs without protocol field | Low | High | Medium | Default protocol to `openai` (backward compatibility) |
| R-2 | Bash 3.2 compatibility issues with new array | Low | Medium | Low | Reuse existing `compat_assoc` wrapper functions |
| R-3 | User confusion about which variables are set | Low | Medium | Low | Clear confirmation messages showing protocol |
| R-4 | Variable masking not applied to Anthropic credentials | Low | Medium | Low | Explicit AC and testing for masking behavior |
| R-5 | Protocol state inconsistency after rapid switches | Low | Low | Low | Proper unset/cleanup logic with testing |
| R-6 | Test endpoint path differences cause failures | Low | Medium | Low | Provider-specific endpoint override capability |

### Risk Severity Calculation
- **Low Risk:** R-2, R-3, R-5 (3 risks)
- **Medium Risk:** R-1, R-4, R-6 (3 risks)
- **High Risk:** None (0 risks)

**Overall Risk Assessment:** **Low to Medium**

---

## Technical Deep Dive

### File Modification Summary

| File | Modifications | Lines Changed (Est) | Complexity |
|------|---------------|---------------------|------------|
| `llm-env` | Major - config parsing, exports, testing, display | ~100-150 | High |
| `config/llm-env.conf` | Minor - add Anthropic provider examples | ~10-15 | Low |
| `tests/unit/test_protocols.bats` | New - unit tests for protocol support | ~200-250 | Medium |

### Code Changes by Function

| Function | Phase | Changes | Related ACs |
|----------|-------|---------|-------------|
| `load_config()` | 1 | Add protocol field parsing | 01-01, 01-02, 01-04 |
| `init_config()` | 1 | Declare `PROVIDER_PROTOCOLS` array | 01-03 |
| `cmd_set()` | 2 | Protocol-based export logic | 02-01, 02-02, 02-03, 02-04, 02-05 |
| `cmd_unset()` | 2 | Clear all protocol variables | 02-03 |
| `cmd_test()` | 3 | Protocol-aware headers and routing | 03-01, 03-02, 03-03, 03-04 |
| `cmd_list()` | 4 | Add protocol column | 04-01 |
| `cmd_show()` | 4 | Mask Anthropic credentials | 04-02, 04-03 |

### Key Implementation Patterns

1. **Bash 3.2 Compatibility:**
   - Use `compat_assoc_set()` and `compat_assoc_get()` wrapper functions
   - Patterns already established at llm-env:236-288

2. **INI Config Parsing:**
   - Extend existing case statement in `load_config()`
   - Patterns already established at llm-env:309-380

3. **Variable Masking:**
   - Reuse existing `mask()` function at llm-env:513-532 for Anthropic credentials

4. **TDD Approach:**
   - RED: Write failing test for new protocol functionality
   - GREEN: Implement minimal code to pass test
   - REFACTOR: Clean up while tests remain green
   - Commit after each AC completion

---

## Testing Strategy

### Test Coverage Matrix

| Story | ACs | Unit Tests | Integration Tests | E2E Tests |
|-------|-----|------------|-------------------|-----------|
| 01 - Protocol Configuration | 4 | 4 | 0 | 0 |
| 02 - Variable Export | 5 | 0 | 5 | 0 |
| 03 - API Testing | 4 | 0 | 4 | 0 |
| 04 - Display & Security | 3 | 3 | 0 | 0 |
| **TOTAL** | **16** | **7** | **9** | **0** |

### Test Framework
- **Framework:** BATS (Bash Automated Testing System)
- **Location:** `tests/unit/test_protocols.bats`, `tests/integration/`
- **Naming Convention:** `.<test_description>() { ... }`
- **Pattern:** Already established in `tests/unit/test_validation.bats`

### Test Execution
```bash
# Run all tests
bats tests/

# Run protocol-specific tests
bats tests/unit/test_protocols.bats

# Run with verbose output
bats -t tests/
```

---

## Success Metrics

### Functional Metrics
- [ ] All 16 acceptance criteria verified complete
- [ ] All BATS tests passing (17 test files expected)
- [ ] Zero shellcheck warnings
- [ ] Consistent shfmt formatting

### Quality Metrics
- [ ] Backward compatibility: existing configs work unchanged
- [ ] Bash 3.2+ compatibility: runs on macOS default bash
- [ ] Shell linting: shellcheck SC2296, SC2155 resolved (already in codebase)

### UX Metrics
- [ ] Clear protocol indication in command output
- [ ] Proper credential masking applied
- [ ] Helpful error messages for invalid configurations

---

## Rollback Plan

If issues arise during implementation:

1. **Phase Rollback:** Each phase can be rolled back independently via git
2. **Feature Flag:** Protocol support is additive - existing functionality works without it
3. **Config Compatibility:** Existing configs without protocol field default to `openai` (no action needed)
4. **Revert Branch:** If critical issues, create revert branch from commit 06ff91d (pre-sprint)

---

## Dependencies and Blockers

### External Dependencies
- None (pure bash implementation)

### Internal Dependencies
| Phase | Depends On |
|-------|------------|
| Phase 1 | None |
| Phase 2 | Phase 1 |
| Phase 3 | Phase 1, Phase 2 |
| Phase 4 | Phase 1, Phase 2 |
| Phase 5 | All previous phases |

### Known Blockers
- None identified

---

## Documentation Updates Required

1. **README.md** (project root)
   - Add Anthropic protocol section
   - Update configuration examples

2. **config/llm-env.conf**
   - Add example Anthropic provider:
     ```ini
     [anthropic]
     api_key = ANTHROPIC_API_KEY
     auth_token = ANTHROPIC_AUTH_TOKEN
     base_url = https://api.anthropic.com
     model = claude-3-opus-20240229
     protocol = anthropic
     ```

3. **man page or help text** (if applicable)
   - Update with protocol field documentation

---

## Post-Sprint Deliverables

1. **Completed Code:**
   - Modified `llm-env` script with protocol support
   - Updated `config/llm-env.conf` with Anthropic example
   - New test file: `tests/unit/test_protocols.bats`

2. **Documentation:**
   - This sprint-design.md document
   - Updated README.md with protocol examples
   - Test coverage report

3. **Verification:**
   - All 16 ACs marked complete
   - Test execution report
   - Shellcheck and shfmt reports

4. **Git Artifacts:**
   - Feature branch with all changes
   - Conventional commit messages following TDD pattern
   - Clean merge to main

---

## Approval Checklist

- [ ] Design document reviewed
- [ ] Technical approach validated
- [ ] Risk analysis approved
- [ ] Estimated effort acceptable (5-9 days)
- [ ] Timeline confirmed
- [ ] Resources available
- [ ] Ready to proceed with sprint planning

---

**Document Status:** Draft - Awaiting Review
**Next Step:** Execute `/create-sprint @.planning/plans/active/1.0_anthropic_protocol_support` to generate sprint implementation plan
