# Acceptance Criteria: Protocol Field Parsing

**Related User Story:** [[01: Protocol Configuration Parsing](../user-stories/01-protocol-configuration.md)]

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Config Parsing | Bash INI parser with regex | Uses existing case statement pattern |
| Data Structure | PROVIDER_PROTOCOLS array | Bash 3.2 compatible via wrapper functions |
| Test Framework | BATS | Unit tests for config parsing |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 309-380) - Modify `load_config()` to parse `protocol` field
- `config/llm-env.conf` - Add example `protocol` configuration


## Happy Path Scenarios
**Scenario 1: Parse protocol=anthropic**
- **Given** A config file with `[provider_anthropic]` section containing `protocol = anthropic`
- **When** load_config() is executed
- **Then** PROVIDER_PROTOCOLS[anthropic] is set to "anthropic"

**Scenario 2: Parse protocol=openai explicit**
- **Given** A config file with `[provider_openai]` section containing `protocol = openai`
- **When** load_config() is executed
- **Then** PROVIDER_PROTOCOLS[openai] is set to "openai"

## Edge Cases
**Edge Case 1: Whitespace in protocol value**
- **Given** Config has `protocol =  anthropic  ` (extra whitespace)
- **When** load_config() parses the file
- **Then** Protocol value is trimmed to "anthropic"

**Edge Case 2: Case sensitivity**
- **Given** Config has `protocol = ANTHROPIC` (uppercase)
- **When** load_config() parses the file
- **Then** Protocol value is normalized to lowercase "anthropic"

## Error Conditions
**Error Scenario 1: Malformed config line**
- Error message: "Warning: Could not parse config line: '[malformed]'"
- Shell behavior: Skip the line and continue parsing

## Performance Requirements
- **Response Time:** Config parsing should complete within 50ms for typical config files (<50 lines)
- **Startup Impact:** No measurable increase to llm-env source time

## Security Considerations
- **Input Validation:** Parse protocol value before assignment
- **Injection Protection:** Proper quote all variable assignments (follow existing shellcheck patterns)

## Test Implementation Guidance
**Test Type:** UNIT
**Test Data Requirements:** Sample config files with protocol configurations
**Mock/Stub Requirements:** Mock PROVIDER_PROTOCOLS array access

## Definition of Done
**Auto-Verified:**
- [ ] All BATS tests passing for config parsing
- [ ] shellcheck passes with zero warnings
- [ ] shfmt formatting consistent

**Story-Specific:**
- [ ] Config parses protocol field correctly from provider sections
- [ ] Whitespace is trimmed from protocol values
- [ ] Protocol values are normalized to lowercase
- [ ] Malformed lines are skipped with warning

**Manual Review:**
- [ ] Code review and approval
