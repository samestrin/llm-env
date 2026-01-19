# Acceptance Criteria: Invalid Protocol Validation

**Related User Story:** [[01: Protocol Configuration Parsing](../user-stories/01-protocol-configuration.md)

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Config Parsing | Bash INI parser with regex | Uses existing case statement pattern |
| Validation | Protocol whitelist check | Only 'openai' and 'anthropic' allowed |
| Test Framework | BATS | Unit tests for validation logic |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 309-380) - Add validation logic to `load_config()`


## Happy Path Scenarios
**Scenario 1: Valid protocol 'anthropic'**
- **Given** Config has `protocol = anthropic`
- **When** load_config() validates the value
- **Then** Value passes validation and is stored

**Scenario 2: Valid protocol 'openai'**
- **Given** Config has `protocol = openai`
- **When** load_config() validates the value
- **Then** Value passes validation and is stored

## Edge Cases
**Edge Case 1: Case variations of valid values**
- **Given** Config has `protocol = Anthropic` or `protocol = ANTHROPIC`
- **When** load_config() validates after normalizing to lowercase
- **Then** Values pass validation as "anthropic"

## Error Conditions
**Error Scenario 1: Invalid protocol value**
- **Given** Config has `protocol = invalid`
- **When** load_config() validates the value
- **Then** Warning message: "Warning: Invalid protocol 'invalid' for provider 'test', defaulting to 'openai'"
- **And** PROVIDER_PROTOCOLS[test] is set to "openai"
- **And** Execution continues (non-fatal)

**Error Scenario 2: Empty protocol value**
- **Given** Config has `protocol = ` (empty string)
- **When** load_config() validates the value
- **Then** Warning message: "Warning: Empty protocol for provider 'test', defaulting to 'openai'"
- **And** PROVIDER_PROTOCOLS[test] is set to "openai"

**Error Scenario 3: Unknown valid-seeming protocol**
- **Given** Config has `protocol = google`
- **When** load_config() validates the value
- **Then** Warning message: "Warning: Invalid protocol 'google' for provider 'test', defaulting to 'openai'"
- **And** PROVIDER_PROTOCOLS[test] is set to "openai"

## Performance Requirements
- **Response Time:** Validation completes instantly (string comparison)
- **Startup Impact:** Minimal - only runs when protocol field present

## Security Considerations
- **Input Validation:** Only allow 'openai' or 'anthropic' as valid protocol values
- **Injection Protection:** Whitelist-based validation prevents injection
- **Logging:** Warnings logged for invalid values

## Test Implementation Guidance
**Test Type:** UNIT
**Test Data Requirements:** Test config files with various protocol values
**Mock/Stub Requirements:** Mock PROVIDER_PROTOCOLS array access

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for validation logic
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] Valid protocol values 'openai' and 'anthropic' accepted
- [ ] Invalid protocol values default to 'openai' with warning
- [ ] Case variations normalized and validated correctly
- [ ] Empty protocol values handled with warning
- [ ] Warning messages are clear and actionable

**Manual Review:**
- [ ] Code review and approval
