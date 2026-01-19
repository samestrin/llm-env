# User Story 3: Protocol-Aware API Testing

**Plan:** [1.0: Anthropic Protocol Support](../plan.md)

## User Story

**As a** developer configuring a new LLM provider in llm-env
**I want** to test provider connectivity using protocol-appropriate authentication headers
**So that** I can verify my API credentials work correctly before using the provider in tools

## Story Context

- **Background:** The `llm-env test` command validates API connectivity by making a request to the provider's endpoint. Different APIs require different authentication headers: OpenAI-compatible APIs use `Authorization: Bearer {api_key}`, while Anthropic's API uses `x-api-key: {api_key}`. Using the wrong header causes authentication failures.
- **Assumptions:** User has valid API key set for the provider. Provider endpoint is reachable via curl.
- **Constraints:** Must detect provider protocol and use correct header. Must maintain existing test endpoint behavior for openai protocol. Must handle both success and failure cases appropriately.

## Story Details

| Field | Value |
|-------|-------|
| **Priority** | High |
| **Effort Estimate** | M |
| **Dependencies** | Story 1 (Protocol Configuration), Story 2 (Variable Switching) |

## Success Criteria (SMART Format)

- **Specific:** `llm-env test <provider>` uses correct authentication header based on provider's protocol
- **Measurable:** Testing an anthropic protocol provider with x-api-key header succeeds. Testing an openai provider with Authorization header succeeds.
- **Achievable:** Extend existing cmd_test() (llm-env:974-1079) with protocol detection
- **Relevant:** Enables validation of credentials for both protocol types
- **Time-bound:** 0.5-1 day implementation time

## Acceptance Criteria

| AC | Title | Type |
|----|-------|------|
| [03-01-openai-authentication-header.md](../acceptance-criteria/03-01-openai-authentication-header.md) | OpenAI Protocol Authentication Header | Integration |
| [03-02-anthropic-authentication-header.md](../acceptance-criteria/03-02-anthropic-authentication-header.md) | Anthropic Protocol Authentication Header | Integration |
| [03-03-test-endpoint-routing.md](../acceptance-criteria/03-03-test-endpoint-routing.md) | Protocol-Aware Test Endpoint Routing | Integration |
| [03-04-test-result-messaging.md](../acceptance-criteria/03-04-test-result-messaging.md) | Clear Test Result Messaging | Integration |

<details>
<summary>Original Criteria Overview</summary>

1. OpenAI protocol uses `Authorization: Bearer {api_key}` header for test request
2. Anthropic protocol uses `x-api-key: {api_key}` header for test request
3. Test endpoint remains consistent (e.g., /models or /v1/models based on provider)
4. Success/failure messages clearly indicate test result
5. Test command reads protocol from current provider configuration

_Detailed AC: `/create-acceptance-criteria @.planning/plans/active/1.0_anthropic_protocol_support`_

</details>

## Technical Considerations

- **Implementation Notes:** Modify cmd_test() to read protocol from PROVIDER_PROTOCOLS. Use conditional header construction based on protocol value.
- **Integration Points:** cmd_test() function, PROVIDER_PROTOCOLS array
- **Data Requirements:** Protocol value, base URL, API key from environment

## Potential Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Different test endpoint paths between protocols | Low | Use provider-configured endpoint path; document if variants needed |

---

**Created:** January 18, 2026 05:44:07PM
**Status:** Draft - Awaiting Acceptance Criteria
