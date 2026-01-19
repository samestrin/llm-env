# User Story 4: Protocol Information Display and Security

**Plan:** [1.0: Anthropic Protocol Support](../plan.md)

## User Story

**As a** developer managing multiple LLM providers in llm-env
**I want** to see protocol information when listing providers and have sensitive Anthropic credentials masked
**So that** I can quickly identify provider configurations without exposing secrets

## Story Context

- **Background:** The `llm-env list` command shows available providers but currently doesn't indicate which protocol each uses. The `llm-env show` command displays current configuration including sensitive values. Supporting protocol display helps users understand their setup. Masking sensitive values prevents credential exposure in logs, screenshots, or shared sessions.
- **Assumptions:** Users expect consistent output format with existing commands. The mask() function exists and is tested (llm-env:513-532).
- **Constraints:** Masking must apply consistently to ANTHROPIC_API_KEY and ANTHROPIC_AUTH_TOKEN. Protocol display should fit in existing output format.

## Story Details

| Field | Value |
|-------|-------|
| **Priority** | Medium |
| **Effort Estimate** | S |
| **Dependencies** | Story 1 (Protocol Configuration), Story 2 (Variable Switching) |

## Success Criteria (SMART Format)

- **Specific:** `llm-env list` displays protocol for each provider, `llm-env show` masks Anthropic credentials
- **Measurable:** Output includes "Protocol: openai" or "Protocol: anthropic" columns. Sensitive values show as "••••7890"
- **Achievable:** Extend existing cmd_list() with protocol column, extend cmd_show() with masking for ANTHROPIC_*
- **Relevant:** Improves usability and security of tool
- **Time-bound:** 0.5-1 day implementation time

## Acceptance Criteria

| AC | Title | Type |
|----|-------|------|
| [04-01-protocol-list-display.md](../acceptance-criteria/04-01-protocol-list-display.md) | Protocol Column in List Display | Unit |
| [04-02-anthropic-credential-masking.md](../acceptance-criteria/04-02-anthropic-credential-masking.md) | Anthropic Credential Masking | Unit |
| [04-03-empty-value-display.md](../acceptance-criteria/04-03-empty-value-display.md) | Empty Value Display | Unit |

<details>
<summary>Original Criteria Overview</summary>

1. `llm-env list` displays protocol column for each provider
2. `llm-env list --all` shows protocol for all available providers
3. `llm-env show` displays ANTHROPIC_API_KEY with masking applied
4. `llm-env show` displays ANTHROPIC_AUTH_TOKEN with masking applied
5. Masking format matches existing mask() function output (••••last4)
6. Empty values display as "∅" (null symbol)

</details>

## Technical Considerations

- **Implementation Notes:** Modify cmd_list() (llm-env:666-716) to include protocol column from PROVIDER_PROTOCOLS. Modify cmd_show() (llm-env:718-733) to apply mask() to ANTHROPIC_API_KEY and ANTHROPIC_AUTH_TOKEN.
- **Integration Points:** cmd_list() function, cmd_show() function, mask() function (llm-env:643-662)
- **Data Requirements:** Protocol value, ANTHROPIC_* environment variable values

## Potential Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Display formatting issues on narrow terminals | Low | Test with various terminal widths, use table format that adapts |
| Missing protocol in list display | Low | Default to 'openai' label if not explicitly set |

---

**Created:** January 18, 2026 05:44:07PM
**Status:** Draft - Awaiting Acceptance Criteria
