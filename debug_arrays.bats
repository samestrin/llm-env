#!/usr/bin/env bats

@test "debug array state during config loading" {
    # Create test setup
    export TEST_HOME="$BATS_TMPDIR/array-debug-$$"
    mkdir -p "$TEST_HOME/.config/llm-env" 
    export HOME="$TEST_HOME"
    export LLM_ENV_DEBUG=1
    
    cat > "$TEST_HOME/.config/llm-env/config.conf" << 'EOF'
[test_provider]
base_url=https://api.example.com/v1
api_key_var=LLM_TEST_API_KEY
default_model=test-model-v1
description=Test provider
enabled=true
EOF

    # Source the script (this runs init_config with built-ins)
    source "$BATS_TEST_DIRNAME/llm-env"
    
    echo "After initial sourcing:" >&3
    echo "PROVIDER_BASE_URLS keys: ${!PROVIDER_BASE_URLS[*]}" >&3
    echo "AVAILABLE_PROVIDERS: ${AVAILABLE_PROVIDERS[*]}" >&3
    
    # Reset CONFIG_LOCATIONS for test
    CONFIG_LOCATIONS=(
        "$HOME/.config/llm-env/config.conf"
        "/usr/local/etc/llm-env/config.conf"
    )
    
    # Now call init_config again
    echo "Before second init_config:" >&3
    echo "PROVIDER_BASE_URLS keys: ${!PROVIDER_BASE_URLS[*]}" >&3
    
    init_config
    
    echo "After second init_config:" >&3
    echo "PROVIDER_BASE_URLS keys: ${!PROVIDER_BASE_URLS[*]}" >&3
    echo "AVAILABLE_PROVIDERS: ${AVAILABLE_PROVIDERS[*]}" >&3
    echo "test_provider base_url: ${PROVIDER_BASE_URLS[test_provider]:-NOT_SET}" >&3
    
    [[ -n "${PROVIDER_BASE_URLS[test_provider]:-}" ]]
}