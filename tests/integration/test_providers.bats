#!/usr/bin/env bats

# Integration tests for provider functionality

setup() {
    # Source the main script
    source "$BATS_TEST_DIRNAME/../../llm-env"
    
    # Create temporary config directory
    export TEST_CONFIG_DIR="$BATS_TMPDIR/llm-env-test-$$"
    mkdir -p "$TEST_CONFIG_DIR"
    
    # Override config paths for testing
    export XDG_CONFIG_HOME="$TEST_CONFIG_DIR"
    export HOME="$TEST_CONFIG_DIR"
    
    # Create test configuration file
    cat > "$TEST_CONFIG_DIR/config.conf" << 'EOF'
[test_provider]
base_url=https://api.example.com/v1
api_key_var=LLM_TEST_API_KEY
default_model=test-model-v1
description=Test provider for unit tests
enabled=true

[disabled_provider]
base_url=https://api.disabled.com/v1
api_key_var=LLM_DISABLED_API_KEY
default_model=disabled-model
description=Disabled test provider
enabled=false
EOF
}

teardown() {
    # Clean up test environment
    rm -rf "$TEST_CONFIG_DIR"
    unset LLM_PROVIDER OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
    unset LLM_TEST_API_KEY LLM_DISABLED_API_KEY
}

@test "cmd_list: shows enabled providers" {
    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_provider" ]]
    [[ "$output" =~ "Test provider for unit tests" ]]
}

@test "cmd_list: does not show disabled providers by default" {
    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" != *"disabled_provider"* ]]
}

@test "cmd_list: shows all providers with --all flag" {
    run cmd_list --all
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_provider" ]]
    [[ "$output" =~ "disabled_provider" ]]
}

@test "cmd_set: sets provider environment variables" {
    export LLM_TEST_API_KEY="test-key-123"
    
    run cmd_set "test_provider"
    [ "$status" -eq 0 ]
    
    # Check that environment variables are set correctly
    [ "$LLM_PROVIDER" = "test_provider" ]
    [ "$OPENAI_API_KEY" = "test-key-123" ]
    [ "$OPENAI_BASE_URL" = "https://api.example.com/v1" ]
    [ "$OPENAI_MODEL" = "test-model-v1" ]
}

@test "cmd_set: fails for non-existent provider" {
    run cmd_set "nonexistent_provider"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Provider 'nonexistent_provider' not found" ]]
}

@test "cmd_set: fails for disabled provider" {
    run cmd_set "disabled_provider"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Provider 'disabled_provider' is disabled" ]]
}

@test "cmd_set: fails when API key is missing" {
    unset LLM_TEST_API_KEY
    
    run cmd_set "test_provider"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "API key not found" ]]
}

@test "cmd_show: displays current provider information" {
    export LLM_TEST_API_KEY="test-key-123"
    cmd_set "test_provider"
    
    run cmd_show
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_provider" ]]
    [[ "$output" =~ "https://api.example.com/v1" ]]
    [[ "$output" =~ "test-model-v1" ]]
}

@test "cmd_show: indicates when no provider is set" {
    run cmd_show
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No provider currently set" ]]
}

@test "cmd_unset: clears provider environment variables" {
    export LLM_TEST_API_KEY="test-key-123"
    cmd_set "test_provider"
    
    run cmd_unset
    [ "$status" -eq 0 ]
    
    # Check that environment variables are cleared
    [ -z "$LLM_PROVIDER" ]
    [ -z "$OPENAI_API_KEY" ]
    [ -z "$OPENAI_BASE_URL" ]
    [ -z "$OPENAI_MODEL" ]
}

@test "cmd_config_backup: creates backup file" {
    run cmd_config_backup
    [ "$status" -eq 0 ]
    
    # Check that backup file was created
    local backup_files=("$TEST_CONFIG_DIR"/*.backup.*)
    [ -f "${backup_files[0]}" ]
}

@test "cmd_config_restore: restores from backup" {
    # Create backup first
    cmd_config_backup
    
    # Modify config
    echo "[new_provider]" >> "$TEST_CONFIG_DIR/config.conf"
    echo "base_url=https://new.api.com/v1" >> "$TEST_CONFIG_DIR/config.conf"
    
    # Find backup file
    local backup_files=("$TEST_CONFIG_DIR"/*.backup.*)
    local backup_file="${backup_files[0]}"
    
    run cmd_config_restore "$backup_file"
    [ "$status" -eq 0 ]
    
    # Check that config was restored (new_provider should be gone)
    run grep "new_provider" "$TEST_CONFIG_DIR/config.conf"
    [ "$status" -eq 1 ]
}

@test "configuration parsing: handles malformed config gracefully" {
    # Create malformed config
    cat > "$TEST_CONFIG_DIR/config.conf" << 'EOF'
[valid_provider]
base_url=https://api.valid.com/v1
api_key_var=LLM_VALID_API_KEY

[incomplete_provider]
base_url=https://api.incomplete.com/v1
# Missing required fields

malformed line without section
EOF

    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "valid_provider" ]]
    [[ "$output" != *"incomplete_provider"* ]]
}