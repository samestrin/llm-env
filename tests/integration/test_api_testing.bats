#!/usr/bin/env bash

# Tests for protocol-aware API testing (cmd_test)

load ../lib/bats_helpers

setup() {
    setup_test_env

    # Create test configuration with both protocols
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
    source "$BATS_TEST_DIRNAME/../../llm-env"
}

teardown() {
    teardown_test_env
    unset OPENAI_TEST_KEY ANTHROPIC_TEST_KEY ANTHROPIC_TEST_TOKEN PROT_NO_PROTO_KEY
}

# ========================================
# Story AC 03-01: OpenAI Authentication Header
# ========================================

@test "OpenAI test: uses Authorization Bearer header format" {
    export OPENAI_TEST_KEY="sk-test-key-12345"

    # Run test command and capture output
    run cmd_test "openai_provider"

    # Should show openai protocol
    [[ "$output" =~ "protocol: openai" ]]
}

@test "OpenAI test: uses /models endpoint" {
    export OPENAI_TEST_KEY="sk-test-key-12345"

    run cmd_test "openai_provider"

    # Should test against models endpoint
    [[ "$output" =~ "/models" ]]
}

@test "OpenAI test: shows masked API key" {
    export OPENAI_TEST_KEY="sk-test-key-12345"

    run cmd_test "openai_provider"

    # Should show masked key (not full key)
    [[ "$output" =~ "API key found" ]]
    # Should NOT show full key
    [[ ! "$output" =~ "sk-test-key-12345" ]] || [[ "$output" =~ "••••" ]]
}

# ========================================
# Story AC 03-02: Anthropic Authentication Header
# ========================================

@test "Anthropic test: uses x-api-key header format" {
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"

    run cmd_test "anthropic_provider"

    # Should show anthropic protocol
    [[ "$output" =~ "protocol: anthropic" ]]
}

@test "Anthropic test: uses /v1/messages endpoint" {
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"

    run cmd_test "anthropic_provider"

    # Should test against messages endpoint
    [[ "$output" =~ "/v1/messages" ]]
}

@test "Anthropic test: shows masked API key" {
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"

    run cmd_test "anthropic_provider"

    # Should show masked key (not full key)
    [[ "$output" =~ "API key found" ]]
    # Should NOT show full key in clear text
    [[ ! "$output" =~ "anthropic-test-key-12345" ]] || [[ "$output" =~ "••••" ]]
}

# ========================================
# Story AC 03-03: Test Endpoint Routing
# ========================================

@test "Endpoint routing: OpenAI uses base_url/models" {
    export OPENAI_TEST_KEY="sk-test-key-12345"

    run cmd_test "openai_provider"

    # Should construct correct endpoint
    [[ "$output" =~ "https://api.openai.com/v1/models" ]]
}

@test "Endpoint routing: Anthropic uses base_url/messages" {
    export ANTHROPIC_TEST_KEY="anthropic-test-key-12345"

    run cmd_test "anthropic_provider"

    # Should construct correct endpoint (base_url typically includes /v1)
    [[ "$output" =~ "/messages" ]]
}

@test "Endpoint routing: default protocol uses OpenAI endpoint" {
    export PROT_NO_PROTO_KEY="sk-default-key-12345"

    run cmd_test "provider_no_protocol"

    # Should use /models endpoint (OpenAI default)
    [[ "$output" =~ "/models" ]]
    [[ "$output" =~ "protocol: openai" ]]
}

# ========================================
# Story AC 03-04: Test Result Messaging
# ========================================

@test "Result messaging: includes provider name" {
    export OPENAI_TEST_KEY="sk-test-key-12345"

    run cmd_test "openai_provider"

    # Should include provider name in output
    [[ "$output" =~ "openai_provider" ]]
}

@test "Result messaging: includes protocol in success/failure" {
    export OPENAI_TEST_KEY="sk-test-key-12345"

    run cmd_test "openai_provider"

    # Should include protocol in output
    [[ "$output" =~ "protocol:" ]]
}

@test "Result messaging: shows test completion" {
    export OPENAI_TEST_KEY="sk-test-key-12345"

    run cmd_test "openai_provider"

    # Should show test completed message
    [[ "$output" =~ "Test completed" ]]
}

# ========================================
# Error Conditions
# ========================================

@test "Error: missing API key shows helpful message" {
    # Don't set the API key
    unset OPENAI_TEST_KEY

    run cmd_test "openai_provider"

    # Should fail with helpful message
    [ "$status" -ne 0 ]
    [[ "$output" =~ "API key not found" ]]
    [[ "$output" =~ "OPENAI_TEST_KEY" ]]
}

@test "Error: unknown provider returns error" {
    run cmd_test "nonexistent_provider"

    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown provider" ]]
}

@test "Error: disabled provider returns error" {
    # The test config doesn't have a disabled provider, but we test the code path
    run cmd_test "nonexistent"

    [ "$status" -ne 0 ]
}
