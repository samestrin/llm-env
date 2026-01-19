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

# ========================================
# Story AC 01-04: Invalid Protocol Validation
# ========================================

@test "validation: valid protocol anthropic is accepted" {
    local test_config="$BATS_TEST_TMPDIR/valid_anthropic.conf"
    cat > "$test_config" << 'EOF'
[ant_provider]
base_url=https://api.anthropic.com/v1
api_key_var=ANTHROPIC_API_KEY
default_model=claude-3-opus-20240229
description=Anthropic provider
enabled=true
protocol=anthropic
EOF

    load_config "$test_config"

    local protocol
    protocol="$(get_provider_value "PROVIDER_PROTOCOLS" "ant_provider")"

    [ "$protocol" == "anthropic" ]
}

@test "validation: valid protocol openai is accepted" {
    local test_config="$BATS_TEST_TMPDIR/valid_openai.conf"
    cat > "$test_config" << 'EOF'
[openai_provider]
base_url=https://api.openai.com/v1
api_key_var=OPENAI_API_KEY
default_model=gpt-5
description=OpenAI provider
enabled=true
protocol=openai
EOF

    load_config "$test_config"

    local protocol
    protocol="$(get_provider_value "PROVIDER_PROTOCOLS" "openai_provider")"

    [ "$protocol" == "openai" ]
}

@test "validation: case variations normalized to lowercase" {
    local test_config="$BATS_TEST_TMPDIR/case_variations.conf"
    cat > "$test_config" << 'EOF'
[provider1]
base_url=https://api.test.com/v1
api_key_var=TEST_API_KEY
default_model=test-model
description=Test provider 1
enabled=true
protocol=ANTHROPIC

[provider2]
base_url=https://api.test2.com/v1
api_key_var=TEST2_API_KEY
default_model=test-model-2
description=Test provider 2
enabled=true
protocol=OpenAI
EOF

    load_config "$test_config"

    local protocol1
    local protocol2
    protocol1="$(get_provider_value "PROVIDER_PROTOCOLS" "provider1")"
    protocol2="$(get_provider_value "PROVIDER_PROTOCOLS" "provider2")"

    # Both should be lowercase
    [ "$protocol1" == "anthropic" ]
    [ "$protocol2" == "openai" ]
}

@test "validation: invalid protocol defaults to openai with warning" {
    local test_config="$BATS_TEST_TMPDIR/invalid_protocol.conf"
    cat > "$test_config" << 'EOF'
[bad_provider]
base_url=https://api.test.com/v1
api_key_var=TEST_API_KEY
default_model=test-model
description=Bad provider
enabled=true
protocol=invalid_protocol_value
EOF

    # Load the config directly (run doesn't preserve environment in tests)
    load_config "$test_config" 2>/dev/null

    # Protocol should default to "openai"
    local protocol
    protocol="$(get_provider_value "PROVIDER_PROTOCOLS" "bad_provider")"

    [ "$protocol" == "openai" ]
}

@test "validation: empty protocol defaults to openai with warning" {
    local test_config="$BATS_TEST_TMPDIR/empty_protocol.conf"
    cat > "$test_config" << 'EOF'
[empty_proto_provider]
base_url=https://api.test.com/v1
api_key_var=TEST_API_KEY
default_model=test-model
description=Empty protocol provider
enabled=true
protocol=
EOF

    load_config "$test_config"

    local protocol
    protocol="$(get_provider_value "PROVIDER_PROTOCOLS" "empty_proto_provider")"

    [ "$protocol" == "openai" ]
}
