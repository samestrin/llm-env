#!/usr/bin/env bash

# Tests for protocol-specific variable export

load ../lib/bats_helpers

setup() {
    setup_test_env

    # Create test configuration with explicit protocol field
    local test_config='[openai_provider]
base_url = https://api.openai.com/v1
api_key_var = OPENAI_TEST_KEY
default_model = gpt-4
description = OpenAI provider with explicit protocol
enabled = true
protocol = openai
max_context_tokens = 1m
max_tool_use_concurrency = 5

[anthropic_provider]
base_url = https://api.anthropic.com
api_key_var = ANTHROPIC_TEST_KEY
auth_token_var = ANTHROPIC_TEST_TOKEN
default_model = claude-3
description = Anthropic provider
enabled = true
protocol = anthropic

[anthropic_gateway]
base_url = https://gateway.example.com/anthropic
api_key_var = ANTHROPIC_GATEWAY_KEY
default_model = glm-5
description = Third-party Anthropic gateway, key only
enabled = true
protocol = anthropic

[anthropic_real_keyonly]
base_url = https://api.anthropic.com/v1
api_key_var = ANTHROPIC_REAL_KEY
default_model = claude-sonnet-4
description = Real Anthropic API, key only (no auth token)
enabled = true
protocol = anthropic

[anthropic_1m]
base_url = https://gateway.example.com/anthropic
api_key_var = ANTHROPIC_GATEWAY_KEY
default_model = kimi-k2.5
description = Third-party gateway declaring a 1M window
enabled = true
protocol = anthropic
max_context_tokens = 1m

[provider_no_protocol]
base_url = https://api.noprotocol.com/v1
api_key_var = PROT_NO_PROTO_KEY
default_model = default-model-1
description = Provider without protocol field
enabled = true

[anthropic_conc5]
base_url = https://gateway.example.com/anthropic
api_key_var = ANTHROPIC_GATEWAY_KEY
default_model = kimi-k2.5
description = Third-party gateway declaring a concurrency cap
enabled = true
protocol = anthropic
max_tool_use_concurrency = 5

[group:mixed_windows]
providers = anthropic_1m,anthropic_gateway

[group:mixed_concurrency]
providers = anthropic_conc5,anthropic_gateway'

    create_test_config "$test_config"

    # Source the main script to load configuration
    # Configuration is automatically loaded when sourcing llm-env
    source "$BATS_TEST_DIRNAME/../../llm-env"
}

teardown() {
    teardown_test_env
    unset OPENAI_TEST_KEY ANTHROPIC_TEST_KEY ANTHROPIC_TEST_TOKEN PROT_NO_PROTO_KEY ANTHROPIC_GATEWAY_KEY ANTHROPIC_REAL_KEY
    unset OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL LLM_PROVIDER
    unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL ANTHROPIC_MODEL
    unset ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL
    unset ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_SUBAGENT_MODEL
    unset CLAUDE_CODE_MAX_CONTEXT_TOKENS
    unset CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY
}

@test "OpenAI protocol: exports OPENAI_API_KEY correctly" {
    # Set up environment with test key
    export OPENAI_TEST_KEY="sk-test-key-12345"

    # Call cmd_set for provider with protocol="openai"
    cmd_set "openai_provider"

    # Verify OPENAI_API_KEY is exported
    [ "$OPENAI_API_KEY" = "sk-test-key-12345" ]
}

@test "OpenAI protocol: exports OPENAI_BASE_URL correctly" {
    # Set up environment with test key
    export OPENAI_TEST_KEY="sk-test-key-12345"

    # Call cmd_set for provider with protocol="openai"
    cmd_set "openai_provider"

    # Verify OPENAI_BASE_URL is exported
    [ "$OPENAI_BASE_URL" = "https://api.openai.com/v1" ]
}

