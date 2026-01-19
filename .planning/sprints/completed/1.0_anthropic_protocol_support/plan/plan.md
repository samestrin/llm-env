# Plan: Anthropic Protocol Support

## Metadata
**Plan Type:** feature
**Last Updated:** 2026-01-18
**Status:** Active

## Objectives
Extend `llm-env` to support the Anthropic protocol, enabling users to manage credentials for both OpenAI-compatible and native Anthropic tools (like `claude` CLI) using a single tool.

## Success Criteria
1.  **Configuration Support:**
    *   Config parser reads a `protocol` field (defaulting to `openai` for backward compatibility).
    *   Supports `protocol = anthropic`.

2.  **Variable Management:**
    *   `llm-env set` exports `OPENAI_*` variables for `protocol=openai`.
    *   `llm-env set` exports `ANTHROPIC_*` variables for `protocol=anthropic` (`ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_MODEL`).
    *   `llm-env set` unsets variables from the *inactive* protocol to ensure a clean environment.
    *   `llm-env unset` clears variables for *both* protocols.

3.  **Tool Compatibility:**
    *   `llm-env test` uses `Authorization: Bearer` for OpenAI protocol.
    *   `llm-env test` uses `x-api-key` for Anthropic protocol.

4.  **User Experience:**
    *   `llm-env list` displays the configured protocol for each provider.
    *   `llm-env show` masks sensitive Anthropic variables (`ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`).

## Implementation Strategy

### 1. Configuration Parsing
*   **Modify `load_config`**: Update the INI parser to recognize the `protocol` key.
*   **Default Behavior**: Ensure that if `protocol` is missing, it defaults to `openai`.
*   **Data Structure**: Store protocol information in the `PROVIDER_PROTOCOLS` associative array (or compatible bash 3.2 structure).

### 2. Variable Export Logic
*   **Update `cmd_set`**:
    *   Check the protocol for the selected provider.
    *   If `openai`: Export `OPENAI_*` and unset `ANTHROPIC_*`.
    *   If `anthropic`: Export `ANTHROPIC_*` and unset `OPENAI_*`.
    *   Export `LLM_PROVIDER` in both cases.

### 3. API Testing Support
*   **Update `cmd_test`**:
    *   Branch logic based on the active protocol.
    *   For Anthropic: Use `curl -H "x-api-key: ..."` and potentially adjust the validation endpoint (e.g., `/v1/models` vs `/v1/messages` if needed, though `models` is standard for checking auth).

### 4. Display and Security
*   **Update `cmd_list`**: Add a column or indicator for the protocol.
*   **Update `cmd_show`**:
    *   Logic to display Anthropic variables if they are set.
    *   Apply `mask()` function to `ANTHROPIC_API_KEY` and `ANTHROPIC_AUTH_TOKEN`.
*   **Update `cmd_unset`**: Ensure it iterates through and unsets all known variables for both protocols.

## Backlog

### User Stories
(See `user-stories/` directory for detailed files)
- **Completed**: 4 stories created

### Acceptance Criteria
(See `acceptance-criteria/` directory for detailed files)
- **Completed**: 16 ACs created

### Tasks
(Not applicable for `feature` plan type; see User Stories)

---

## Documentation References

See [`documentation/README.md`](documentation/README.md) for implementation guidance.

| Document | Priority | Section Coverage |
|----------|----------|------------------|
| [Architecture & Bash Compatibility](documentation/architecture-bash-compat.md) | 🔴 CRITICAL | Bash 3.2 compatibility, INI parsing, wrapper functions |
| [TDD & Testing Strategy](documentation/tdd-testing-strategy.md) | 🔴 CRITICAL | RED-GREEN-REFACTOR cycle, BATS framework patterns |
| [Coding Standards & Security](documentation/coding-standards-security.md) | 🟡 IMPORTANT | Naming conventions, security, variable masking |
| [Git Workflow & Quality Tools](documentation/git-workflow-quality.md) | 🟢 REFERENCE | TDD commit pattern, shellcheck/shfmt tools |
