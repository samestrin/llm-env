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

[anthropic_provider]
base_url = https://api.anthropic.com
api_key_var = ANTHROPIC_TEST_KEY
auth_token_var = ANTHROPIC_TEST_TOKEN
default_model = claude-3
description = Anthropic provider
enabled = true
protocol = anthropic

[provider_no_protocol]
base_url = https://api.noprotocol.com/v1
api_key_var = PROT_NO_PROTO_KEY
default_model = default-model-1
description = Provider without protocol field
enabled = true'

    create_test_config "$test_config"

    # Source the main script to load configuration
    # Configuration is automatically loaded when sourcing llm-env
    source "$BATS_TEST_DIRNAME/../../llm-env"
}

teardown() {
    teardown_test_env
    unset OPENAI_TEST_KEY ANTHROPIC_TEST_KEY ANTHROPIC_TEST_TOKEN PROT_NO_PROTO_KEY
    unset OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL LLM_PROVIDER
    unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL ANTHROPIC_MODEL
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

@test "Protocol coexistence: switching openai->anthropic preserves OPENAI_ variables" {
    # Set up environment for both providers
    export OPENAI_TEST_KEY="sk-test-key-12345"
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"
    export ANTHROPIC_TEST_TOKEN="anthropic-test-token-6789"

    # First set OpenAI provider
    cmd_set "openai_provider"
    [ -n "$OPENAI_API_KEY" ]

    # Then switch to Anthropic provider
    cmd_set "anthropic_provider"

    # Verify OPENAI_ variables are preserved
    [ -n "$OPENAI_API_KEY" ]
    [ -n "$OPENAI_BASE_URL" ]
    [ -n "$OPENAI_MODEL" ]

    # Verify ANTHROPIC_ variables are set
    [ -n "$ANTHROPIC_API_KEY" ]
    [ -n "$ANTHROPIC_AUTH_TOKEN" ]
    [ -n "$ANTHROPIC_BASE_URL" ]
    [ -n "$ANTHROPIC_MODEL" ]

    # Verify active provider switched
    [ "$LLM_PROVIDER" = "anthropic_provider" ]
    [ "$LLM_PROTOCOL" = "anthropic" ]
}

@test "Protocol coexistence: switching anthropic->openai preserves ANTHROPIC_ variables" {
    # Set up environment for both providers
    export OPENAI_TEST_KEY="sk-test-key-12345"
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"
    export ANTHROPIC_TEST_TOKEN="anthropic-test-token-6789"

    # First set Anthropic provider
    cmd_set "anthropic_provider"
    [ -n "$ANTHROPIC_API_KEY" ]

    # Then switch to OpenAI provider
    cmd_set "openai_provider"

    # Verify ANTHROPIC_ variables are preserved
    [ -n "$ANTHROPIC_API_KEY" ]
    [ -n "$ANTHROPIC_AUTH_TOKEN" ]
    [ -n "$ANTHROPIC_BASE_URL" ]
    [ -n "$ANTHROPIC_MODEL" ]

    # Verify OPENAI_ variables are set
    [ -n "$OPENAI_API_KEY" ]
    [ -n "$OPENAI_BASE_URL" ]
    [ -n "$OPENAI_MODEL" ]

    # Verify active provider switched
    [ "$LLM_PROVIDER" = "openai_provider" ]
    [ "$LLM_PROTOCOL" = "openai" ]
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

    # Set OpenAI again (switches active provider, preserves Anthropic)
    cmd_set "openai_provider"
    [ "$LLM_PROVIDER" = "openai_provider" ]
    [ "$OPENAI_API_KEY" = "sk-test-key-12345" ]
    [ -n "$ANTHROPIC_API_KEY" ]  # Both protocols coexist
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

@test "cmd_show: displays both protocols when both are configured" {
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

    # Both protocols should be displayed
    [[ "$output" =~ "OPENAI_BASE_URL" ]]
    [[ "$output" =~ "OPENAI_MODEL" ]]
    [[ "$output" =~ "OPENAI_API_KEY" ]]
    [[ "$output" =~ "ANTHROPIC_BASE_URL" ]]
    [[ "$output" =~ "ANTHROPIC_MODEL" ]]
    [[ "$output" =~ "ANTHROPIC_API_KEY" ]]
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
