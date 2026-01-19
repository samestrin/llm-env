# User Story 2: Protocol-Specific Variable Export

**Plan:** [1.0: Anthropic Protocol Support](../plan.md)

## User Story

**As a** hybrid developer switching between OpenAI-compatible and native Anthropic tools
**I want** llm-env to automatically export the correct protocol's variables when I set a provider
**So that** my environment is always configured correctly without manual variable management or conflicts

## Story Context

- **Background:** Different tools require different environment variable sets. OpenAI SDKs use OPENAI_API_KEY, OPENAI_BASE_URL, OPENAI_MODEL. Native Anthropic tools require ANTHROPIC_API_KEY, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_BASE_URL, ANTHROPIC_MODEL. Having both sets active simultaneously can cause confusion and tool misbehavior.
- **Assumptions:** User has set appropriate API keys in their environment (e.g., LLM_OPENAI_API_KEY, LLM_ANTHROPIC_API_KEY). Protocol field has been parsed from config (Story 1).
- **Constraints:** Must unset variables from other protocol to prevent conflicts. Must work in sourced environment (no set -e). Must maintain existing behavior for openai protocol.

## Story Details

| Field | Value |
|-------|-------|
| **Priority** | High |
| **Effort Estimate** | M |
| **Dependencies** | Story 1 (Protocol Configuration) |

## Success Criteria (SMART Format)

- **Specific:** `llm-env set <provider>` exports correct variables based on provider's protocol
- **Measurable:** Running `env | grep -E 'OPENAI_|ANTHROPIC_'` shows only active protocol's variables
- **Achievable:** Extend existing cmd_set() with protocol-based branching logic
- **Relevant:** Core feature enabling seamless tool switching
- **Time-bound:** 1-2 days implementation time

## Acceptance Criteria

| AC | Title | Type |
|----|-------|------|
| [02-01-openai-protocol-export.md](../acceptance-criteria/02-01-openai-protocol-export.md) | OpenAI Protocol Variable Export | Integration |
| [02-02-anthropic-protocol-export.md](../acceptance-criteria/02-02-anthropic-protocol-export.md) | Anthropic Protocol Variable Export | Integration |
| [02-03-protocol-cleanup.md](../acceptance-criteria/02-03-protocol-cleanup.md) | Protocol Cleanup on Provider Switch | Integration |
| [02-04-protocol-confirmation-message.md](../acceptance-criteria/02-04-protocol-confirmation-message.md) | Protocol Confirmation Output Message | Integration |
| [02-05-sourced-script-behavior.md](../acceptance-criteria/02-05-sourced-script-behavior.md) | Sourced Script Environment Behavior | Integration |
| [02-06-protocol-unset-behavior.md](../acceptance-criteria/02-06-protocol-unset-behavior.md) | Protocol Unset Behavior | Integration |

<details>
<summary>Original Criteria Overview</summary>

1. OpenAI protocol exports: OPENAI_API_KEY, OPENAI_BASE_URL, OPENAI_MODEL, LLM_PROVIDER
2. Anthropic protocol exports: ANTHROPIC_API_KEY, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_BASE_URL, ANTHROPIC_MODEL, LLM_PROVIDER
3. Setting a provider unsets variables from the other protocol
4. Output message indicates which protocol is active
5. `llm-env set` honors existing environment behavior (sourced script)
6. `llm-env unset` clears variables for all protocols

</details>

## Technical Considerations

- **Implementation Notes:** Modify cmd_set() (llm-env:587-653) to read protocol from PROVIDER_PROTOCOLS and branch logic. Add unset statements for opposite protocol's variables.
- **Integration Points:** cmd_set() function, PROVIDER_PROTOCOLS array, get_provider_value() wrapper
- **Data Requirements:** Protocol value from config, API key environment variable names

## Potential Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| User confusion about which vars are set | Medium | Clear output message showing active protocol and exported variables |
| Accidentally unsetting user-set variables | Low | Only unset variables from opposite protocol, not arbitrary ANTHROPIC_/OPENAI_ vars |

---

**Created:** January 18, 2026 05:44:07PM
**Status:** Draft - Awaiting Acceptance Criteria
