## Overview

This plan extends the `llm-env` tool to support native Anthropic protocol in addition to the existing OpenAI-compatible protocol. This enables users to seamlessly switch between OpenAI-compatible tools and native Anthropic tools (like the Claude CLI) using the same command interface.

The feature introduces a `protocol` configuration field that determines which set of environment variables are exported:
- **Protocol `openai` (default):** Exports `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`
- **Protocol `anthropic`:** Exports `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_MODEL`

## Problem

Users who work with both OpenAI-compatible tools and native Anthropic tools cannot use `llm-env` to manage their Anthropic credentials. They must manually export variables or use a different tool, breaking the unified workflow `llm-env` aims to provide.

## Solution

Add a `protocol` configuration option to provider definitions that controls which environment variables are exported and which API headers are used for testing.

## Workflow Status
- [x] **Plan Created**
- [x] **User Stories** - 4 stories generated (01-protocol-configuration.md, 02-variable-switching.md, 03-api-testing.md, 04-protocol-display.md)
- [x] **Acceptance Criteria** - 16 ACs generated (S1:4, S2:5, S3:4, S4:3)
- [x] **Design Sprint** - sprint-design.md created with 5 implementation phases
- [ ] **Sprint Plan** - `/create-sprint @.planning/plans/active/1.0_anthropic_protocol_support`

## Timeline & Milestones

This is a Medium complexity feature estimated to require 4 user stories covering:
1. Protocol configuration parsing
2. Protocol-specific variable export
3. Protocol-aware API testing
4. Information display updates

## Resource Requirements

- **Development:** Bash scripting knowledge, familiarity with existing codebase patterns
- **Testing:** BATS framework (already in use)
- **Platform testing:** macOS (bash 3.2), Linux (bash 4+)

## Expected Outcomes

- Users can define Anthropic providers with `protocol=anthropic` in config
- Single `llm-env set` command switches protocols cleanly
- `llm-env test` uses correct headers per protocol
- Backward maintained - existing configs work unchanged
- Enables llm-env to become a true "Universal AI Switcher"

## Risk Summary

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| User confusion about which vars are set | Low | Medium | Clear output showing protocol |
| Breaking existing configs | Low | High | Default protocol to `openai` |
| Bash 3.2 compatibility issues | Low | Medium | Reuse existing compatibility patterns |

## Plan Assets
- [Original Request](original-requirements.md)
- [Plan](plan.md)
- [Metadata](metadata.md)
- [Codebase Discovery](codebase-discovery.json)
- [User Stories](user-stories/) (4 stories)
- [Acceptance Criteria](acceptance-criteria/) (13 ACs)

---

## Documentation References

See [`documentation/README.md`](documentation/README.md) for implementation guidance.

| Document | Priority |
|----------|----------|
| [Architecture & Bash Compatibility](documentation/architecture-bash-compat.md) | 🔴 CRITICAL |
| [TDD & Testing Strategy](documentation/tdd-testing-strategy.md) | 🔴 CRITICAL |
| [Coding Standards & Security](documentation/coding-standards-security.md) | 🟡 IMPORTANT |
| [Git Workflow & Quality Tools](documentation/git-workflow-quality.md) | 🟢 REFERENCE |
