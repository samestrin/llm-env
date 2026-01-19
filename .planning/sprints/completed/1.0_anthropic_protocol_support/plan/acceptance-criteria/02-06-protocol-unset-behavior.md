# Acceptance Criteria: Protocol Unset Behavior

**Related User Story:** [[02: Protocol-Specific Variable Export](../user-stories/02-variable-switching.md)]

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Variable Cleanup | Bash unset | Unset variables from all protocols |
| Test Framework | BATS | Integration tests for unset behavior |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 947-960) - Modify `cmd_unset()` to clear all protocol variables

## Happy Path Scenarios
**Scenario 1: Unsetting an OpenAI Protocol Provider**
- **Given** the current provider is set to "my-openai-provider"
- **And** "my-openai-provider" has `protocol=openai`
- **And** the environment contains `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`
- **When** I run `llm-env unset`
- **Then** `OPENAI_API_KEY` is unset
- **And** `OPENAI_BASE_URL` is unset
- **And** `OPENAI_MODEL` is unset
- **And** `LLM_PROVIDER` is unset

**Scenario 2: Unsetting an Anthropic Protocol Provider**
- **Given** the current provider is set to "my-anthropic-provider"
- **And** "my-anthropic-provider" has `protocol=anthropic`
- **And** the environment contains `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_MODEL`
- **When** I run `llm-env unset`
- **Then** `ANTHROPIC_API_KEY` is unset
- **And** `ANTHROPIC_AUTH_TOKEN` is unset
- **And** `ANTHROPIC_BASE_URL` is unset
- **And** `ANTHROPIC_MODEL` is unset
- **And** `LLM_PROVIDER` is unset

**Scenario 3: Unsetting Cleans All Known Variables (Safety Check)**
- **Given** the environment somehow contains mixed variables (e.g., `OPENAI_API_KEY` and `ANTHROPIC_API_KEY`)
- **When** I run `llm-env unset`
- **Then** All standard variables for both protocols are unset:
  - `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`
  - `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_MODEL`
- **And** `LLM_PROVIDER` is unset

## Edge Cases
**Edge Case 1: Unsetting when no provider is set**
- **Given** No LLM variables are set
- **When** I run `llm-env unset`
- **Then** Command completes successfully
- **And** Environment remains clean

## Error Conditions
**Error Scenario 1: Unsetting with readonly variables**
- **Given** `OPENAI_API_KEY` is set to readonly
- **When** I run `llm-env unset`
- **Then** Command attempts to unset
- **And** Reports error if unset fails (shell behavior)

## Performance Requirements
- **Response Time:** Unset completes instantly

## Security Considerations
- **Clean Slate:** Ensures no credentials remain in environment

## Test Implementation Guidance
**Test Type:** INTEGRATION
**Test Data Requirements:** Environment with mixed protocol variables
**Mock/Stub Requirements:** None

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for unset behavior
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] `llm-env unset` clears all OPENAI_* variables
- [ ] `llm-env unset` clears all ANTHROPIC_* variables
- [ ] `llm-env unset` clears LLM_PROVIDER

**Manual Review:**
- [ ] Code review and approval
