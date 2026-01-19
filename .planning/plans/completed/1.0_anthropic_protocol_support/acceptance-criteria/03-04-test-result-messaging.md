# Acceptance Criteria: Clear Test Result Messaging

**Related User Story:** [[03: Protocol-Aware API Testing]](../user-stories/03-api-testing.md)

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Result Messaging | Standard output format | Clear success/failure indicators |
| Error Handling | Exit codes and stderr | Non-zero exit on failure |
| Test Framework | BATS | Integration tests for output format |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 974-1079) - Modify `cmd_test()` to include protocol in output messages


## Happy Path Scenarios
**Scenario 1: Success message for OpenAI provider**
- **Given** User runs `llm-env test openai` with valid credentials
- **When** cmd_test() receives successful response
- **Then** Display message "openai: Connected successfully (protocol: openai)"
- **And** Exit code is 0

**Scenario 2: Success message for Anthropic provider**
- **Given** User runs `llm-env test anthropic` with valid credentials
- **When** cmd_test() receives successful response
- **Then** Display message "anthropic: Connected successfully (protocol: anthropic)"
- **And** Exit code is 0

**Scenario 3: Clear failure message with context**
- **Given** User runs `llm-env test provider` with invalid credentials
- **When** cmd_test() receives 401 response
- **Then** Display message "provider: Authentication failed (protocol: {protocol}) - invalid API key"
- **And** Exit code is non-zero

**Scenario 4: Protocol displayed in output**
- **Given** Any provider test command is run
- **When** cmd_test() returns result
- **Then** Output includes which protocol was used (openai or anthropic)

## Edge Cases
**Edge Case 1: Rate limited response**
- **Given** API returns 429 status
- **When** cmd_test() receives response
- **Then** Display message "provider: Rate limited - please try again later"
- **And** Exit code is non-zero

**Edge Case 2: Server error response**
- **Given** API returns 5xx status
- **When** cmd_test() receives response
- **Then** Display message "provider: Server error (HTTP {status_code})"
- **And** Exit code is non-zero

**Edge Case 3: Unexpected response format**
- **Given** API returns non-JSON response
- **When** cmd_test() parses response
- **Then** Display message "provider: Unexpected response format"
- **And** Exit code is non-zero

**Edge Case 4: Malformed API response**
- **Given** API returns invalid JSON
- **When** cmd_test() parses response
- **Then** Display message without crash
- **And** Shows hint about expected format

## Error Conditions
**Error Scenario 1: Network timeout**
- Error message: "provider: Connection timed out (30s)"
- Shell behavior: Return non-zero exit code

**Error Scenario 2: Unknown protocol configured**
- Error message: "provider: Unknown protocol '{protocol}' configured"
- Shell behavior: Return non-zero exit code

**Error Scenario 3: Missing provider configuration**
- Error message: "provider: No configuration found"
- Shell behavior: Return non-zero exit code

**Error Scenario 4: Missing curl binary**
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
- [ ] All BATS tests passing for result messaging
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] Success messages include provider name and protocol
- [ ] Failure messages include protocol and error details
- [ ] Exit code 0 for success, non-zero for failure
- [ ] Protocol always displayed in output

**Manual Review:**
- [ ] Code review and approval
