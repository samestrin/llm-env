# Test Planning Matrix

**Generated:** January 18, 2026 05:49:19PM
**Plan:** 1.0_anthropic_protocol_support
**Total ACs:** 17

---

## Summary by Story

| Story | ACs | Unit | Integration | E2E | Complexity |
|-------|-----|------|-------------|-----|------------|
| 01 - Protocol Configuration | 4 | 4 | 0 | 0 | Medium |
| 02 - Variable Switching | 6 | 0 | 5 | 0 | Medium |
| 03 - API Testing | 4 | 0 | 4 | 0 | Medium |
| 04 - Protocol Display | 3 | 3 | 0 | 0 | Low |

---

## Detailed AC List

### Story 1: Protocol Configuration Parsing

| AC ID | Title | Test Type | Complexity | Priority |
|-------|-------|-----------|------------|----------|
| 01-01 | Protocol Field Parsing | Unit | Low | P1 |
| 01-02 | Default Protocol Values | Unit | Low | P1 |
| 01-03 | Protocol Storage in PROVIDER_PROTOCOLS | Unit | Medium | P1 |
| 01-04 | Invalid Protocol Validation | Unit | Medium | P1 |

### Story 2: Protocol-Specific Variable Export

| AC ID | Title | Test Type | Complexity | Priority |
|-------|-------|-----------|------------|----------|
| 02-01 | OpenAI Protocol Variable Export | Integration | Medium | P1 |
| 02-02 | Anthropic Protocol Variable Export | Integration | Medium | P1 |
| 02-03 | Protocol Cleanup on Provider Switch | Integration | Medium | P1 |
| 02-04 | Protocol Confirmation Output Message | Integration | Low | P2 |
| 02-05 | Sourced Script Environment Behavior | Integration | Medium | P1 |

### Story 3: Protocol-Aware API Testing

| AC ID | Title | Test Type | Complexity | Priority |
|-------|-------|-----------|------------|----------|
| 03-01 | OpenAI Protocol Authentication Header | Integration | Low | P1 |
| 03-02 | Anthropic Protocol Authentication Header | Integration | Low | P1 |
| 03-03 | Protocol-Aware Test Endpoint Routing | Integration | Medium | P1 |
| 03-04 | Clear Test Result Messaging | Integration | Low | P2 |

### Story 4: Protocol Information Display and Security

| AC ID | Title | Test Type | Complexity | Priority |
|-------|-------|-----------|------------|----------|
| 04-01 | Protocol Column in List Display | Unit | Low | P2 |
| 04-02 | Anthropic Credential Masking | Unit | Low | P1 |
| 04-03 | Empty Value Display | Unit | Low | P3 |

---

## Test Coverage Notes

- **Unit Tests:** 7 ACs require unit tests
- **Integration Tests:** 9 ACs require integration tests
- **E2E Tests:** 0 ACs require E2E tests
- **High Complexity:** 1 AC marked high complexity
- **Medium Complexity:** 7 ACs marked medium complexity
- **Low Complexity:** 8 ACs marked low complexity
