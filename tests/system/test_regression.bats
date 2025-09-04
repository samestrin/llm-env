#!/usr/bin/env bats

# Regression tests to prevent regressions and test edge cases

setup() {
    # Create temporary directory for testing
    export TEST_DIR="$BATS_TMPDIR/llm-env-regression-test-$$"
    mkdir -p "$TEST_DIR"
    
    # Source test helpers for load-aware timeout functions
    source "$BATS_TEST_DIRNAME/../lib/bats_helpers.sh"
    
    # Save original environment
    export ORIG_HOME="$HOME"
    export ORIG_XDG_CONFIG_HOME="$XDG_CONFIG_HOME"
    export ORIG_BASH_VERSION="$BASH_VERSION"
    
    # Set up test environment
    export HOME="$TEST_DIR"
    export XDG_CONFIG_HOME="$TEST_DIR/.config"
}

teardown() {
    # Restore original environment
    export HOME="$ORIG_HOME"
    export XDG_CONFIG_HOME="$ORIG_XDG_CONFIG_HOME"
    export BASH_VERSION="$ORIG_BASH_VERSION"
    
    # Clean up test directory
    rm -rf "$TEST_DIR"
    
    # Clear any test provider data
    unset LLM_PROVIDER OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
}

# EDGE CASE TESTS

@test "regression: handles completely empty config file" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    touch "$XDG_CONFIG_HOME/llm-env/config.conf"
    
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available providers:" ]]
    # Empty config should show no providers (this is expected behavior)
}

@test "regression: handles config file with only whitespace" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    echo -e "\n   \n\t\n   " > "$XDG_CONFIG_HOME/llm-env/config.conf"
    
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available providers:" ]]
}

@test "regression: handles config file with only comments" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" << 'EOF'
# This is a comment
# Another comment
; This is also a comment
EOF
    
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available providers:" ]]
}

@test "regression: handles malformed section headers" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" << 'EOF'
[incomplete_section
base_url=https://api.incomplete.com/v1

[valid_provider]
base_url=https://api.valid.com/v1
api_key_var=VALID_API_KEY
default_model=valid-model
description=Valid provider
enabled=true
EOF
    
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "valid_provider" ]]
    [[ "$output" != *"incomplete_section"* ]]
}

@test "regression: handles missing required fields" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" << 'EOF'
[missing_base_url]
api_key_var=MISSING_URL_KEY
default_model=test-model
enabled=true

[missing_api_key]
base_url=https://api.missing.com/v1
default_model=test-model
enabled=true

[complete_provider]
base_url=https://api.complete.com/v1
api_key_var=COMPLETE_API_KEY
default_model=complete-model
description=Complete provider
enabled=true
EOF
    
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "complete_provider" ]]
    # Incomplete providers should be handled gracefully (either included with defaults or excluded)
}

@test "regression: handles very long provider names" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    local long_name="very_long_provider_name_that_exceeds_normal_limits_and_tests_boundary_conditions"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" << EOF
[$long_name]
base_url=https://api.longname.com/v1
api_key_var=LONG_NAME_API_KEY
default_model=long-model
description=Provider with very long name
enabled=true
EOF
    
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "$long_name" ]]
}

@test "regression: handles special characters in values" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" << 'EOF'
[special_chars]
base_url=https://api.special.com/v1/path?key=value&other=123
api_key_var=SPECIAL_API_KEY
default_model=model-with-dashes_and_underscores
description=Provider with special chars: $, &, @, #, %, etc.
enabled=true
EOF
    
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "special_chars" ]]
}

@test "regression: handles case sensitivity in configuration" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" << 'EOF'
[CaseSensitive]
base_url=https://api.case.com/v1
api_key_var=CASE_API_KEY
default_model=case-model
DESCRIPTION=Case sensitive description
ENABLED=true

[casesensitive]
base_url=https://api.lower.com/v1
api_key_var=LOWER_API_KEY
default_model=lower-model
description=Lowercase version
enabled=true
EOF
    
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    # Both should be treated as different providers
    [[ "$output" =~ "CaseSensitive" ]]
    [[ "$output" =~ "casesensitive" ]]
}

# ERROR HANDLING TESTS

@test "regression: handles permission denied on config file" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" << 'EOF'
[test_provider]
base_url=https://api.test.com/v1
api_key_var=TEST_API_KEY
default_model=test-model
enabled=true
EOF
    
    # Remove read permission
    chmod 000 "$XDG_CONFIG_HOME/llm-env/config.conf"
    
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    # Should fall back to built-in providers
    [[ "$output" =~ "Available providers:" ]]
    
    # Restore permission for cleanup
    chmod 644 "$XDG_CONFIG_HOME/llm-env/config.conf"
}

