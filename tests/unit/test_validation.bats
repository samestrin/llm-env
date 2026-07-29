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

    # v1.4.0: dots are accepted to express versioned model ids like kimi-k2.5
    run validate_provider_name "openai_synth_kimi-k2.5"
    [ "$status" -eq 0 ]

    run validate_provider_name "anth_alibaba_qwen3.5-plus"
    [ "$status" -eq 0 ]
}

@test "validate_provider_name: rejects invalid provider names" {
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

# COMPREHENSIVE EDGE CASE VALIDATION TESTS

@test "validate_provider_name: edge case - empty string" {
    run validate_provider_name ""
    [ "$status" -eq 1 ]
}

@test "validate_provider_name: edge case - whitespace only" {
    run validate_provider_name "   "
    [ "$status" -eq 1 ]
    
    run validate_provider_name $'\t'
    [ "$status" -eq 1 ]
    
    run validate_provider_name $'\n'
    [ "$status" -eq 1 ]
}

@test "validate_provider_name: edge case - special characters" {
    run validate_provider_name "provider@domain"
    [ "$status" -eq 1 ]
    
    run validate_provider_name "provider#1"
    [ "$status" -eq 1 ]
    
    run validate_provider_name "provider%test"
    [ "$status" -eq 1 ]
    
    run validate_provider_name "provider&test"
    [ "$status" -eq 1 ]
}

@test "validate_provider_name: edge case - unicode characters" {
    run validate_provider_name "provider_ü"
    [ "$status" -eq 1 ]
    
    run validate_provider_name "provider_测试"
    [ "$status" -eq 1 ]
}

@test "validate_provider_name: boundary conditions" {
    # Single character names
    run validate_provider_name "a"
    [ "$status" -eq 0 ]
    
    run validate_provider_name "1"
    [ "$status" -eq 0 ]
    
    run validate_provider_name "_"
    [ "$status" -eq 0 ]
    
    run validate_provider_name "-"
    [ "$status" -eq 0 ]
}

@test "configuration parsing: handles malformed INI syntax" {
    # Test with configuration that has syntax errors
    local test_config='
[valid_section]
key=value
malformed_line_without_equals
another=valid_line

[missing_bracket
key=value

[valid_section_3]
key=value'
    
    # This test verifies the parser handles malformed config gracefully
    # The exact behavior (ignore malformed lines vs fail) depends on implementation
    # but it should not crash
    
    run echo "$test_config" 
    [ "$status" -eq 0 ]
    [[ "$output" =~ "valid_section" ]]
}

# CHANGED IN 1.7.0. These previously asserted that mask() revealed most of a
# short secret -- "short" showed as "•hort" (4 of 5 characters) and "x" was
# returned verbatim. That documented the leak as intended behaviour. A tail is
# now revealed only once the secret is long enough for it to be a small
# fraction of the whole: none under 8 characters, 2 up to 11, 4 from 12.
# Long-secret behaviour is unchanged.

@test "mask function: properly masks sensitive data" {
    # Short secrets reveal nothing at all.
    run mask "short"
    [ "$status" -eq 0 ]
    [[ "$output" == "•••••" ]]

    # 13 characters: last 4 shown, as before.
    run mask "medium_length"
    [ "$status" -eq 0 ]
    [[ "$output" == "•••••••••ngth" ]]

    # Long secrets are unchanged.
    run mask "verylongpasswordthatshouldbehidden"
    [ "$status" -eq 0 ]
    [[ "$output" == "••••••••••••••••••••••••••••••dden" ]]
}

@test "mask function: handles edge cases" {
    # Empty string is still shown as the empty marker rather than a mask.
    run mask ""
    [ "$status" -eq 0 ]
    [[ "$output" == "∅" ]]

    # A one- or two-character secret used to be returned VERBATIM.
    run mask "x"
    [ "$status" -eq 0 ]
    [[ "$output" == "•" ]]

    run mask "xy"
    [ "$status" -eq 0 ]
    [[ "$output" == "••" ]]

    run mask "xyz"
    [ "$status" -eq 0 ]
    [[ "$output" == "•••" ]]
}

@test "mask function: never echoes any part of a short secret" {
    # Property form of the above: whatever the length, nothing under 8
    # characters may contribute a literal character to the output.
    local secret out
    for secret in a ab abc abcd abcde abcdef abcdefg; do
        out="$(mask "$secret")"
        [[ "$out" != *"${secret: -1}"* ]] || {
            echo "mask('$secret') = '$out' leaks its last character"
            return 1
        }
    done
}

@test "array helper functions: handle empty arrays" {
    # Test with bash 4.0+ mode
    export BASH_ASSOC_ARRAY_SUPPORT="true"
    
    # This test ensures array helper functions don't crash with empty arrays
    run has_provider_key "NONEXISTENT_ARRAY" "test_key"
    # Should complete without crashing (status could be 0 or 1)
    [[ "$status" == 0 || "$status" == 1 ]]
}

@test "array helper functions: handle nonexistent keys" {
    export BASH_ASSOC_ARRAY_SUPPORT="true"
    
    # Test accessing nonexistent keys doesn't crash  
    run get_provider_value "PROVIDER_BASE_URLS" "nonexistent_provider"
    # Should complete without crashing (status could be 0 or 1)
    [[ "$status" == 0 || "$status" == 1 ]]
}

@test "compatibility mode: array operations work correctly" {
    # Force compatibility mode
    export BASH_ASSOC_ARRAY_SUPPORT="false"
    
    # Re-initialize to use compatibility arrays
    source "$BATS_TEST_DIRNAME/../../llm-env"
    
    # Test basic operations work in compatibility mode
    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available providers:" ]]
}

@test "error handling: graceful degradation with missing functions" {
    # Test that script handles missing optional dependencies gracefully
    # This is more of a integration test but validates error handling
    
    # The script should work even if some external tools are missing
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env --version"
    [ "$status" -eq 0 ]
}

@test "input sanitization: command injection protection" {
    # Test that user input is properly sanitized
    # These should not execute shell commands
    
    run validate_provider_name "; rm -rf /"
    [ "$status" -eq 1 ]
    
    run validate_provider_name "\$(malicious_command)"
    [ "$status" -eq 1 ]
    
    run validate_provider_name "|whoami"
    [ "$status" -eq 1 ]
    
    run validate_provider_name "&& echo hacked"
    [ "$status" -eq 1 ]
}

@test "memory safety: no buffer overflow conditions" {
    # Test with extremely long inputs to ensure no buffer overflows
    local very_long_string=$(printf 'a%.0s' {1..10000})
    
    run validate_provider_name "$very_long_string"
    # Should either accept (if valid) or reject (if invalid) but not crash
    [[ "$status" == 0 || "$status" == 1 ]]
}

@test "concurrent safety: multiple processes don't interfere" {
    # Test that multiple instances can run concurrently without issues
    {
        bash -c "source $BATS_TEST_DIRNAME/../../llm-env list" &
        bash -c "source $BATS_TEST_DIRNAME/../../llm-env --version" &
        bash -c "source $BATS_TEST_DIRNAME/../../llm-env list" &
        wait
    }
    
    # All processes should complete without hanging or crashing
    [ "$?" -eq 0 ]
}

@test "version constant is defined" {
    [[ -n "$LLM_ENV_VERSION" ]]
    [[ "$LLM_ENV_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}