@test "OpenAI protocol: exports OPENAI_MODEL correctly" {
    # Set up environment with test key
    export OPENAI_TEST_KEY="sk-test-key-12345"

    # Call cmd_set for provider with protocol="openai"
    cmd_set "openai_provider"

    # Verify OPENAI_MODEL is exported
    [ "$OPENAI_MODEL" = "gpt-4" ]
}

@test "OpenAI protocol: partial config exports only available variables" {
    # Set up environment with test key
    export OPENAI_TEST_KEY="sk-test-key-12345"

    # Use the full openai_provider which has all fields
    cmd_set "openai_provider"
    [ "$OPENAI_API_KEY" = "sk-test-key-12345" ]
    [ "$OPENAI_BASE_URL" = "https://api.openai.com/v1" ]
    [ "$OPENAI_MODEL" = "gpt-4" ]
}

@test "Anthropic protocol: exports ANTHROPIC_API_KEY correctly" {
    # Set up environment with test credentials
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"
    export ANTHROPIC_TEST_TOKEN="anthropic-test-token-6789"

    # Call cmd_set for provider with protocol="anthropic"
    cmd_set "anthropic_provider"

    # Verify ANTHROPIC_API_KEY is exported
    [ "$ANTHROPIC_API_KEY" = "anthropic-test-key-12345" ]
}

@test "Anthropic protocol: exports ANTHROPIC_AUTH_TOKEN correctly" {
    # Set up environment with test credentials
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"
    export ANTHROPIC_TEST_TOKEN="anthropic-test-token-6789"

    # Call cmd_set for provider with protocol="anthropic"
    cmd_set "anthropic_provider"

    # Verify ANTHROPIC_AUTH_TOKEN is exported
    [ "$ANTHROPIC_AUTH_TOKEN" = "anthropic-test-token-6789" ]
}

@test "Anthropic protocol: mirrors API key into ANTHROPIC_AUTH_TOKEN for third-party gateway" {
    # Key-only config (no auth_token_var) against a non-Anthropic host: the
    # API key must be mirrored into ANTHROPIC_AUTH_TOKEN so Bearer-auth
    # gateways authenticate. Only fires when no explicit token is configured.
    unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL ANTHROPIC_MODEL
    export ANTHROPIC_GATEWAY_KEY="gateway-key-abc"

    cmd_set "anthropic_gateway"

    [ "$ANTHROPIC_API_KEY" = "gateway-key-abc" ]
    [ "$ANTHROPIC_AUTH_TOKEN" = "gateway-key-abc" ]
}

@test "Anthropic protocol: does not mirror AUTH_TOKEN for real api.anthropic.com" {
    # Key-only config against api.anthropic.com: the sk-ant-* key must NOT be
    # sent as a Bearer token (the real API expects it via x-api-key), so
    # ANTHROPIC_AUTH_TOKEN stays unset.
    unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL ANTHROPIC_MODEL
    export ANTHROPIC_REAL_KEY="sk-ant-api03-realkey"

    cmd_set "anthropic_real_keyonly"

    [ "$ANTHROPIC_API_KEY" = "sk-ant-api03-realkey" ]
    [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]
}

@test "Anthropic protocol: exports ANTHROPIC_BASE_URL correctly" {
    # Set up environment with test credentials
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"
    export ANTHROPIC_TEST_TOKEN="anthropic-test-token-6789"

    # Call cmd_set for provider with protocol="anthropic"
    cmd_set "anthropic_provider"

    # Verify ANTHROPIC_BASE_URL is exported
    [ "$ANTHROPIC_BASE_URL" = "https://api.anthropic.com" ]
}

@test "Anthropic protocol: exports ANTHROPIC_MODEL correctly" {
    # Set up environment with test credentials
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"
    export ANTHROPIC_TEST_TOKEN="anthropic-test-token-6789"

    # Call cmd_set for provider with protocol="anthropic"
    cmd_set "anthropic_provider"

    # Verify ANTHROPIC_MODEL is exported
    [ "$ANTHROPIC_MODEL" = "claude-3" ]
}

