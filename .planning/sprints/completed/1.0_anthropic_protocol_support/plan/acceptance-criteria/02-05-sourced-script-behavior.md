# Acceptance Criteria: Sourced Script Environment Behavior

**Related User Story:** [[02: Protocol-Specific Variable Export](../user-stories/02-variable-switching.md)]

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Environment Export | Bash export statements | Variables exported to parent shell |
| No Subshell Spawn | Source mode operation | Must not use `set -e` or spawn subshell |
| Test Framework | BATS | Tests for sourced script behavior |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 587-653) - Verify `cmd_set()` uses `export` for sourced environment


## Happy Path Scenarios
**Scenario 1: Exported variables persist in parent shell**
- **Given** User sources llm-env: `source ./llm-env`
- **When** User runs `llm-env set any-provider`
- **Then** Exported variables are available in user's current shell
- **And** `echo $LLM_PROVIDER` returns the provider name

**Scenario 2: No set -e interferes with variable operations**
- **Given** User has existing shell with error handling configured
- **When** User sources llm-env and runs set command
- **Then** Variable operations complete without premature exit
- **And** Script does not add `set -e` that would break behavior

**Scenario 3: Multiple commands work in same source session**
- **Given** User has sourced llm-env
- **When** User runs `llm-env set provider1` then `llm-env set provider2`
- **Then** Both commands execute successfully
- **And** Variables from provider1 are properly replaced with provider2

## Edge Cases
**Edge Case 1: Running llm-env without source**
- **Given** User runs llm-env directly (not sourced): `./llm-env set provider`
- **When** The script completes
- **Then** Variables are exported but not visible (spawned subshell)
- **And** Script exits with appropriate return code
- **Note:** This is expected behavior - user should use source mode

**Edge Case 2: Existing environment variables interfere**
- **Given** User has existing OPENAI_API_KEY from previous session
- **When** User sources llm-env and runs `llm-env set anthropic-provider`
- **Then** Old OPENAI_API_KEY is unset
- **And** ANTHROPIC_* variables are correctly exported

**Edge Case 3: Shell with restrictive mode**
- **Given** User's shell has `set -u` (undefined variable error) active
- **When** User sources llm-env and runs set command
- **Then** Script handles undefined variables gracefully
- **And** Command completes without error

## Error Conditions
**Error Scenario 1: Provider not found**
- Error message: "Error: Provider 'unknown' not found"
- Shell behavior: Return non-zero exit code in sourced environment
- Variable state: No variables are exported or modified

**Error Scenario 2: Missing required field**
- Error message: "Error: Provider 'test' is missing required field 'api_key'"
- Shell behavior: Return non-zero exit code
- Variable state: Existing variables remain unchanged

## Performance Requirements
- **Response Time:** Export operations complete within 100ms
- **Memory:** No memory leaks with repeated sourced commands

## Security Considerations
- **Sandboxing:** Variables are exported only to current shell context
- **Privilege Escalation:** No use of eval or other unsafe practices

## Test Implementation Guidance
**Test Type:** INTEGRATION
**Test Data Requirements:** Test environment in sourced mode (not subshell)
**Mock/Stub Requirements:** Verify variable persistence in parent shell context

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for sourced script behavior
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] Exported variables persist when script is sourced
- [ ] No `set -e` is added that would break sourced behavior
- [ ] Multiple set commands work in same session
- [ ] Unexported variables (not sourced) behavior is documented

**Manual Review:**
- [ ] Code review and approval
- [ ] User documentation updated for source requirement
