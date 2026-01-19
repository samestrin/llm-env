# Acceptance Criteria: Anthropic Credential Masking

**Related User Story:** [[04: Protocol Information Display and Security](../user-stories/04-protocol-display.md)]

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Credential Masking | mask() function | Reuse existing mask() from llm-env:643-662 |
| Display | cmd_show() output | Show masked values for ANTHROPIC_* variables |
| Test Framework | BATS | Unit tests for display functions |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 718-733) - Modify `cmd_show()` to display masked `ANTHROPIC_*` variables
- `llm-env` (Line: 643-662) - Reuse `mask()` function for Anthropic credentials


## Happy Path Scenarios
**Scenario 1: Show displays masked ANTHROPIC_API_KEY**
- **Given** ANTHROPIC_API_KEY is set to "sk-ant-1234567890abcdef"
- **When** User runs `llm-env show`
- **Then** Output shows "ANTHROPIC_API_KEY: ••••cdef" (masked format)
- **And** Full key is never displayed

**Scenario 2: Show displays masked ANTHROPIC_AUTH_TOKEN**
- **Given** ANTHROPIC_AUTH_TOKEN is set to "sk-ant-token9876543210"
- **When** User runs `llm-env show`
- **Then** Output shows "ANTHROPIC_AUTH_TOKEN: ••••3210" (masked format)
- **And** Full token is never displayed

**Scenario 3: Both Anthropic credentials shown masked together**
- **Given** Both ANTHROPIC_API_KEY and ANTHROPIC_AUTH_TOKEN are set
- **When** User runs `llm-env show`
- **Then** Both variables are displayed with masking applied
- **And** Format matches mask() function output (bullets + last 4 chars)

## Edge Cases
**Edge Case 1: Short API keys (3-4 characters)**
- **Given** ANTHROPIC_API_KEY is "xyz" (3 chars)
- **When** mask() function is applied
- **Then** Output shows "•yz" (first char masked per mask() logic)

**Edge Case 2: API key equal to 4 characters**
- **Given** ANTHROPIC_API_KEY is "1234"
- **When** mask() function is applied
- **Then** Output shows "•234" (first char masked)

**Edge Case 3: API key with 5+ characters**
- **Given** ANTHROPIC_API_KEY is "sk-ant-12345"
- **When** mask() function is applied
- **Then** Output shows "••••••••345" or "••••345" per mask() logic

**Edge Case 4: Very long API key**
- **Given** ANTHROPIC_API_KEY is longer than 50 characters
- **When** mask() function is applied
- **Then** Output shows bullets for all but last 4 characters

## Error Conditions
**Error Scenario 1: Masking function not available**
- Error message: "Error: mask() function not found"
- Shell behavior: Fall back to showing "∅" or empty placeholder

**Error Scenario 2: Null/undefined credential value**
- Error message: No error
- Shell behavior: Display variable status with empty or ∅ placeholder

## Performance Requirements
- **Response Time:** Show display completes within 50ms
- **Memory:** No memory leaks with repeated show commands

## Security Considerations
- **Credential Exposure:** No sensitive values displayed unmasked
- **Logs:** Ensure masked values are masked in logs/history
- **Screenshots:** Masked format prevents credential exposure in screenshots

## Test Implementation Guidance
**Test Type:** UNIT
**Test Data Requirements:** Test credentials of various lengths
**Mock/Stub Requirements:** Mock mask() function output verification

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for credential masking
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] ANTHROPIC_API_KEY is displayed with masking
- [ ] ANTHROPIC_AUTH_TOKEN is displayed with masking
- [ ] Masking format matches existing mask() output (••••last4)
- [ ] All credential lengths handled correctly
- [ ] No unmasked values ever displayed

**Manual Review:**
- [ ] Code review and approval
