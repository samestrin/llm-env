#!/usr/bin/env bats

# Integration tests for provider functionality

setup() {
    # ==========================================
    # CRITICAL TIMING SEQUENCE FOR INTEGRATION TESTS
    # ==========================================
    # This setup function follows a specific order to ensure proper configuration loading:
    # 1. Set up test environment variables BEFORE sourcing the script
    # 2. Create test config file BEFORE sourcing the script  
    # 3. Source the script (which triggers init_config() automatically)
    # 4. Re-declare arrays if needed for BATS compatibility
    #
    # IMPORTANT: The order matters because init_config() runs during script sourcing
    # and needs to find the test configuration file to override built-in defaults.
    
    # Step 1: Create temporary config directory and set HOME FIRST
    export TEST_CONFIG_DIR="$BATS_TMPDIR/llm-env-test-$$"
    mkdir -p "$TEST_CONFIG_DIR/.config/llm-env"
    export HOME="$TEST_CONFIG_DIR"
    
    # Step 2: Create test configuration file BEFORE sourcing script
    # This ensures init_config() finds the test config instead of falling back to built-in defaults
    # The test config includes both enabled and disabled providers for comprehensive testing
    cat > "$TEST_CONFIG_DIR/.config/llm-env/config.conf" << 'EOF'
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

    # Step 3: Enable debug mode for troubleshooting (disable for production)
    # export LLM_ENV_DEBUG=1
    
    # Step 4: Re-declare associative arrays to ensure they work in BATS context
    # BATS has scoping issues with associative arrays, so we pre-declare them
    declare -A PROVIDER_BASE_URLS
    declare -A PROVIDER_API_KEY_VARS
    declare -A PROVIDER_DEFAULT_MODELS
    declare -A PROVIDER_DESCRIPTIONS
    declare -A PROVIDER_ENABLED
    declare -a AVAILABLE_PROVIDERS
    
    # Step 5: NOW source the main script - init_config() will find our test configuration
    # Because HOME is set correctly, CONFIG_LOCATIONS will point to our test config
    # This is the critical moment where configuration loading occurs
    source "$BATS_TEST_DIRNAME/../../llm-env"
    
    # Step 6: Debug verification (disable for production)
    # Uncomment to verify arrays are populated correctly after sourcing:
    # echo "SETUP DEBUG: AVAILABLE_PROVIDERS: ${AVAILABLE_PROVIDERS[*]}" >&2
}

teardown() {
    # Clean up test environment
    rm -rf "$TEST_CONFIG_DIR"
    unset LLM_PROVIDER OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
    unset LLM_TEST_API_KEY LLM_DISABLED_API_KEY
}

# ==========================================
# HELPER FUNCTION: ARRAY RE-INITIALIZATION
# ==========================================
# This helper function addresses BATS scoping limitations with associative arrays.
# Some tests need to re-initialize arrays after modifying config files during test execution.
#
# USAGE: Call init_test_arrays() at the start of any test that:
#   - Modifies config files after setup() completes
#   - Needs fresh array population from updated configuration
#   - Experiences array scoping issues in BATS environment
#
# TECHNICAL NOTES:
#   - Uses 'declare -gA' for global associative arrays
#   - Uses 'declare -ga' for global indexed arrays  
#   - Calls init_config() to repopulate arrays from current config state
init_test_arrays() {
    # Re-declare arrays globally in test context to work around BATS scoping issues
    declare -gA PROVIDER_BASE_URLS
    declare -gA PROVIDER_API_KEY_VARS
    declare -gA PROVIDER_DEFAULT_MODELS
    declare -gA PROVIDER_DESCRIPTIONS
    declare -gA PROVIDER_ENABLED
    declare -ga AVAILABLE_PROVIDERS
    
    # Repopulate arrays from current configuration state
    init_config
}

@test "cmd_list: shows enabled providers" {
    init_test_arrays
    
    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_provider" ]]
    [[ "$output" =~ "Test provider for unit tests" ]]
}

@test "cmd_list: does not show disabled providers by default" {
    init_test_arrays
    
    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" != *"disabled_provider"* ]]
}

@test "cmd_list: shows all providers with --all flag" {
    init_test_arrays
    
    run cmd_list --all
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_provider" ]]
    [[ "$output" =~ "disabled_provider" ]]
}

@test "cmd_set: sets provider environment variables" {
    init_test_arrays
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
    init_test_arrays
    
    run cmd_set "nonexistent_provider"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Available providers:" ]]
}

@test "cmd_set: fails for disabled provider" {
    init_test_arrays
    
    run cmd_set "disabled_provider"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Available providers:" ]]
}

@test "cmd_set: fails when API key is missing" {
    init_test_arrays
    unset LLM_TEST_API_KEY
    
    run cmd_set "test_provider"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No API key found for test_provider" ]]
}

@test "cmd_show: displays current provider information" {
    init_test_arrays
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
    init_test_arrays
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
    init_test_arrays
    
    run cmd_config backup
    [ "$status" -eq 0 ]
    
    # Check that backup file was created
    local backup_files=("$TEST_CONFIG_DIR"/.config/llm-env/backups/*.conf)
    [ -f "${backup_files[0]}" ]
}

@test "cmd_config_restore: restores from backup" {
    init_test_arrays
    
    # Create backup first
    cmd_config backup
    
    # Modify config
    echo "[new_provider]" >> "$TEST_CONFIG_DIR/.config/llm-env/config.conf"
    echo "base_url=https://new.api.com/v1" >> "$TEST_CONFIG_DIR/.config/llm-env/config.conf"
    
    # Find backup file
    local backup_files=("$TEST_CONFIG_DIR"/.config/llm-env/backups/*.conf)
    local backup_file="${backup_files[0]}"
    
    run cmd_config restore "$backup_file"
    echo "DEBUG: restore status=$status" >&3
    echo "DEBUG: restore output='$output'" >&3
    [ "$status" -eq 0 ]
    
    # Check that config was restored (new_provider should be gone)
    run grep "new_provider" "$TEST_CONFIG_DIR/.config/llm-env/config.conf"
    [ "$status" -eq 1 ]
}

@test "configuration parsing: handles malformed config gracefully" {
    # Create malformed config
    cat > "$TEST_CONFIG_DIR/.config/llm-env/config.conf" << 'EOF'
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
    init_test_arrays
    
    run cmd_list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "valid_provider" ]]
    [[ "$output" != *"incomplete_provider"* ]]
}