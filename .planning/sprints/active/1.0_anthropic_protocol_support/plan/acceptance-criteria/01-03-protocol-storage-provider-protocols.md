# Acceptance Criteria: Protocol Storage in PROVIDER_PROTOCOLS

**Related User Story:** [[01: Protocol Configuration Parsing](../user-stories/01-protocol-configuration.md)

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Data Structure | PROVIDER_PROTOCOLS array | Bash 3.2 compatible via wrapper functions |
| Wrapper Functions | compat_assoc_set/get | Abstracts Bash 3.2 limitations |
| Test Framework | BATS | Unit tests for array operations |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 157-298) - Implement `compat_assoc` wrappers for `PROVIDER_PROTOCOLS`
- `llm-env` (Line: 309-380) - Update `load_config()` to store protocol values


## Happy Path Scenarios
**Scenario 1: Store protocol value for provider**
- **Given** Config has `[provider_anthropic]` with `protocol = anthropic`
- **When** load_config() executes compat_assoc_set_wrapper PROVIDER_PROTOCOLS anthropic "anthropic"
- **Then** Value is stored and retrievable via compat_assoc_get_wrapper

**Scenario 2: Retrieve protocol value for provider**
- **Given** PROVIDER_PROTOCOLS[openai] was set to "openai"
- **When** compat_assoc_get_wrapper PROVIDER_PROTOCOLS openai is called
- **Then** Returns "openai"

**Scenario 3: Multiple provider protocols**
- **Given** Config has `[provider_anthropic]` and `[provider_openai]` sections
- **When** load_config() parses both sections
- **Then** PROVIDER_PROTOCOLS contains entries for both providers

## Edge Cases
**Edge Case 1: Provider name with underscores**
- **Given** Config has `[provider_custom_tool]` section
- **When** load_config() stores protocol
- **Then** PROVIDER_PROTOCOLS[custom_tool] is accessible via wrapper

**Edge Case 2: Provider name with hyphens**
- **Given** Config has `[provider-my-tool]` section
- **When** load_config() stores protocol
- **Then** PROVIDER_PROTOCOLS[my-tool] is accessible via wrapper

## Error Conditions
**Error Scenario 1: Retrieving non-existent provider**
- **Given** PROVIDER_PROTOCOLS does not have entry for "missing"
- **When** compat_assoc_get_wrapper PROVIDER_PROTOCOLS missing is called
- **Then** Returns empty string (indicates not set)

## Performance Requirements
- **Response Time:** Array get/set operations complete within 1ms
- **Startup Impact:** Minimal overhead from wrapper functions

## Security Considerations
- **Input Validation:** Provider names validated before storage
- **Injection Protection:** Proper quoting in wrapper functions

## Test Implementation Guidance
**Test Type:** UNIT
**Test Data Requirements:** Test get/set wrapper functions directly
**Mock/Stub Requirements:** Mock storage for Bash 3.2 compatibility tests

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for PROVIDER_PROTOCOLS storage/retrieval
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] PROVIDER_PROTOCOLS stores protocol values correctly
- [ ] compat_assoc_set_wrapper works for storing protocols
- [ ] compat_assoc_get_wrapper retrieves stored protocols
- [ ] Multiple providers stored simultaneously
- [ ] Provider names with special characters handled

**Manual Review:**
- [ ] Code review and approval
