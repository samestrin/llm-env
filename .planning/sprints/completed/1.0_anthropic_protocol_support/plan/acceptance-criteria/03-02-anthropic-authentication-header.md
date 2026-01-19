# Acceptance Criteria: Anthropic Protocol Authentication Header

**Related User Story:** [[03: Protocol-Aware API Testing]](../user-stories/03-api-testing.md)

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| API Testing | curl with x-api-key header | Anthropic: x-api-key: {api_key} |
| HTTP Validation | JSON parsing API response | Check for successful auth |
| Test Framework | BATS | Integration tests for API endpoints |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 974-1079) - Modify `cmd_test()` to implement Anthropic authentication logic


## Happy Path Scenarios
**Scenario 1: Test Anthropic provider with valid credentials**
- **Given** User runs `llm-env test anthropic` with valid ANTHROPIC_API_KEY
- **When** cmd_test() executes curl request
- **Then** Request uses `x-api-key: $ANTHROPIC_API_KEY` header
- **And** Returns success message for valid credentials

**Scenario 2: Test validates x-api-key format**
- **Given** Anthropic provider configured with protocol=anthropic
- **When** cmd_test() constructs the curl request
- **Then** Header uses "x-api-key:" without Bearer prefix
- **And** No Authorization header is sent

**Scenario 3: Anthropic-compatible providers**
- **Given** Provider configured with protocol=anthropic
- **When** cmd_test() executes for that provider
- **Then** Request uses x-api-key header consistently

## Edge Cases
**Edge Case 1: API key contains special characters**
- **Given** ANTHROPIC_API_KEY contains URL-escaped characters
- **When** cmd_test() executes curl request
- **Then** API key is properly quoted/escaped in header

**Edge Case 2: Empty API key**
- **Given** ANTHROPIC_API_KEY is set but empty string
- **When** cmd_test() attempts request
- **Then** Appropriate error message displayed

**Edge Case 3: Both protocols accidentally configured**
- **Given** Provider has conflicting protocol configuration
- **When** cmd_test() reads provider protocol
- **Then** Uses the configured value without mixing headers

## Error Conditions
**Error Scenario 1: Invalid API credentials**
- Error message: "Authentication failed: invalid API key"
- HTTP status / error code: 401
- Shell behavior: Return non-zero exit code

**Error Scenario 2: Missing Anthropic API version**
- Error message: "Error: No base URL configured for provider"
- Shell behavior: Return non-zero exit code

**Error Scenario 3: Curl not available**
- Error message: "Error: curl is required for testing"
- Shell behavior: Return non-zero exit code

## Performance Requirements
- **Response Time:** Test completes within 10 seconds for valid credentials
- **Timeout:** 30-second timeout for API requests

## Security Considerations
- **Credential Handling:** API keys only sent in HTTP headers, never printed
- **Error Messages:** Never expose full API key in error messages

## Test Implementation Guidance
**Test Type:** INTEGRATION
**Test Data Requirements:** Mock API endpoints for testing
**Mock/Stub Requirements:** Mock curl responses for test scenarios

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for Anthropic auth header
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] Anthropic test uses x-api-key header
- [ ] No Bearer token prefix used
- [ ] Valid credentials return success
- [ ] No Authorization header is sent

**Manual Review:**
- [ ] Code review and approval