# INVERTED IN 1.7.0.
#
# These two tests previously asserted that switching protocol PRESERVED the
# other protocol's variables, under the name "Protocol coexistence". That was
# not a feature: leaving ANTHROPIC_BASE_URL and the CLAUDE_CODE_* overrides
# exported after switching to an OpenAI provider means Claude Code keeps
# routing to the old host, using the old credential, while the user believes
# they have switched. See tests/integration/test_env_isolation.bats for the
# full contract; these keep the original fixtures and call style.

@test "Protocol switch: openai->anthropic clears OPENAI_ variables" {
    export OPENAI_TEST_KEY="sk-test-key-12345"
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"
    export ANTHROPIC_TEST_TOKEN="anthropic-test-token-6789"

    cmd_set "openai_provider"
    [ -n "$OPENAI_API_KEY" ]

    cmd_set "anthropic_provider"

    # The previous protocol must be fully torn down.
    [ -z "${OPENAI_API_KEY:-}" ]
    [ -z "${OPENAI_BASE_URL:-}" ]
    [ -z "${OPENAI_MODEL:-}" ]

    # The newly selected protocol must be fully configured.
    [ -n "$ANTHROPIC_API_KEY" ]
    [ -n "$ANTHROPIC_AUTH_TOKEN" ]
    [ -n "$ANTHROPIC_BASE_URL" ]
    [ -n "$ANTHROPIC_MODEL" ]

    [ "$LLM_PROVIDER" = "anthropic_provider" ]
    [ "$LLM_PROTOCOL" = "anthropic" ]
}

@test "Protocol switch: anthropic->openai clears ANTHROPIC_ and CLAUDE_CODE_ variables" {
    export OPENAI_TEST_KEY="sk-test-key-12345"
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"
    export ANTHROPIC_TEST_TOKEN="anthropic-test-token-6789"

    cmd_set "anthropic_provider"
    [ -n "$ANTHROPIC_API_KEY" ]

    cmd_set "openai_provider"

    [ -z "${ANTHROPIC_API_KEY:-}" ]
    [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]
    [ -z "${ANTHROPIC_BASE_URL:-}" ]
    [ -z "${ANTHROPIC_MODEL:-}" ]
    # Claude Code reads these; leaving them set is the actual harm.
    [ -z "${ANTHROPIC_DEFAULT_OPUS_MODEL:-}" ]
    [ -z "${ANTHROPIC_DEFAULT_SONNET_MODEL:-}" ]
    [ -z "${ANTHROPIC_DEFAULT_HAIKU_MODEL:-}" ]
    [ -z "${CLAUDE_CODE_SUBAGENT_MODEL:-}" ]
    [ -z "${CLAUDE_CODE_MAX_CONTEXT_TOKENS:-}" ]

    [ -n "$OPENAI_API_KEY" ]
    [ -n "$OPENAI_BASE_URL" ]
    [ -n "$OPENAI_MODEL" ]

    [ "$LLM_PROVIDER" = "openai_provider" ]
    [ "$LLM_PROTOCOL" = "openai" ]
}

# ---- max_context_tokens -> CLAUDE_CODE_MAX_CONTEXT_TOKENS ----
#
# The key declares a third-party model's real context window so Claude Code can
# size auto-compact for a model it does not recognize. A stale value is worse
# than none: the session then overruns the real window and fails hard mid-task
# instead of merely printing the cosmetic warning the key exists to remove.

@test "max context: an anthropic provider with the key exports the expanded count" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    cmd_set "anthropic_1m"

    [ "$CLAUDE_CODE_MAX_CONTEXT_TOKENS" = "1000000" ]
}

@test "max context: an anthropic provider without the key exports nothing" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    cmd_set "anthropic_gateway"

    [ -z "${CLAUDE_CODE_MAX_CONTEXT_TOKENS:-}" ]
}

