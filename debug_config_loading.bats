#!/usr/bin/env bats

setup() {
    # Set up test environment
    export TEST_CONFIG_DIR="$(mktemp -d)"
    export HOME="$TEST_CONFIG_DIR"
    
    # Create the config directory structure
    mkdir -p "$TEST_CONFIG_DIR/.config/llm-env"
    
    # Create test configuration file
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
}

teardown() {
    rm -rf "$TEST_CONFIG_DIR"
}

@test "debug configuration loading" {
    # Source the main script
    source "./llm-env"
    
    echo "HOME: $HOME"
    echo "Config file exists: $([ -f "$HOME/.config/llm-env/config.conf" ] && echo yes || echo no)"
    echo "Config file content:"
    cat "$HOME/.config/llm-env/config.conf"
    echo "AVAILABLE_PROVIDERS array: ${AVAILABLE_PROVIDERS[@]:-empty}"
    echo "AVAILABLE_PROVIDERS length: ${#AVAILABLE_PROVIDERS[@]}"
    echo "PROVIDER_BASE_URLS keys: ${!PROVIDER_BASE_URLS[@]:-empty}"
    
    # This should fail to show the debug output
    false
}