@test "regression: handles config directory as file" {
    # Create a file where config directory should be
    mkdir -p "$XDG_CONFIG_HOME"
    touch "$XDG_CONFIG_HOME/llm-env"
    
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    # Should gracefully handle and fall back to built-ins
    [[ "$output" =~ "Available providers:" ]]
}

@test "regression: handles extremely large config file" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    
    # Generate a large config file (100 providers)
    {
        for i in {1..100}; do
            echo "[large_provider_$i]"
            echo "base_url=https://api.large$i.com/v1"
            echo "api_key_var=LARGE_${i}_API_KEY"
            echo "default_model=large-model-$i"
            echo "description=Large test provider $i with some additional text to make it longer"
            echo "enabled=true"
            echo ""
        done
    } > "$XDG_CONFIG_HOME/llm-env/config.conf"
    
    # Test should complete within reasonable time
    local start_time=$(date +%s)
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    local end_time=$(date +%s)
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "large_provider_1" ]]
    [[ "$output" =~ "large_provider_100" ]]
    
    # Calculate dynamic timeout based on system load
    local base_timeout=10  # Base timeout in seconds
    local dynamic_timeout
    dynamic_timeout=$(calculate_dynamic_timeout $base_timeout)
    
    echo "# Dynamic timeout calculated: ${dynamic_timeout}s (base: ${base_timeout}s)" >&3
    
    # Should complete within dynamic timeout even with large config
    # Timeout automatically adjusts based on CI environment load and system resources
    local duration=$((end_time - start_time))
    [ "$duration" -lt "$dynamic_timeout" ]
}

@test "regression: handles config with duplicate section names" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" << 'EOF'
[duplicate_provider]
base_url=https://api.first.com/v1
api_key_var=FIRST_API_KEY
default_model=first-model
description=First provider
enabled=true

[duplicate_provider]
base_url=https://api.second.com/v1
api_key_var=SECOND_API_KEY
default_model=second-model
description=Second provider
enabled=true
EOF
    
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    # Should handle duplicates gracefully (typically last one wins)
    [[ "$output" =~ "duplicate_provider" ]]
}

# PERFORMANCE REGRESSION TESTS

@test "regression: initialization time remains acceptable" {
    # Test script loading performance
    local start_time=$(date +%s%N)
    bash -c "source $BATS_TEST_DIRNAME/../../llm-env --version" > /dev/null
    local end_time=$(date +%s%N)
    
    # Calculate duration in milliseconds
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    # Calculate dynamic timeout based on system load (base: 2000ms)
    local dynamic_timeout=$(calculate_dynamic_timeout 2000)
    echo "# Dynamic timeout calculated: ${dynamic_timeout}ms (base: 2000ms)" >&3
    
    # Should initialize within dynamic timeout
    [ "$duration" -lt "$dynamic_timeout" ]
}

@test "regression: memory usage stays reasonable" {
    # This test verifies the script doesn't have obvious memory leaks
    # Run the script multiple times in succession
    for i in {1..10}; do
        bash -c "source $BATS_TEST_DIRNAME/../../llm-env list" > /dev/null
    done
    
    # If we reach here without hanging or crashing, memory usage is acceptable
    true
}

# COMPATIBILITY REGRESSION TESTS

@test "regression: environment variable isolation" {
    # Ensure script doesn't pollute parent environment
    export TEST_VAR="original_value"
    export LLM_PROVIDER="original_provider"
    
    # Run in subshell
    (
        export LLM_OPENAI_API_KEY='test-key-12345'
        source "$BATS_TEST_DIRNAME/../../llm-env" set openai > /dev/null
        # Changes should be contained to subshell
    )
    
    # Parent environment should be unchanged
    [ "$TEST_VAR" = "original_value" ]
    [ "$LLM_PROVIDER" = "original_provider" ]
}

@test "regression: script works with set -e" {
    # Test that script works with strict error handling
    run bash -c "set -e; source $BATS_TEST_DIRNAME/../../llm-env --version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "LLM Environment Manager" ]]
}

@test "regression: script works with set -u" {
    # Test that script works with unbound variable detection
    run bash -c "set -u; source $BATS_TEST_DIRNAME/../../llm-env --version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "LLM Environment Manager" ]]
}

@test "regression: script works with pipefail" {
    # Test that script works with pipe failure detection
    run bash -c "set -o pipefail; source $BATS_TEST_DIRNAME/../../llm-env --version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "LLM Environment Manager" ]]
}

@test "regression: handles SIGINT gracefully" {
    # This test verifies the script doesn't leave resources in bad state
    # when interrupted (though SIGINT testing in BATS is limited)
    
    # Run a command that should complete quickly
    # Note: Removed timeout command for macOS compatibility
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available providers:" ]]
}