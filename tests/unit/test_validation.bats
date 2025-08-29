#!/usr/bin/env bats

# Unit tests for input validation functions

setup() {
    # Source the main script to access functions
    source "$BATS_TEST_DIRNAME/../../llm-env"
}

@test "validate_provider_name: accepts valid provider names" {
    run validate_provider_name "cerebras"
    [ "$status" -eq 0 ]
    
    run validate_provider_name "openai-v2"
    [ "$status" -eq 0 ]
    
    run validate_provider_name "groq_fast"
    [ "$status" -eq 0 ]
    
    run validate_provider_name "provider123"
    [ "$status" -eq 0 ]
}

@test "validate_provider_name: rejects invalid provider names" {
    run validate_provider_name "invalid.provider"
    [ "$status" -eq 1 ]
    
    run validate_provider_name "provider with spaces"
    [ "$status" -eq 1 ]
    
    run validate_provider_name "provider@special"
    [ "$status" -eq 1 ]
    
    run validate_provider_name ""
    [ "$status" -eq 1 ]
    
    run validate_provider_name "provider/slash"
    [ "$status" -eq 1 ]
}

@test "validate_provider_name: handles edge cases" {
    run validate_provider_name "a"
    [ "$status" -eq 0 ]
    
    run validate_provider_name "a-b_c123"
    [ "$status" -eq 0 ]
    
    # Test very long name
    local long_name="a$(printf 'b%.0s' {1..100})"
    run validate_provider_name "$long_name"
    [ "$status" -eq 0 ]
}

@test "debug function: outputs when LLM_ENV_DEBUG=1" {
    export LLM_ENV_DEBUG=1
    run debug "test message"
    [ "$status" -eq 0 ]
    [[ "$output" == "[DEBUG] test message" ]]
}

@test "debug function: silent when LLM_ENV_DEBUG=0" {
    export LLM_ENV_DEBUG=0
    run debug "test message"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "debug function: silent when LLM_ENV_DEBUG unset" {
    unset LLM_ENV_DEBUG
    run debug "test message"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "version constant is defined" {
    [[ -n "$VERSION" ]]
    [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}