@test "max context: an openai provider never exports it even when configured" {
    # openai_provider carries max_context_tokens=1m in the fixture on purpose.
    # Testing an openai provider WITHOUT the key would prove nothing.
    export OPENAI_TEST_KEY="sk-test-key-12345"

    cmd_set "openai_provider"

    [ -z "${CLAUDE_CODE_MAX_CONTEXT_TOKENS:-}" ]
}

@test "max context: anthropic -> anthropic without the key drops the value" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    cmd_set "anthropic_1m"
    [ "$CLAUDE_CODE_MAX_CONTEXT_TOKENS" = "1000000" ]

    cmd_set "anthropic_gateway"
    [ -z "${CLAUDE_CODE_MAX_CONTEXT_TOKENS:-}" ]
}

@test "max context: a group member without the key does not inherit it" {
    # set_multiple_providers clears both protocols once and sets
    # __LLM_SET_ADDITIVE=1, so members never clear each other. Every other
    # anthropic variable survives that because it is exported unconditionally.
    # A conditional export without a matching unset leaves the first member's
    # window standing against the second member's model.
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    cmd_set "mixed_windows"

    [ "$ANTHROPIC_MODEL" = "glm-5" ]
    [ -z "${CLAUDE_CODE_MAX_CONTEXT_TOKENS:-}" ]
}

# ---- max_tool_use_concurrency -> CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY ----
#
# Same rationale and switch-path coverage as max_context_tokens above: a stale
# concurrency cap from a previous provider is worse than none.

@test "max concurrency: an anthropic provider with the key exports it" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    cmd_set "anthropic_conc5"

    [ "$CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY" = "5" ]
}

@test "max concurrency: an anthropic provider without the key exports nothing" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    cmd_set "anthropic_gateway"

    [ -z "${CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY:-}" ]
}

@test "max concurrency: an openai provider never exports it even when configured" {
    # openai_provider carries max_tool_use_concurrency=5 in the fixture on
    # purpose. Testing an openai provider WITHOUT the key would prove nothing.
    export OPENAI_TEST_KEY="sk-test-key-12345"

    cmd_set "openai_provider"

    [ -z "${CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY:-}" ]
}

@test "max concurrency: anthropic -> anthropic without the key drops the value" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    cmd_set "anthropic_conc5"
    [ "$CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY" = "5" ]

    cmd_set "anthropic_gateway"
    [ -z "${CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY:-}" ]
}

@test "max concurrency: a group member without the key does not inherit it" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    cmd_set "mixed_concurrency"

    [ "$ANTHROPIC_MODEL" = "glm-5" ]
    [ -z "${CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY:-}" ]
}

# ---- the "Additional Claude Code variables set" confirmation line ----
#
# Pinned by exact equality, not a substring glob: a glob cannot detect an
# appended field, which is precisely the change being guarded. This line is
# quoted in docs/claude-code-quickstart.md and had no test at all before, so
# any edit to it was invisible to CI.

_claude_code_line() {
    printf '%s\n' "$output" | grep 'Additional Claude Code variables set'
}

@test "max context: the Claude Code variables line is unchanged when the key is unset" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    run cmd_set "anthropic_gateway"
    [ "$status" -eq 0 ]

    local line
    line="$(_claude_code_line)"
    [ "$line" = "🔧 Additional Claude Code variables set: ANTHROPIC_DEFAULT_OPUS_MODEL=glm-5, ANTHROPIC_DEFAULT_SONNET_MODEL=glm-5, ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-5, CLAUDE_CODE_SUBAGENT_MODEL=glm-5" ]
}

@test "max context: the Claude Code variables line appends the token count when set" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    run cmd_set "anthropic_1m"
    [ "$status" -eq 0 ]

    local line
    line="$(_claude_code_line)"
    [ "$line" = "🔧 Additional Claude Code variables set: ANTHROPIC_DEFAULT_OPUS_MODEL=kimi-k2.5, ANTHROPIC_DEFAULT_SONNET_MODEL=kimi-k2.5, ANTHROPIC_DEFAULT_HAIKU_MODEL=kimi-k2.5, CLAUDE_CODE_SUBAGENT_MODEL=kimi-k2.5, CLAUDE_CODE_MAX_CONTEXT_TOKENS=1000000" ]
}

