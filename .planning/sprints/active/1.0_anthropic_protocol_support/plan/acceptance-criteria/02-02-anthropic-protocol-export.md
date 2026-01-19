# Acceptance Criteria: Anthropic Protocol Variable Export

**Related User Story:** [[02: Protocol-Specific Variable Export](../user-stories/02-variable-switching.md)]

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Variable Export | Bash environment variables | export declarations in cmd_set() |
| Protocol Detection | PROVIDER_PROTOCOLS array | Read protocol field from provider config |
| Test Framework | BATS | Integration tests for Anthropic protocol export |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 587-653) - Modify `cmd_set()` to export `ANTHROPIC_*` variables
- `llm-env` (Line: 157-298) - Use `compat_assoc` wrappers to read protocol


## Happy Path Scenarios
**Scenario 1: Set provider with Anthropic protocol exports correct variables**
- **Given** Provider config has protocol=anthropic and valid api_key, auth_token, base_url, model fields
- **When** User runs `llm-env set <provider>` for an anthropic protocol provider
- **Then** ANTHROPIC_API_KEY is exported with the provider's api_key value
- **And** ANTHROPIC_AUTH_TOKEN is exported with the provider's auth_token value
- **And** ANTHROPIC_BASE_URL is exported with the provider's base_url value
- **And** ANTHROPIC_MODEL is exported with the provider's model value
- **And** LLM_PROVIDER is exported with the provider name

**Scenario 2: All Anthropic variables are exportable after provider set**
- **Given** User has sourced llm-env in their shell
- **When** User runs `llm-env set anthropic-provider` (protocol=anthropic)
- **Then** Running `echo $ANTHROPIC_API_KEY` returns the configured API key
- **And** Running `echo $ANTHROPIC_AUTH_TOKEN` returns the configured auth token
- **And** Running `echo $ANTHROPIC_BASE_URL` returns the configured base URL
- **And** Running `echo $ANTHROPIC_MODEL` returns the configured model

## Edge Cases
**Edge Case 1: Provider with partial Anthropic config**
- **Given** Provider config only has api_key and base_url (no auth_token or model)
- **When** User sets the provider with anthropic protocol
- **Then** ANTHROPIC_API_KEY is exported
- **And** ANTHROPIC_BASE_URL is exported
- **And** ANTHROPIC_AUTH_TOKEN is unset
- **And** ANTHROPIC_MODEL is unset

**Edge Case 2: Provider with auth_token only**
- **Given** Provider config only has auth_token (no api_key, base_url, or model)
- **When** User sets the provider
- **Then** ANTHROPIC_AUTH_TOKEN is exported
- **And** Other ANTHROPIC variables are unset

## Error Conditions
**Error Scenario 1: Provider not found**
- Error message: "Error: Provider 'unknown' not found"
- Shell behavior: Return non-zero exit code, no variables exported

**Error Scenario 2: Missing required api_key field**
- Error message: "Error: Provider 'test' is missing required field 'api_key'"
- Shell behavior: Return non-zero exit code, no variables exported

## Performance Requirements
- **Response Time:** Variable export completes within 100ms
- **Memory:** No memory leaks with repeated anthropic provider switches

## Security Considerations
- **Credential Management:** Sensitive variable values are exported, not printed to stdout
- **Path sanitization:** Provider names are validated before use in export statements

## Test Implementation Guidance
**Test Type:** INTEGRATION
**Test Data Requirements:** Test provider with anthropic protocol and all fields populated
**Mock/Stub Requirements:** Mock environment variable inspection

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for Anthropic protocol export
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] ANTHROPIC_API_KEY is exported correctly for anthropic protocol providers
- [ ] ANTHROPIC_AUTH_TOKEN is exported correctly for anthropic protocol providers
- [ ] ANTHROPIC_BASE_URL is exported correctly for anthropic protocol providers
- [ ] ANTHROPIC_MODEL is exported correctly for anthropic protocol providers
- [ ] LLM_PROVIDER is exported with provider name
- [ ] Partial config exports only available variables

**Manual Review:**
- [ ] Code review and approval
