#!/usr/bin/env bats

# Unit tests for protocol configuration parsing

setup() {
    # Source the main script to access functions
    source "$BATS_TEST_DIRNAME/../../llm-env"
}

# ========================================
# Story AC 01-02: Default Protocol Values
# ========================================

@test "default protocol: config without protocol field defaults to openai" {
    # Create a minimal config without protocol field
    local test_config="$BATS_TEST_TMPDIR/no_protocol.conf"
    cat > "$test_config" << 'EOF'
[test_provider]
base_url=https://api.test.com/v1
api_key_var=TEST_API_KEY
default_model=test-model
description=Test provider
enabled=true
EOF

    # Load the config
    load_config "$test_config"

    # PROVIDER_PROTOCOLS should default to "openai" when not specified
    local protocol
    protocol="$(get_provider_value "PROVIDER_PROTOCOLS" "test_provider")"

    [ "$protocol" == "openai" ]
}

@test "default protocol: empty provider section defaults to openai" {
    # Config with empty provider section
    local test_config="$BATS_TEST_TMPDIR/empty_provider.conf"
    cat > "$test_config" << 'EOF'
[empty_section]
base_url=https://api.test.com/v1
api_key_var=TEST_API_KEY
default_model=test-model
description=Test provider
enabled=true
EOF

    load_config "$test_config"

    local protocol
    protocol="$(get_provider_value "PROVIDER_PROTOCOLS" "empty_section")"

    [ "$protocol" == "openai" ]
}

@test "default protocol: backward compatibility with existing configs" {
    # Simulate existing config format (no protocol field)
    local test_config="$BATS_TEST_TMPDIR/existing_config.conf"
    cat > "$test_config" << 'EOF'
[openai]
base_url=https://api.openai.com/v1
api_key_var=LLM_OPENAI_API_KEY
default_model=gpt-5
description=Industry standard
enabled=true

[groq]
base_url=https://api.groq.com/openai/v1
api_key_var=LLM_GROQ_API_KEY
default_model=openai/gpt-oss-120b
description=Lightning-fast inference
enabled=true
EOF

    load_config "$test_config"

    # Both should default to "openai" when protocol not specified
    local openai_protocol
    openai_protocol="$(get_provider_value "PROVIDER_PROTOCOLS" "openai")"
    local groq_protocol
    groq_protocol="$(get_provider_value "PROVIDER_PROTOCOLS" "groq")"

    [ "$openai_protocol" == "openai" ]
    [ "$groq_protocol" == "openai" ]
}
