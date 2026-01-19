# Original Requirements

**Date:** January 18, 2026 04:28:21PM

**Command:** /init-plan .planning/preplans/active/01-anthropic-support.md

**Target:** `.planning/preplans/active/01-anthropic-support.md`

---

## Content

[Full input content preserved in original-requirements-uncompressed.md due to length constraints. This document contains the critical extracted requirements below.]

---

## Critical Extracted Requirements

### Problem Statement
Users who work with both OpenAI-compatible tools and native Anthropic tools (like `claude` CLI) currently cannot use `llm-env` to manage their Anthropic credentials. They must manually export variables or use a different tool, breaking the unified workflow `llm-env` aims to provide.

### Proposed Solution
Extend `llm-env` to support a new `protocol` configuration option:
- **Protocol `openai` (default):** continues to set `OPENAI_*` variables
- **Protocol `anthropic`:** sets `ANTHROPIC_*` variables

### Success Criteria

**Functional:**
- Config parser reads `protocol` field (defaulting to `openai`)
- `llm-env set` exports correct variables based on protocol:
  - `openai`: `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`
  - `anthropic`: `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_MODEL`
- `llm-env set` unsets variables from the *other* protocol to keep environment clean
- `llm-env test` uses correct headers and validation for Anthropic endpoints
- `llm-env unset` clears all variables (both OpenAI and Anthropic)
- `llm-env list` shows protocol information

**Business:**
- Enables `llm-env` to become a true "Universal AI Switcher"
- Supports the growing ecosystem of Anthropic-native tools

### Technical Constraints
- Must maintain backward compatibility for existing config files (default to `openai` protocol)
- Must work in Bash 3.2+ (macOS default)
- Configuration format is INI-style; new field must be optional

### Non-Functional Requirements

**Performance:**
- No noticeable slowdown in shell startup or switching time

**Security:**
- `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY` must be masked in `llm-env show` output

### Out of Scope
- Setting *both* sets of variables simultaneously
- Supporting other proprietary protocols (e.g., Google Vertex AI native auth) in this sprint

**Note:** This is a feature plan that requires user stories and acceptance criteria.