@test "max concurrency: the Claude Code variables line appends the concurrency cap when set" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    run cmd_set "anthropic_conc5"
    [ "$status" -eq 0 ]

    local line
    line="$(_claude_code_line)"
    [ "$line" = "🔧 Additional Claude Code variables set: ANTHROPIC_DEFAULT_OPUS_MODEL=kimi-k2.5, ANTHROPIC_DEFAULT_SONNET_MODEL=kimi-k2.5, ANTHROPIC_DEFAULT_HAIKU_MODEL=kimi-k2.5, CLAUDE_CODE_SUBAGENT_MODEL=kimi-k2.5, CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=5" ]
}

@test "No protocol field: defaults to openai behavior" {
    # Set up environment for provider without protocol field
    export PROT_NO_PROTO_KEY="sk-default-key-12345"

    # Set provider with no protocol field (should default to openai)
    cmd_set "provider_no_protocol"

    # Verify OPENAI_ variables are set (default behavior)
    [ -n "$OPENAI_API_KEY" ]
    [ "$OPENAI_API_KEY" = "sk-default-key-12345" ]
    [ -n "$OPENAI_BASE_URL" ]
    [ -n "$OPENAI_MODEL" ]
}

@test "Sourced script: exported variables persist in parent shell" {
    # Set up environment with test key
    export OPENAI_TEST_KEY="sk-test-key-12345"

    # Set provider in "sourced" context
    # In BATS, we're running in the same shell, so this should work
    cmd_set "openai_provider"

    # Verify variables are set in current scope
    [ "$OPENAI_API_KEY" = "sk-test-key-12345" ]
    [ "$OPENAI_BASE_URL" = "https://api.openai.com/v1" ]
    [ "$OPENAI_MODEL" = "gpt-4" ]
    [ "$LLM_PROVIDER" = "openai_provider" ]
}

@test "Sourced script: multiple set commands work in same session" {
    # Set up environment for both providers
    export OPENAI_TEST_KEY="sk-test-key-12345"
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"
    export ANTHROPIC_TEST_TOKEN="anthropic-test-token-6789"

    # Set OpenAI provider
    cmd_set "openai_provider"
    [ "$LLM_PROVIDER" = "openai_provider" ]
    [ "$OPENAI_API_KEY" = "sk-test-key-12345" ]

    # Set Anthropic (overwrites previous)
    cmd_set "anthropic_provider"
    [ "$LLM_PROVIDER" = "anthropic_provider" ]
    [ "$ANTHROPIC_API_KEY" = "anthropic-test-key-12345" ]

    # Set OpenAI again: switches the active provider AND tears down Anthropic.
    cmd_set "openai_provider"
    [ "$LLM_PROVIDER" = "openai_provider" ]
    [ "$OPENAI_API_KEY" = "sk-test-key-12345" ]
    [ -z "${ANTHROPIC_API_KEY:-}" ]  # only one protocol is live at a time
}

@test "OpenAI confirmation message includes protocol" {
    export OPENAI_TEST_KEY="sk-test-key-12345"

    run cmd_set "openai_provider"

    [ "$status" -eq 0 ]
    [[ "$output" =~ "protocol" ]] || [[ "$output" =~ "openai" ]]
}

@test "Anthropic confirmation message includes protocol" {
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"
    export ANTHROPIC_TEST_TOKEN="anthropic-test-token-6789"

    run cmd_set "anthropic_provider"

    [ "$status" -eq 0 ]
    [[ "$output" =~ "protocol" ]] || [[ "$output" =~ "anthropic" ]]
}

