# Acceptance Criteria: Default Protocol Values

**Related User Story:** [[01: Protocol Configuration Parsing](../user-stories/01-protocol-configuration.md)

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Config Parsing | Bash INI parser with regex | Uses existing case statement pattern |
| Data Structure | PROVIDER_PROTOCOLS array | Bash 3.2 compatible via wrapper functions |
| Test Framework | BATS | Unit tests for default handling |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 309-380) - Modify `load_config()` to set default protocol
- `llm-env` (Line: 157-298) - Update `compat_assoc` wrappers for default handling


## Happy Path Scenarios
**Scenario 1: Default protocol when not specified**
- **Given** A config file with `[provider_openai]` section WITHOUT protocol field
- **When** load_config() is executed
- **Then** PROVIDER_PROTOCOLS[openai] defaults to "openai"

**Scenario 2: Default protocol for new provider**
- **Given** A config file with `[provider_newtool]` section with no protocol field
- **When** load_config() is executed
- **Then** PROVIDER_PROTOCOLS[newtool] defaults to "openai"

## Edge Cases
**Edge Case 1: Empty provider section**
- **Given** Config has `[provider_section]` with no keys
- **When** load_config() parses the file
- **Then** PROVIDER_PROTOCOLS[section] defaults to "openai"

**Edge Case 2: Provider with only other config keys**
- **Given** Config has `[provider_test]` with `api_key = xyz` but no protocol
- **When** load_config() parses the file
- **Then** PROVIDER_PROTOCOLS[test] defaults to "openai"

## Error Conditions
**Error Scenario 1: Backward compatibility existing configs**
- **Given** An existing config file with provider sections no protocol field
- **When** load_config() is executed
- **Then** All providers default to "openai" and existing functionality works

## Performance Requirements
- **Response Time:** Default value assignment completes instantly
- **Startup Impact:** Minimal - only when provider lacks protocol field

## Security Considerations
- **Input Validation:** Default value is trusted literal "openai"
- **Injection Protection:** No user input involved in default assignment

## Test Implementation Guidance
**Test Type:** UNIT
**Test Data Requirements:** Config files without protocol fields
**Mock/Stub Requirements:** Mock PROVIDER_PROTOCOLS array access

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for default handling
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] Default protocol is 'openai' when not specified
- [ ] Backward compatibility maintained for existing configs
- [ ] Empty provider sections handled correctly

**Manual Review:**
- [ ] Code review and approval
