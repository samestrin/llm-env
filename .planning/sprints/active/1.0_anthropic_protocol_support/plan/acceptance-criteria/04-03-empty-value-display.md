# Acceptance Criteria: Empty Value Display

**Related User Story:** [[04: Protocol Information Display and Security](../user-stories/04-protocol-display.md)]

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Value Display | cmd_show() output | Show variable status with proper placeholder |
| Masking | mask() function | Handle empty string, null, unset values |
| Test Framework | BATS | Unit tests for display functions |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 718-733) - Modify `cmd_show()` to handle empty values for Anthropic variables


## Happy Path Scenarios
**Scenario 1: Empty string API key displays correctly**
- **Given** ANTHROPIC_API_KEY is set to empty string ""
- **When** mask() function is applied
- **Then** Output shows "ANTHROPIC_API_KEY: ∅"

**Scenario 2: unset variable displays as not set**
- **Given** ANTHROPIC_API_KEY is not set (unset)
- **When** User runs `llm-env show`
- **Then** Output shows "ANTHROPIC_API_KEY: ∅" or similar placeholder

**Scenario 3: Unset ANTHROPIC_AUTH_TOKEN displays correctly**
- **Given** ANTHROPIC_AUTH_TOKEN is not set
- **When** User runs `llm-env show`
- **Then** Output shows "ANTHROPIC_AUTH_TOKEN: ∅"

**Scenario 4: Only some Anthropic variables are set**
- **Given** ANTHROPIC_API_KEY is set but ANTHROPIC_AUTH_TOKEN is unset
- **When** User runs `llm-env show`
- **Then** ANTHROPIC_API_KEY shows masked value
- **And** ANTHROPIC_AUTH_TOKEN shows "∅" placeholder

## Edge Cases
**Edge Case 1: Whitespace-only credential value**
- **Given** ANTHROPIC_API_KEY is set to "   " (only spaces)
- **When** User runs `llm-env show`
- **Then** Output treats as empty and shows "∅"

**Edge Case 2: Newline-only credential value**
- **Given** ANTHROPIC_API_KEY is set to newline character only
- **When** User runs `llm-env show`
- **Then** Output handles gracefully with appropriate placeholder

**Edge Case 3: Variable exists but masked result would be empty**
- **Given** ANTHROPIC_API_KEY value would result in empty mask
- **When** mask() function processes it
- **Then** Output shows "∅" placeholder

## Error Conditions
**Error Scenario 1: Mask function error on empty value**
- Error message: No error (handle gracefully)
- Shell behavior: Show generic placeholder like "∅" or "<not set>"

**Error Scenario 2: Unexpected special characters in credential**
- Error message: No explicit error
- Shell behavior: Masking still applies, display sanitized output

## Performance Requirements
- **Response Time:** Empty value check completes instantly
- **Memory:** No buffer overflows in special character handling

## Security Considerations
- **Credential Exposure:** Empty values don't expose any information
- **Display:** Placeholder is generic and doesn't reveal variable state details

## Test Implementation Guidance
**Test Type:** UNIT
**Test Data Requirements:** Test with empty strings, unset variables, whitespace values
**Mock/Stub Requirements:** Mock environment variable inspection

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for empty value display
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] Empty string values display as "∅"
- [ ] Unset variables display as "∅"
- [ ] Whitespace-only values treated as empty
- [ ] Both set and unset Anthropic variables handled in same show output

**Manual Review:**
- [ ] Code review and approval
