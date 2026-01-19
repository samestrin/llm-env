# Acceptance Criteria: OpenAI Protocol Variable Export

**Related User Story:** [[02: Protocol-Specific Variable Export](../user-stories/02-variable-switching.md)]

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Variable Export | Bash environment variables | export declarations in cmd_set() |
| Protocol Detection | PROVIDER_PROTOCOLS array | Read protocol field from provider config |
| Test Framework | BATS | Integration tests for OpenAI protocol export |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 587-653) - Modify `cmd_set()` to export `OPENAI_*` variables
- `llm-env` (Line: 157-298) - Use `compat_assoc` wrappers to read protocol


## Happy Path Scenarios
**Scenario 1: Set provider with OpenAI protocol exports correct variables**
- **Given** Provider config has protocol=openai and valid api_key, base_url, model fields
- **When** User runs `llm-env set <provider>` for an openai protocol provider
- **Then** OPENAI_API_KEY is exported with the provider's api_key value
- **And** OPENAI_BASE_URL is exported with the provider's base_url value
- **And** OPENAI_MODEL is exported with the provider's model value
- **And** LLM_PROVIDER is exported with the provider name

**Scenario 2: All OpenAI variables are exportable after provider set**
- **Given** User has sourced llm-env in their shell
- **When** User runs `llm-env set openai-provider` (protocol=openai)
- **Then** Running `echo $OPENAI_API_KEY` returns the configured API key
- **And** Running `echo $OPENAI_BASE_URL` returns the configured base URL
- **And** Running `echo $OPENAI_MODEL` returns the configured model

## Edge Cases
**Edge Case 1: Provider with partial OpenAI config**
- **Given** Provider config only has api_key (no base_url or model)
- **When** User sets the provider with openai protocol
- **Then** OPENAI_API_KEY is exported
- **And** OPENAI_BASE_URL is unset (not empty string)
- **And** OPENAI_MODEL is unset

**Edge Case 2: Provider with extra OpenAI fields**
- **Given** Provider config has api_key, base_url, model, and an extra field called api_version
- **When** User sets the provider
- **Then** Only OPENAI_API_KEY, OPENAI_BASE_URL, OPENAI_MODEL, LLM_PROVIDER are exported
- **And** No extra OPENAI_ variables are exported

## Error Conditions
**Error Scenario 1: Provider not found**
- Error message: "Error: Provider 'unknown' not found"
- Shell behavior: Return non-zero exit code, no variables exported

**Error Scenario 2: Missing required api_key field**
- Error message: "Error: Provider 'test' is missing required field 'api_key'"
- Shell behavior: Return non-zero exit code, no variables exported

## Performance Requirements
- **Response Time:** Variable export completes within 100ms
- **Memory:** No memory leaks with repeated openai provider switches

## Security Considerations
- **Credential Management:** Sensitive variable values are exported, not printed to stdout
- **Path sanitization:** Provider names are validated before use in export statements

## Test Implementation Guidance
**Test Type:** INTEGRATION
**Test Data Requirements:** Test provider with openai protocol and all fields populated
**Mock/Stub Requirements:** Mock environment variable inspection

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for OpenAI protocol export
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] OPENAI_API_KEY is exported correctly for openai protocol providers
- [ ] OPENAI_BASE_URL is exported correctly for openai protocol providers
- [ ] OPENAI_MODEL is exported correctly for openai protocol providers
- [ ] LLM_PROVIDER is exported with provider name
- [ ] Partial config exports only available variables

**Manual Review:**
- [ ] Code review and approval
