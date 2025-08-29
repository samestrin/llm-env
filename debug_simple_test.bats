#!/usr/bin/env bats

@test "debug configuration loading" {
    # Create test config
    export TEST_HOME="$BATS_TMPDIR/debug-test-$$"
    mkdir -p "$TEST_HOME/.config/llm-env"
    export HOME="$TEST_HOME"
    
    cat > "$TEST_HOME/.config/llm-env/config.conf" << 'EOF'
[test_provider]
base_url=https://api.example.com/v1
api_key_var=LLM_TEST_API_KEY
default_model=test-model-v1
description=Test provider
enabled=true
EOF

    # Enable debug mode
    export LLM_ENV_DEBUG=1
    
    # Source script
    source "$BATS_TEST_DIRNAME/llm-env"
    
    # Check what's loaded
    echo "CONFIG_LOCATIONS: ${CONFIG_LOCATIONS[*]}"
    echo "HOME: $HOME"
    echo "Config file exists: $(test -f "$HOME/.config/llm-env/config.conf" && echo yes || echo no)"
    echo "AVAILABLE_PROVIDERS: ${AVAILABLE_PROVIDERS[*]}"
    echo "PROVIDER_BASE_URLS keys: ${!PROVIDER_BASE_URLS[*]}"
    
    # Cleanup
    rm -rf "$TEST_HOME"
}