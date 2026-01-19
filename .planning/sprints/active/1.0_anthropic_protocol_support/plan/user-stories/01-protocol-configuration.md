# User Story 1: Protocol Configuration Parsing

**Plan:** [1.0: Anthropic Protocol Support](../plan.md)

## User Story

**As a** hybrid developer using both OpenAI-compatible tools and native Anthropic tools
**I want** to specify a protocol type in my llm-env configuration files
**So that** llm-env knows which set of environment variables to export for each provider

## Story Context

- **Background:** llm-env currently assumes all providers use OpenAI-compatible environment variables. Native Anthropic tools require ANTHROPIC_* variables instead. Adding a protocol field allows users to define which variable set each provider uses.
- **Assumptions:** Users understand INI-style configuration format. Existing configurations without protocol field should continue working (backward compatibility).
- **Constraints:** Must default to 'openai' for backward compatibility. Must work with Bash 3.2+ (macOS default). Configuration format remains INI-style.

## Story Details

| Field | Value |
|-------|-------|
| **Priority** | High |
| **Effort Estimate** | M |
| **Dependencies** | None |

## Success Criteria (SMART Format)

- **Specific:** Config parser recognizes and reads `protocol` field from provider sections
- **Measurable:** All provider configurations with or without protocol field parse successfully
- **Achievable:** Extends existing INI parser case statement with protocol handling
- **Relevant:** Enables all subsequent protocol-specific functionality
- **Time-bound:** 1-2 days implementation time

## Acceptance Criteria

| AC | Title | Type |
|----|-------|------|
| [01-01-protocol-field-parsing.md](../acceptance-criteria/01-01-protocol-field-parsing.md) | Protocol Field Parsing | Unit |
| [01-02-default-protocol-values.md](../acceptance-criteria/01-02-default-protocol-values.md) | Default Protocol Values | Unit |
| [01-03-protocol-storage-provider-protocols.md](../acceptance-criteria/01-03-protocol-storage-provider-protocols.md) | Protocol Storage in PROVIDER_PROTOCOLS | Unit |
| [01-04-invalid-protocol-validation.md](../acceptance-criteria/01-04-invalid-protocol-validation.md) | Invalid Protocol Validation | Unit |

<details>
<summary>Original Criteria Overview</summary>

1. Config parser reads `protocol` field from provider configuration sections
2. Missing protocol field defaults to 'openai' for backward compatibility
3. Protocol value is stored in PROVIDER_PROTOCOLS associative array (or Bash 3.2 equivalent)
4. Invalid protocol values are rejected with clear error message

</details>

## Technical Considerations

- **Implementation Notes:** Add 'protocol' case statement to load_config() function (llm-env:309-380). Use wrapper functions (set_provider_value/get_provider_value) for Bash 3.2 compatibility.
- **Integration Points:** load_config() function, PROVIDER_PROTOCOLS array declaration in init_config()
- **Data Requirements:** New PROVIDER_PROTOCOLS associative array storing protocol value per provider

## Potential Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing configs | High | Default missing protocol to 'openai' |
| Bash 3.2 compatibility issues | Medium | Use existing wrapper functions for PROVIDER_PROTOCOLS |

---

**Created:** January 18, 2026 05:44:07PM
**Status:** Draft - Awaiting Acceptance Criteria
