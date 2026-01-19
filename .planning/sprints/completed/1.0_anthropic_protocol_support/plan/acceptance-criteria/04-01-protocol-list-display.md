# Acceptance Criteria: Protocol Column in List Display

**Related User Story:** [[04: Protocol Information Display and Security](../user-stories/04-protocol-display.md)]

## Implementation Technology
| Component | Technology | Notes |
|-----------|------------|-------|
| Display Formatting | Bash printf/table | Protocol column in list output |
| Data Source | PROVIDER_PROTOCOLS array | Read protocol value per provider |
| Test Framework | BATS | Unit tests for display functions |

## Related Files (from codebase-discovery.json)
- `llm-env` (Line: 666-716) - Modify `cmd_list()` to add protocol column


## Happy Path Scenarios
**Scenario 1: List shows protocol column**
- **Given** Multiple providers configured with different protocols
- **When** User runs `llm-env list`
- **Then** Output table includes a "Protocol" column showing "openai" or "anthropic" for each provider

## Edge Cases
**Edge Case 1: Provider with unknown protocol value**
- **Given** Provider protocol is invalid or empty
- **When** User runs `llm-env list`
- **Then** Protocol column shows "openai" or empty placeholder

## Definition of Done
- [ ] All BATS tests passing for protocol column display
- [ ] shellcheck passes with zero warnings
- [ ] cmd_list() includes protocol column
