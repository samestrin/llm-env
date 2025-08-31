#!/usr/bin/env bats

# Integration tests for provider functionality

# Load BATS helper functions
load ../lib/bats_helpers

setup() {
    # Use helper to set up test environment
    setup_test_env
    
    # Create test configuration file
    local test_config='[test_provider]
base_url=https://api.example.com/v1
api_key_var=LLM_TEST_API_KEY
default_model=test-model-v1
description=Test provider for integration tests
enabled=true

[disabled_provider]
base_url=https://api.disabled.com/v1
api_key_var=LLM_DISABLED_API_KEY
default_model=disabled-model
description=Disabled provider for testing
enabled=false'
    
    create_test_config "$test_config"
    
    # Source the main script to load configuration
    source "$BATS_TEST_DIRNAME/../../llm-env"
    
    # Configuration is automatically loaded when sourcing llm-env
}

teardown() {
    # Use helper to clean up test environment
    teardown_test_env
    unset LLM_TEST_API_KEY LLM_DISABLED_API_KEY
}

# Note: Array re-initialization is now handled by bats_helpers.sh
# Use init_test_environment() or clear_provider_arrays() as needed

@test "cmd_list: shows enabled providers" {
    # Array initialization handled by helpers
    
    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_provider" ]]
    [[ "$output" =~ "Test provider for integration tests" ]]
}

@test "cmd_list: does not show disabled providers by default" {
    # Array initialization handled by helpers
    
    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" != *"disabled_provider"* ]]
}

@test "cmd_list: shows all providers with --all flag" {
    # Array initialization handled by helpers
    
    run cmd_list --all
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_provider" ]]
    [[ "$output" =~ "disabled_provider" ]]
}

@test "cmd_set: sets provider environment variables" {
    # Array initialization handled by helpers
    export LLM_TEST_API_KEY="test-key-123"
    
    # Call cmd_set directly (not with run) so env vars persist
    cmd_set "test_provider"
    
    # Check that environment variables are set correctly
    [ "$LLM_PROVIDER" = "test_provider" ]
    [ "$OPENAI_API_KEY" = "test-key-123" ]
    [ "$OPENAI_BASE_URL" = "https://api.example.com/v1" ]
    [ "$OPENAI_MODEL" = "test-model-v1" ]
}

@test "cmd_set: fails for non-existent provider" {
    # Array initialization handled by helpers
    
    run cmd_set "nonexistent_provider"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Available providers:" ]]
}

@test "cmd_set: fails for disabled provider" {
    # Array initialization handled by helpers
    
    run cmd_set "disabled_provider"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Available providers:" ]]
}

@test "cmd_set: fails when API key is missing" {
    # Array initialization handled by helpers
    unset LLM_TEST_API_KEY
    
    run cmd_set "test_provider"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No API key found for test_provider" ]]
}

@test "cmd_show: displays current provider information" {
    # Array initialization handled by helpers
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
    [[ "$output" =~ "LLM_PROVIDER     = ∅" ]]
}

@test "cmd_unset: clears provider environment variables" {
    # Array initialization handled by helpers
    export LLM_TEST_API_KEY="test-key-123"
    cmd_set "test_provider"
    
    # Call cmd_unset directly (not with run) so env var changes persist
    cmd_unset
    
    # Check that environment variables are cleared
    [ -z "$LLM_PROVIDER" ]
    [ -z "$OPENAI_API_KEY" ]
    [ -z "$OPENAI_BASE_URL" ]
    [ -z "$OPENAI_MODEL" ]
}

@test "cmd_config_backup: creates backup file" {
    # Array initialization handled by helpers
    
    run cmd_config backup
    [ "$status" -eq 0 ]
    
    # Check that backup file was created
    local backup_files=("$BATS_TEST_TMPDIR"/.config/llm-env/backups/*.conf)
    [ -f "${backup_files[0]}" ]
}

@test "cmd_config_restore: restores from backup" {
    # Array initialization handled by helpers
    
    # Create backup first
    cmd_config backup
    
    # Modify config
    echo "[new_provider]" >> "$BATS_TEST_TMPDIR/.config/llm-env/config.conf"
    echo "base_url=https://new.api.com/v1" >> "$BATS_TEST_TMPDIR/.config/llm-env/config.conf"
    
    # Find backup file
    local backup_files=("$BATS_TEST_TMPDIR"/.config/llm-env/backups/*.conf)
    local backup_file="${backup_files[0]}"
    
    run cmd_config restore "$backup_file"
    [ "$status" -eq 0 ]
    
    # Check that config was restored (new_provider should be gone)
    run grep "new_provider" "$BATS_TEST_TMPDIR/.config/llm-env/config.conf"
    [ "$status" -eq 1 ]
}

@test "configuration parsing: handles malformed config gracefully" {
    # Create malformed config
    cat > "$BATS_TEST_TMPDIR/.config/llm-env/config.conf" << 'EOF'
[valid_provider]
base_url=https://api.valid.com/v1
api_key_var=LLM_VALID_API_KEY
default_model=valid-model
description=Valid provider
enabled=true

[incomplete_provider]
base_url=https://api.incomplete.com/v1
# Missing required fields

malformed line without section
EOF

    # Re-initialize after changing config file
    init_config
    
    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "valid_provider" ]]
    [[ "$output" != *"incomplete_provider"* ]]
}