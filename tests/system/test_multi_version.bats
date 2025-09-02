#!/usr/bin/env bats

# System tests for bash version matrix compatibility

setup() {
    # Source helper functions for dynamic timeout calculation
    source "$BATS_TEST_DIRNAME/../lib/bats_helpers.sh"
    
    # Create temporary directory for testing
    export TEST_DIR="$BATS_TMPDIR/llm-env-multiversion-test-$$"
    mkdir -p "$TEST_DIR"
    
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

# Test matrix for different bash versions
@test "version matrix: bash 5.2 full functionality" {
    export BASH_VERSION="5.2.37(1)-release"
    
    # Test script loading
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env --version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "LLM Environment Manager" ]]
    
    # Test provider operations
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available providers:" ]]
    [[ "$output" =~ "openai" ]]
}

@test "version matrix: bash 4.0 compatibility" {
    export BASH_VERSION="4.0.44(1)-release"
    
    # Test script loading
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env --version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "LLM Environment Manager" ]]
    
    # Test provider operations
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available providers:" ]]
    [[ "$output" =~ "openai" ]]
    
    # Test provider setting
    run bash -c "
        export LLM_OPENAI_API_KEY='test-key-12345'
        source $BATS_TEST_DIRNAME/../../llm-env set openai && echo \$LLM_PROVIDER
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "openai" ]]
}

@test "version matrix: bash 3.2 fallback mode" {
    export BASH_VERSION="3.2.57(1)-release"
    
    # Test script loading
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env --version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "LLM Environment Manager" ]]
    
    # Test provider operations with compatibility layer
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available providers:" ]]
    [[ "$output" =~ "openai" ]]
    
    # Test provider setting with compatibility layer
    run bash -c "
        export LLM_OPENAI_API_KEY='test-key-12345'
        source $BATS_TEST_DIRNAME/../../llm-env set openai && echo \$LLM_PROVIDER
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "openai" ]]
}

@test "version matrix: configuration loading across versions" {
    # Create test configuration
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" << 'EOF'
[version_test_provider]
base_url=https://api.versiontest.com/v1
api_key_var=VERSION_TEST_API_KEY
default_model=version-test-model
description=Version test provider
enabled=true
EOF

    # Test with bash 5.x
    export BASH_VERSION="5.2.37(1)-release"
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version_test_provider" ]]
    
    # Test with bash 4.0
    export BASH_VERSION="4.0.44(1)-release"
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version_test_provider" ]]
    
    # Test with bash 3.2 (compatibility mode)
    export BASH_VERSION="3.2.57(1)-release"
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version_test_provider" ]]
}

@test "version matrix: error handling consistency" {
    # Test invalid command across versions
    for version in "5.2.37(1)-release" "4.0.44(1)-release" "3.2.57(1)-release"; do
        export BASH_VERSION="$version"
        
        run bash -c "source $BATS_TEST_DIRNAME/../../llm-env invalid_command"
        [ "$status" -eq 1 ]
        [[ "$output" =~ "Unknown command" ]]
    done
}

@test "version matrix: help output consistency" {
    # Test help command across versions
    for version in "5.2.37(1)-release" "4.0.44(1)-release" "3.2.57(1)-release"; do
        export BASH_VERSION="$version"
        
        run bash -c "source $BATS_TEST_DIRNAME/../../llm-env --help"
        [ "$status" -eq 0 ]
        [[ "$output" =~ "Usage:" ]]
        [[ "$output" =~ "Commands:" ]]
        [[ "$output" =~ "Examples:" ]]
    done
}

@test "version matrix: environment variable handling" {
    # Test environment variable isolation across versions
    export LLM_PROVIDER="initial_value"
    
    for version in "5.2.37(1)-release" "4.0.44(1)-release" "3.2.57(1)-release"; do
        export BASH_VERSION="$version"
        
        # Test in subshell to verify isolation
        run bash -c "
            export LLM_PROVIDER='initial_value'
            (source $BATS_TEST_DIRNAME/../../llm-env set openai && echo \$LLM_PROVIDER)
            echo \$LLM_PROVIDER
        "
        [ "$status" -eq 0 ]
        # First line should be openai (from subshell)
        # Second line should be initial_value (from parent)
        [[ "${lines[0]}" =~ "openai" ]]
        [[ "${lines[-1]}" =~ "initial_value" ]]
    done
}

@test "performance matrix: initialization time acceptable across versions" {
    for version in "5.2.37(1)-release" "4.0.44(1)-release" "3.2.57(1)-release"; do
        export BASH_VERSION="$version"
        
        # Measure initialization time
        local start_time=$(date +%s%N)
        bash -c "source $BATS_TEST_DIRNAME/../../llm-env list" > /dev/null
        local end_time=$(date +%s%N)
        
        # Calculate duration in milliseconds
        local duration=$(( (end_time - start_time) / 1000000 ))
        
        # Calculate dynamic timeout based on system load (base: 2500ms)
        local dynamic_timeout=$(calculate_dynamic_timeout 2500)
        echo "# Dynamic timeout calculated: ${dynamic_timeout}ms (base: 2500ms)"
        
        # Should complete within dynamic timeout
        [ "$duration" -lt "$dynamic_timeout" ]
    done
}

@test "version matrix: large configuration performance" {
    # Create large configuration for performance testing
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    {
        for i in {1..20}; do
            echo "[perf_test_provider_$i]"
            echo "base_url=https://api.perftest$i.com/v1"
            echo "api_key_var=PERF_TEST_${i}_API_KEY"
            echo "default_model=perf-test-model-$i"
            echo "description=Performance test provider $i"
            echo "enabled=true"
            echo ""
        done
    } > "$XDG_CONFIG_HOME/llm-env/config.conf"
    
    for version in "5.2.37(1)-release" "4.0.44(1)-release" "3.2.57(1)-release"; do
        export BASH_VERSION="$version"
        
        # Test that list operation completes successfully even with large config
        run bash -c "source $BATS_TEST_DIRNAME/../../llm-env list"
        [ "$status" -eq 0 ]
        [[ "$output" =~ "perf_test_provider_1" ]]
        [[ "$output" =~ "perf_test_provider_20" ]]
        
        # Measure performance
        local start_time=$(date +%s%N)
        bash -c "source $BATS_TEST_DIRNAME/../../llm-env list" > /dev/null
        local end_time=$(date +%s%N)
        
        local duration=$(( (end_time - start_time) / 1000000 ))
        
        # Calculate dynamic timeout based on system load (base: 2500ms)
        local dynamic_timeout=$(calculate_dynamic_timeout 2500)
        echo "# Dynamic timeout calculated: ${dynamic_timeout}ms (base: 2500ms)"
        
        # Even with 20 providers, should complete within dynamic timeout
        [ "$duration" -lt "$dynamic_timeout" ]
    done
}

@test "version matrix: edge case version strings" {
    # Test various edge case version formats
    for version in "4.3" "4" "4.0-rc1" "4.0.0" "unknown"; do
        export BASH_VERSION="$version"
        
        # Script should still load and work
        run bash -c "source $BATS_TEST_DIRNAME/../../llm-env --version"
        [ "$status" -eq 0 ]
        [[ "$output" =~ "LLM Environment Manager" ]]
    done
}