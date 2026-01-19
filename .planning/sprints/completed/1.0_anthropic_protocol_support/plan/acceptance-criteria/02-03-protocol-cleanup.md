# Acceptance Criteria: Protocol Cleanup on Provider Switch

**Related User Story:** [[02: Protocol-Specific Variable Export](../user-stories/02-variable-switching.md)]

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Variable Cleanup | Bash unset | Unset variables from inactive protocol |
| Protocol Detection | PROVIDER_PROTOCOLS array | Determine which variables to clean |
| Test Framework | BATS | Integration tests for cleanup behavior |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 587-653) - Modify `cmd_set()` to unset inactive protocol variables
- `llm-env` (Line: 947-960) - Modify `cmd_unset()` to clear all protocol variables


## Happy Path Scenarios
**Scenario 1: Switching from OpenAI to Anthropic cleans up OpenAI variables**
- **Given** User has previously run `llm-env set openai-provider` (OPENAI_* variables are set)
- **When** User runs `llm-env set anthropic-provider` (protocol=anthropic)
- **Then** OPENAI_API_KEY is unset
- **And** OPENAI_BASE_URL is unset
- **And** OPENAI_MODEL is unset
- **And** ANTHROPIC_* variables are correctly exported

**Scenario 2: Switching from Anthropic to OpenAI cleans up Anthropic variables**
- **Given** User has previously run `llm-env set anthropic-provider` (ANTHROPIC_* variables are set)
- **When** User runs `llm-env set openai-provider` (protocol=openai)
- **Then** ANTHROPIC_API_KEY is unset
- **And** ANTHROPIC_AUTH_TOKEN is unset
- **And** ANTHROPIC_BASE_URL is unset
- **And** ANTHROPIC_MODEL is unset
- **And** OPENAI_* variables are correctly exported

**Scenario 3: Environment is clean after protocol switch**
- **Given** User switches from openai to anthropic
- **When** cmd_set() completes
- **Then** Running `env | grep ^OPENAI_` returns no results
- **And** Only ANTHROPIC_* variables are present

## Edge Cases
**Edge Case 1: Multiple switches in same session**
- **Given** User switches openai -> anthropic -> openai -> anthropic
- **When** Each switch completes
- **Then** Only the active protocol's variables are set
- **And** No variable leak from previous protocol

**Edge Case 2: Variables already set externally before llm-env use**
- **Given** OPENAI_API_KEY is set externally (not by llm-env)
- **When** User sets anthropic provider
- **Then** OPENAI_API_KEY is explicitly unset (clean slate)
- **And** ANTHROPIC_* variables are correctly exported

**Edge Case 3: Partial provider config during switch**
- **Given** Target provider only has api_key (no base_url or model)
- **When** User switches protocols
- **Then** Previous protocol's all variables are unset
- **And** Target protocol's available variables are exported

## Error Conditions
**Error Scenario 1: Provider not found during switch**
- Error message: "Error: Provider 'unknown' not found"
- Shell behavior: Return non-zero exit code, existing variables remain unchanged

**Error Scenario 2: Missing required field during switch**
- Error message: "Error: Provider 'test' is missing required field 'api_key'"
- Shell behavior: Return non-zero exit code, existing variables remain unchanged

## Performance Requirements
- **Response Time:** Cleanup completes within 50ms
- **Memory:** No accumulation of variables with repeated protocol switching

## Security Considerations
- **Credential Management:** Credentials from inactive protocol are completely removed from environment
- **Scope Limitation:** Only protocol-specific variables are unset, not arbitrary OPENAI_/ANTHROPIC_ variables

## Test Implementation Guidance
**Test Type:** INTEGRATION
**Test Data Requirements:** Test providers with both openai and anthropic protocols
**Mock/Stub Requirements:** Mock environment variable inspection

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for protocol cleanup
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] Switching to openai unsets all ANTHROPIC_* variables
- [ ] Switching to anthropic unsets all OPENAI_* variables
- [ ] cmd_unset() clears both protocol variables
- [ ] Multiple switches maintain clean environment
- [ ] Externally set variables are properly unset

**Manual Review:**
- [ ] Code review and approval
