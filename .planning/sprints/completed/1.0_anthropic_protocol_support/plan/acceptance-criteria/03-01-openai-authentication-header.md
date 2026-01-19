# Acceptance Criteria: OpenAI Protocol Authentication Header

**Related User Story:** [[03: Protocol-Aware API Testing]](../user-stories/03-api-testing.md)

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| API Testing | curl with Bearer token | OpenAI: Authorization: Bearer {api_key} |
| HTTP Validation | JSON parsing API response | Check for successful auth |
| Test Framework | BATS | Integration tests for API endpoints |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 974-1079) - Modify `cmd_test()` to implement OpenAI authentication logic


## Happy Path Scenarios
**Scenario 1: Test OpenAI provider with valid credentials**
- **Given** User runs `llm-env test openai` with valid OPENAI_API_KEY
- **When** cmd_test() executes curl request
- **Then** Request uses `Authorization: Bearer $OPENAI_API_KEY` header
- **And** Returns success message for valid credentials

**Scenario 2: Test validates Bearer token format**
- **Given** OpenAI provider configured with protocol=openai
- **When** cmd_test() constructs the curl request
- **Then** Header includes "Bearer " prefix before the API key
- **And** No additional authentication headers are sent

**Scenario 3: Multiple OpenAI-compatible providers**
- **Given** Provider configured with protocol=openai (e.g., azure, openrouter)
- **When** cmd_test() executes for that provider
- **Then** Request uses Authorization: Bearer header consistently

## Edge Cases
**Edge Case 1: API key contains special characters**
- **Given** OPENAI_API_KEY contains URL-escaped characters
- **When** cmd_test() executes curl request
- **Then** API key is properly quoted/escaped in header

**Edge Case 2: Empty API key**
- **Given** OPENAI_API_KEY is set but empty string
- **When** cmd_test() attempts request
- **Then** Appropriate error message displayed

## Error Conditions
**Error Scenario 1: Invalid API credentials**
- Error message: "Authentication failed: invalid API key"
- HTTP status / error code: 401
- Shell behavior: Return non-zero exit code

**Error Scenario 2: Missing Base URL**
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
- [ ] All BATS tests passing for OpenAI auth header
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] OpenAI test uses Authorization: Bearer header
- [ ] Bearer token format includes space after "Bearer"
- [ ] Valid credentials return success

**Manual Review:**
- [ ] Code review and approval