@test "cmd_show: displays only the active protocol after a switch" {
    # Set up environment for both providers
    export OPENAI_TEST_KEY="sk-test-key-12345"
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"
    export ANTHROPIC_TEST_TOKEN="anthropic-test-token-6789"

    # Set OpenAI first, then Anthropic
    cmd_set "openai_provider"
    cmd_set "anthropic_provider"

    run cmd_show

    [ "$status" -eq 0 ]

    # Active provider should be anthropic
    [[ "$output" =~ "anthropic_provider" ]]
    [[ "$output" =~ "LLM_PROTOCOL       = anthropic" ]]

    # Only the active protocol is shown. This test was named "displays both
    # protocols" and asserted the OPENAI_* block was still present after
    # switching -- which was a symptom of the leak, not a feature: those
    # variables pointed at the previous provider's host and credential.
    [[ "$output" =~ "ANTHROPIC_BASE_URL" ]]
    [[ "$output" =~ "ANTHROPIC_MODEL" ]]
    [[ "$output" =~ "ANTHROPIC_API_KEY" ]]
    [[ ! "$output" =~ "OPENAI_BASE_URL" ]]
    [[ ! "$output" =~ "OPENAI_API_KEY" ]]
}

# cmd_show is the only surface where a user can confirm the declared window
# actually landed -- `set` scrolls past, and a wrong value is otherwise silent
# until Claude Code overruns the real context.

@test "cmd_show: displays CLAUDE_CODE_MAX_CONTEXT_TOKENS when it is set" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    cmd_set "anthropic_1m"

    run cmd_show

    [ "$status" -eq 0 ]
    [[ "$output" == *"CLAUDE_CODE_MAX_CONTEXT_TOKENS = 1000000"* ]]
}

@test "cmd_show: omits CLAUDE_CODE_MAX_CONTEXT_TOKENS when it is unset" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    cmd_set "anthropic_gateway"

    run cmd_show

    [ "$status" -eq 0 ]
    [[ "$output" == *"ANTHROPIC_BASE_URL"* ]]
    [[ "$output" != *"MAX_CONTEXT_TOKENS"* ]]
}

@test "cmd_show: omits CLAUDE_CODE_MAX_CONTEXT_TOKENS under the openai protocol" {
    export OPENAI_TEST_KEY="sk-test-key-12345"

    cmd_set "openai_provider"

    run cmd_show

    [ "$status" -eq 0 ]
    [[ "$output" != *"MAX_CONTEXT_TOKENS"* ]]
}

@test "cmd_show: displays CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY when it is set" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    cmd_set "anthropic_conc5"

    run cmd_show

    [ "$status" -eq 0 ]
    [[ "$output" == *"CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY = 5"* ]]
}

@test "cmd_show: omits CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY when it is unset" {
    export ANTHROPIC_GATEWAY_KEY="gateway-key-12345"

    cmd_set "anthropic_gateway"

    run cmd_show

    [ "$status" -eq 0 ]
    [[ "$output" == *"ANTHROPIC_BASE_URL"* ]]
    [[ "$output" != *"MAX_TOOL_USE_CONCURRENCY"* ]]
}

@test "cmd_show: omits CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY under the openai protocol" {
    export OPENAI_TEST_KEY="sk-test-key-12345"

    cmd_set "openai_provider"

    run cmd_show

    [ "$status" -eq 0 ]
    [[ "$output" != *"MAX_TOOL_USE_CONCURRENCY"* ]]
}

@test "cmd_show: displays only active protocol when other is not configured" {
    # Set up only OpenAI
    export OPENAI_TEST_KEY="sk-test-key-12345"

    cmd_set "openai_provider"

    run cmd_show

    [ "$status" -eq 0 ]

    # OpenAI variables should be displayed
    [[ "$output" =~ "OPENAI_BASE_URL" ]]
    [[ "$output" =~ "OPENAI_MODEL" ]]

    # Anthropic variables should NOT be displayed
    [[ ! "$output" =~ "ANTHROPIC_BASE_URL" ]]
    [[ ! "$output" =~ "ANTHROPIC_MODEL" ]]
}
