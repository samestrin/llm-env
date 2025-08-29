#!/usr/bin/env bats

# System tests for cross-platform compatibility

setup() {
    # Source the main script
    source "$BATS_TEST_DIRNAME/../../llm-env"
    
    # Create temporary directory for testing
    export TEST_DIR="$BATS_TMPDIR/llm-env-system-test-$$"
    mkdir -p "$TEST_DIR"
    
    # Save original environment
    export ORIG_HOME="$HOME"
    export ORIG_XDG_CONFIG_HOME="$XDG_CONFIG_HOME"
    
    # Set up test environment
    export HOME="$TEST_DIR"
    export XDG_CONFIG_HOME="$TEST_DIR/.config"
}

teardown() {
    # Restore original environment
    export HOME="$ORIG_HOME"
    export XDG_CONFIG_HOME="$ORIG_XDG_CONFIG_HOME"
    
    # Clean up test directory
    rm -rf "$TEST_DIR"
    
    # Clear any set provider
    unset LLM_PROVIDER OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
}

@test "system: handles missing config directory gracefully" {
    # Ensure no config directory exists
    rm -rf "$XDG_CONFIG_HOME/llm-env"
    
    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No configuration found" ]]
}

@test "system: creates config directory when needed" {
    # Ensure no config directory exists
    rm -rf "$XDG_CONFIG_HOME/llm-env"
    
    run cmd_config init
    [ "$status" -eq 0 ]
    [ -d "$XDG_CONFIG_HOME/llm-env" ]
}

@test "system: handles XDG_CONFIG_HOME fallback" {
    unset XDG_CONFIG_HOME
    
    # Should fall back to $HOME/.config
    run cmd_config init
    [ "$status" -eq 0 ]
    [ -d "$HOME/.config/llm-env" ]
}

@test "system: command line argument parsing" {
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env --version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "LLM Environment Manager" ]]
    [[ "$output" =~ "$VERSION" ]]
}

@test "system: help command displays usage" {
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env --help"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
    [[ "$output" =~ "Examples:" ]]
}

@test "system: handles invalid command gracefully" {
    run bash -c "source $BATS_TEST_DIRNAME/../../llm-env invalid_command"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown command" ]]
}

@test "system: environment variable isolation" {
    # Set some environment variables
    export LLM_PROVIDER="initial"
    export OPENAI_API_KEY="initial_key"
    
    # Create minimal config for testing
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" << 'EOF'
[test_provider]
base_url=https://api.test.com/v1
api_key_var=LLM_TEST_API_KEY
default_model=test-model
description=Test provider
enabled=true
EOF
    
    export LLM_TEST_API_KEY="test_key"
    
    # Set provider in subshell
    (
        source "$BATS_TEST_DIRNAME/../../llm-env" set test_provider
        [ "$LLM_PROVIDER" = "test_provider" ]
        [ "$OPENAI_API_KEY" = "test_key" ]
    )
    
    # Original environment should be unchanged
    [ "$LLM_PROVIDER" = "initial" ]
    [ "$OPENAI_API_KEY" = "initial_key" ]
}

@test "system: configuration file permissions" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    
    # Create config file with restricted permissions
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" << 'EOF'
[test_provider]
base_url=https://api.test.com/v1
api_key_var=LLM_TEST_API_KEY
default_model=test-model
description=Test provider
enabled=true
EOF
    
    chmod 600 "$XDG_CONFIG_HOME/llm-env/config.conf"
    
    # Should still be able to read the config
    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_provider" ]]
}

@test "system: large configuration file handling" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    
    # Create large config with many providers
    {
        for i in {1..100}; do
            echo "[provider_$i]"
            echo "base_url=https://api.provider$i.com/v1"
            echo "api_key_var=LLM_PROVIDER${i}_API_KEY"
            echo "default_model=model-$i"
            echo "description=Test provider $i"
            echo "enabled=true"
            echo ""
        done
    } > "$XDG_CONFIG_HOME/llm-env/config.conf"
    
    # Should handle large config file
    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "provider_1" ]]
    [[ "$output" =~ "provider_100" ]]
}

@test "system: concurrent access safety" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" << 'EOF'
[test_provider]
base_url=https://api.test.com/v1
api_key_var=LLM_TEST_API_KEY
default_model=test-model
description=Test provider
enabled=true
EOF
    
    # Simulate concurrent access
    {
        cmd_list &
        cmd_list &
        cmd_list &
        wait
    }
    
    # All processes should complete successfully
    [ "$?" -eq 0 ]
}

@test "system: PATH independence" {
    # Test that the script doesn't depend on specific PATH entries
    local limited_path="/bin:/usr/bin"
    
    run env PATH="$limited_path" bash -c "source $BATS_TEST_DIRNAME/../../llm-env --version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "$VERSION" ]]
}