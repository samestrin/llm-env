# Acceptance Criteria: Protocol-Aware Test Endpoint Routing

**Related User Story:** [[03: Protocol-Aware API Testing]](../user-stories/03-api-testing.md)

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Endpoint Resolution | Protocol-based path selection | OpenAI: /v1/models, Anthropic: /v1/messages |
| HTTP Validation | JSON parsing API response | Check for successful auth |
| Test Framework | BATS | Integration tests for API endpoints |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 974-1079) - Modify `cmd_test()` to implement protocol-based routing


## Happy Path Scenarios
**Scenario 1: OpenAI provider uses correct endpoint**
- **Given** OpenAI provider configured with base_url set
- **When** cmd_test() executes for openai protocol
- **Then** Request goes to `${base_url}/v1/models` (or provider-specific endpoint)
- **And** Returns list of models or auth success

**Scenario 2: Anthropic provider uses correct endpoint**
- **Given** Anthropic provider configured with base_url set
- **When** cmd_test() executes for anthropic protocol
- **Then** Request goes to `${base_url}/v1/messages` (or provider-specific endpoint)
- **And** Returns successful 200 response for valid credentials

**Scenario 3: Provider-specific endpoint override**
- **Given** Provider configured with custom test_endpoint
- **When** cmd_test() executes
- **Then** Request goes to the configured custom endpoint
- **And** Ignores protocol default endpoint

## Edge Cases
**Edge Case 1: Base URL missing protocol or path**
- **Given** Provider base_url lacks scheme (http/https)
- **When** cmd_test() constructs request
- **Then** Adds default https:// or shows helpful error

**Edge Case 2: Base URL with trailing slash**
- **Given** Provider base_url ends with /
- **When** cmd_test() constructs full endpoint path
- **Then** Correctly handles path concatenation without double slashes

**Edge Case 3: Endpoint path already in base_url**
- **Given** Provider base_url includes full endpoint path
- **When** cmd_test() executes
- **Then** Does not append protocol default path twice

**Edge Case 4: Unknown protocol configured**
- **Given** Provider configured with unrecognized protocol value
- **When** cmd_test() attempts to determine endpoint
- **Then** Falls back to openai endpoint or shows clear error

## Error Conditions
**Error Scenario 1: No base URL configured**
- Error message: "Error: No base URL configured for provider"
- Shell behavior: Return non-zero exit code

**Error Scenario 2: Endpoint returns 404**
- Error message: "Error: Test endpoint not found (404)"
- HTTP status / error code: 404
- Shell behavior: Return non-zero exit code

**Error Scenario 3: Network connection failed**
- Error message: "Error: Could not connect to endpoint"
- Shell behavior: Return non-zero exit code

**Error Scenario 4: Invalid URL format**
- Error message: "Error: Invalid base URL format"
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
- [ ] All BATS tests passing for endpoint routing
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] OpenAI test uses /v1/models or provider endpoint
- [ ] Anthropic test uses /v1/messages or provider endpoint
- [ ] Provider-specific endpoints override protocol defaults
- [ ] Trailing slash handling correct

**Manual Review:**
- [ ] Code review and approval
