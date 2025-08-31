#!/usr/bin/env bats

# Unit tests for bash version compatibility across different shell versions

setup() {
    # Source the main script
    source "$BATS_TEST_DIRNAME/../../llm-env"
    
    # Save original BASH_VERSION for restoration
    export ORIG_BASH_VERSION="$BASH_VERSION"
}

teardown() {
    # Restore original environment
    export BASH_VERSION="$ORIG_BASH_VERSION"
    
    # Clear any test provider data
    unset LLM_PROVIDER OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
}

@test "bash version detection: identifies bash 5.x correctly" {
    BASH_VERSION="5.2.37(1)-release"
    
    # Re-run version detection
    parse_bash_version
    
    [ "$BASH_MAJOR_VERSION" = "5" ]
    [ "$BASH_MINOR_VERSION" = "2" ]
    [ "$BASH_ASSOC_ARRAY_SUPPORT" = "true" ]
}

@test "bash version detection: identifies bash 4.0 correctly" {
    BASH_VERSION="4.0.44(1)-release"
    
    parse_bash_version
    
    [ "$BASH_MAJOR_VERSION" = "4" ]
    [ "$BASH_MINOR_VERSION" = "0" ]
    [ "$BASH_ASSOC_ARRAY_SUPPORT" = "true" ]
}

@test "bash version detection: identifies bash 3.2 correctly" {
    BASH_VERSION="3.2.57(1)-release"
    
    parse_bash_version
    
    [ "$BASH_MAJOR_VERSION" = "3" ]
    [ "$BASH_MINOR_VERSION" = "2" ]
    [ "$BASH_ASSOC_ARRAY_SUPPORT" = "false" ]
}

@test "bash version detection: handles missing BASH_VERSION gracefully" {
    unset BASH_VERSION
    
    parse_bash_version
    
    # Should default to 4.0 when missing
    [ "$BASH_MAJOR_VERSION" = "4" ]
    [ "$BASH_MINOR_VERSION" = "0" ]
    [ "$BASH_ASSOC_ARRAY_SUPPORT" = "true" ]
}

@test "bash version detection: handles malformed version string" {
    BASH_VERSION="invalid-version-string"
    
    parse_bash_version
    
    # Should fallback to conservative defaults
    [ "$BASH_MAJOR_VERSION" = "3" ]
    [ "$BASH_MINOR_VERSION" = "2" ]
    [ "$BASH_ASSOC_ARRAY_SUPPORT" = "false" ]
}

@test "associative array compatibility: works in bash 4.0+ mode" {
    # Test through the main script interface
    run bash -c "
        export BASH_ASSOC_ARRAY_SUPPORT='true'
        source $BATS_TEST_DIRNAME/../../llm-env
        get_provider_value 'PROVIDER_BASE_URLS' 'openai'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "api.openai.com" ]]
}

@test "associative array compatibility: works in bash 3.2 mode" {
    # Test through the main script interface
    run bash -c "
        export BASH_ASSOC_ARRAY_SUPPORT='false'
        source $BATS_TEST_DIRNAME/../../llm-env
        get_provider_value 'PROVIDER_BASE_URLS' 'openai'
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "api.openai.com" ]]
}

@test "provider operations: list providers works in both modes" {
    # Test with native arrays (bash 4.0+)
    run bash -c "
        export BASH_ASSOC_ARRAY_SUPPORT='true'
        source $BATS_TEST_DIRNAME/../../llm-env list
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available providers:" ]]
    [[ "$output" =~ "openai" ]]
    
    # Test with compatibility arrays (bash 3.2)
    run bash -c "
        export BASH_ASSOC_ARRAY_SUPPORT='false'
        source $BATS_TEST_DIRNAME/../../llm-env list
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available providers:" ]]
    [[ "$output" =~ "openai" ]]
}

@test "provider operations: set provider works in both modes" {
    # Test with native arrays (bash 4.0+)
    run bash -c "
        export LLM_OPENAI_API_KEY='test-key-12345'
        export BASH_ASSOC_ARRAY_SUPPORT='true'
        source $BATS_TEST_DIRNAME/../../llm-env set openai
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "openai" ]]
    
    # Test with compatibility arrays (bash 3.2)
    run bash -c "
        export LLM_OPENAI_API_KEY='test-key-12345'
        export BASH_ASSOC_ARRAY_SUPPORT='false'
        source $BATS_TEST_DIRNAME/../../llm-env set openai
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "openai" ]]
}

@test "performance: compatibility mode performance acceptable" {
    # Test performance through script interface
    local start_time=$(date +%s%N)
    bash -c "
        unset LLM_ENV_DEBUG
        export BASH_ASSOC_ARRAY_SUPPORT='false'
        source $BATS_TEST_DIRNAME/../../llm-env list
    " > /dev/null
    local end_time=$(date +%s%N)
    
    # Calculate duration in milliseconds
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    # Debug output for CI troubleshooting
    echo "# Performance test duration: ${duration}ms" >&3
    
    # Should complete within reasonable time (< 2000ms for compatibility mode)
    # Increased threshold to account for CI environment variability
    [ "$duration" -lt 2000 ]
}

@test "array bounds checking: handles large provider sets" {
    # Create a temporary config with many providers
    local test_config_dir="$BATS_TMPDIR/llm-env-version-test"
    mkdir -p "$test_config_dir/.config/llm-env"
    
    # Generate config with 15 providers (smaller set for reliable testing)
    {
        for i in {1..15}; do
            echo "[test_provider_$i]"
            echo "base_url=https://api.test$i.com/v1"
            echo "api_key_var=TEST_${i}_API_KEY"
            echo "default_model=test-model-$i"
            echo "description=Test provider $i"
            echo "enabled=true"
            echo ""
        done
    } > "$test_config_dir/.config/llm-env/config.conf"
    
    # Test loading with compatibility mode
    run bash -c "
        export BASH_ASSOC_ARRAY_SUPPORT='false'
        export XDG_CONFIG_HOME='$test_config_dir/.config'
        source $BATS_TEST_DIRNAME/../../llm-env list
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_provider_1" ]]
    [[ "$output" =~ "test_provider_15" ]]
    
    # Clean up
    rm -rf "$test_config_dir"
}

@test "edge cases: empty configuration handled properly" {
    local empty_config_dir="$BATS_TMPDIR/llm-env-empty-test"
    mkdir -p "$empty_config_dir/.config/llm-env"
    touch "$empty_config_dir/.config/llm-env/config.conf"
    
    # Test with empty config
    run bash -c "
        export BASH_ASSOC_ARRAY_SUPPORT='false'
        export XDG_CONFIG_HOME='$empty_config_dir/.config'
        source $BATS_TEST_DIRNAME/../../llm-env list
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available providers:" ]]
    
    # Clean up
    rm -rf "$empty_config_dir"
}