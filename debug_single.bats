#!/usr/bin/env bats

setup() {
    # Create temporary config directory
    export TEST_CONFIG_DIR="$BATS_TMPDIR/llm-env-test-$$"
    mkdir -p "$TEST_CONFIG_DIR/.config/llm-env"
    
    # Override config paths for testing
    export HOME="$TEST_CONFIG_DIR"
    export LLM_ENV_DEBUG=1
    
    # Create test configuration file BEFORE sourcing script
    cat > "$TEST_CONFIG_DIR/.config/llm-env/config.conf" << 'EOF'
[test_provider]
base_url=https://api.example.com/v1
api_key_var=LLM_TEST_API_KEY
default_model=test-model-v1
description=Test provider for unit tests
enabled=true
EOF

    # Source script
    source "$BATS_TEST_DIRNAME/llm-env"
    
    # Re-initialize CONFIG_LOCATIONS with the test HOME path
    CONFIG_LOCATIONS=(
        "$HOME/.config/llm-env/config.conf"
        "/usr/local/etc/llm-env/config.conf"
        "$(dirname "${BASH_SOURCE[0]}")/config/llm-env.conf"
    )
    
    # Force re-initialization
    init_config
}

teardown() {
    rm -rf "$TEST_CONFIG_DIR"
    unset LLM_PROVIDER OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
    unset LLM_TEST_API_KEY LLM_ENV_DEBUG
}

@test "debug: check provider loading" {
    echo "HOME: $HOME" >&3
    echo "Config file exists: $(test -f "$HOME/.config/llm-env/config.conf" && echo yes || echo no)" >&3
    echo "Config contents:" >&3
    cat "$HOME/.config/llm-env/config.conf" >&3
    echo "CONFIG_LOCATIONS: ${CONFIG_LOCATIONS[*]}" >&3
    echo "AVAILABLE_PROVIDERS: ${AVAILABLE_PROVIDERS[*]}" >&3
    echo "PROVIDER_BASE_URLS keys: ${!PROVIDER_BASE_URLS[*]}" >&3
    
    run cmd_list
    echo "cmd_list status: $status" >&3
    echo "cmd_list output: $output" >&3
    
    [ "$status" -eq 0 ]
}