# Feature Request: Anthropic Protocol Support

## Context

`llm-env` currently operates as an "OpenAI Switcher," mapping various provider keys (Cerebras, Groq, etc.) to the standard `OPENAI_*` environment variables. However, tools like the `claude` CLI and native Anthropic SDKs rely on `ANTHROPIC_*` variables (`ANTHROPIC_API_KEY`, `ANTHROPIC_BASE_URL`, etc.) and do not use the OpenAI compatibility layer.

## Problem Statement

Users who work with both OpenAI-compatible tools and native Anthropic tools (like `claude` CLI) currently cannot use `llm-env` to manage their Anthropic credentials. They must manually export variables or use a different tool, breaking the unified workflow `llm-env` aims to provide.

## Proposed Solution

Extend `llm-env` to support a new `protocol` configuration option.
- **Protocol `openai` (default):** continues to set `OPENAI_*` variables.
- **Protocol `anthropic`:** sets `ANTHROPIC_*` variables.

This allows users to define providers like `my-claude` in their config and switch to them just as easily as they switch to `gpt-4`.

## User Personas

### Primary: The Hybrid Developer
- Uses `curl` or Python scripts with OpenAI-compatible endpoints for some tasks.
- Uses `claude` CLI for coding assistance or interacting with Claude 3 Opus.
- Wants a single command (`llm-env set`) to switch contexts without remembering variable names.

## User Journeys

### Switching to Claude
1. User adds a custom provider to `~/.config/llm-env/config.conf` with `protocol=anthropic`.
2. User runs `llm-env set my-claude`.
3. `llm-env` detects the protocol.
4. `llm-env` exports `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_MODEL`.
5. `llm-env` unsets `OPENAI_API_KEY`, etc. (to prevent confusion).
6. User runs `claude` CLI and it just works.

### Testing Connectivity
1. User runs `llm-env test my-claude`.
2. `llm-env` sees it's an Anthropic provider.
3. `llm-env` sends a request to `$BASE_URL/v1/models` using `x-api-key` header (instead of Bearer token).
4. Connectivity is verified.

## Success Criteria

### Functional
- [ ] Config parser reads `protocol` field (defaulting to `openai`).
- [ ] `llm-env set` exports correct variables based on protocol.
    - [ ] `openai`: `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`
    - [ ] `anthropic`: `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_MODEL`
- [ ] `llm-env set` unsets variables from the *other* protocol to keep environment clean.
- [ ] `llm-env test` uses correct headers and validation for Anthropic endpoints.
- [ ] `llm-env unset` clears all variables (both OpenAI and Anthropic).
- [ ] `llm-env list` shows protocol information (maybe a column or flag).

### Business
- [ ] Enables `llm-env` to become a true "Universal AI Switcher".
- [ ] Supports the growing ecosystem of Anthropic-native tools.

## Technical Constraints

- Must maintain backward compatibility for existing config files (default to `openai` protocol).
- Must work in Bash 3.2+ (macOS default).
- Configuration format is INI-style; new field must be optional.

## Non-Functional Requirements

### Performance
- No noticeable slowdown in shell startup or switching time.

### Security
- `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY` must be masked in `llm-env show` output.

## Out of Scope

- Setting *both* sets of variables simultaneously (unless we decide to support a "bridge" mode later, but for now we stick to strict protocol switching).
- Supporting other proprietary protocols (e.g., Google Vertex AI native auth) in this sprint.

## Dependencies

- None.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| User confusion about which vars are set | Low | Medium | Clear output in `llm-env set` showing exactly what was set. |
| Breaking existing configs | Low | High | Default `protocol` to `openai` if missing. |
