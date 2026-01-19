# Acceptance Criteria: Protocol Confirmation Output Message

**Related User Story:** [[02: Protocol-Specific Variable Export](../user-stories/02-variable-switching.md)]

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Output Display | Bash echo/printf | Print confirmation message to stdout |
| Message Formatting | String interpolation | Include protocol name and exported variables |
| Test Framework | BATS | Tests for output message format and content |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 587-653) - Modify `cmd_set()` to update confirmation message


## Happy Path Scenarios
**Scenario 1: OpenAI protocol set shows correct confirmation message**
- **Given** Provider config has protocol=openai
- **When** User runs `llm-env set openai-provider`
- **Then** Output message indicates "openai" protocol is active
- **And** Message includes exported variables: OPENAI_API_KEY, OPENAI_BASE_URL, OPENAI_MODEL

**Scenario 2: Anthropic protocol set shows correct confirmation message**
- **Given** Provider config has protocol=anthropic
- **When** User runs `llm-env set anthropic-provider`
- **Then** Output message indicates "anthropic" protocol is active
- **And** Message includes exported variables: ANTHROPIC_API_KEY, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_BASE_URL, ANTHROPIC_MODEL

**Scenario 3: Partial config message shows only exported variables**
- **Given** Provider config has protocol=anthropic but only has api_key and base_url
- **When** User runs `llm-env set partial-provider`
- **Then** Message shows "anthropic" protocol
- **And** Message lists only ANTHROPIC_API_KEY and ANTHROPIC_BASE_URL (not the missing ones)

## Edge Cases
**Edge Case 1: Multiple switches show updated messages**
- **Given** User switches openai -> anthropic
- **When** Each set command completes
- **Then** First message indicates openai protocol
- **And** Second message indicates anthropic protocol

**Edge Case 2: Provider name with special characters**
- **Given** Provider name contains spaces or special characters
- **When** User sets the provider
- **Then** Message displays provider name correctly quoted or escaped

## Error Conditions
**Error Scenario 1: Provider not found**
- Error message: "Error: Provider 'unknown' not found"
- Shell behavior: Return non-zero exit code, no confirmation message printed

**Error Scenario 2: Missing required field**
- Error message: "Error: Provider 'test' is missing required field 'api_key'"
- Shell behavior: Return non-zero exit code, no confirmation message printed

## Performance Requirements
- **Response Time:** Message output completes within 10ms
- **Memory:** No buffer overflows in message formatting

## Security Considerations
- **Credential Protection:** Confirmation message does NOT print actual variable values
- **Message Sanitization:** Provider names are escaped to prevent injection

## Test Implementation Guidance
**Test Type:** INTEGRATION
**Test Data Requirements:** Test providers with both protocols and varying field completeness
**Mock/Stub Requirements:** Capture stdout message content for verification

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for confirmation messages
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] OpenAI protocol message correctly identifies "openai" protocol
- [ ] Anthropic protocol message correctly identifies "anthropic" protocol
- [ ] Message lists exported variables
- [ ] Message does NOT print actual variable values
- [ ] Partial config shows only exported variables

**Manual Review:**
- [ ] Code review and approval
- [ ] Message format is clear and user-friendly
