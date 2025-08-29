#!/bin/bash

# Debug script to test llm-env sourcing and cmd_list execution with exact BATS environment
set -e

echo "=== Debug Test Script (BATS Environment) ==="

# Set up test environment exactly like BATS
export TEST_CONFIG_DIR="$(mktemp -d)"
export HOME="$TEST_CONFIG_DIR"
export BATS_TEST_DIRNAME="$(pwd)/tests/integration"

echo "TEST_CONFIG_DIR: $TEST_CONFIG_DIR"
echo "HOME: $HOME"
echo "BATS_TEST_DIRNAME: $BATS_TEST_DIRNAME"
echo "Shell: $0"
echo "Bash version: $BASH_VERSION"

# Create the config directory structure
mkdir -p "$TEST_CONFIG_DIR/.config/llm-env"

# Create test configuration file exactly as in BATS
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

echo "=== Configuration file content ==="
cat "$TEST_CONFIG_DIR/.config/llm-env/config.conf"
echo

echo "=== Sourcing llm-env (from BATS path) ==="
source "$BATS_TEST_DIRNAME/../../llm-env"

echo "=== Available providers array ==="
echo "AVAILABLE_PROVIDERS: ${AVAILABLE_PROVIDERS[@]}"
echo "Array length: ${#AVAILABLE_PROVIDERS[@]}"
echo

echo "=== Provider arrays ==="
echo "Base URLs keys: ${!PROVIDER_BASE_URLS[@]}"
echo "Enabled keys: ${!PROVIDER_ENABLED[@]}"
echo "Descriptions keys: ${!PROVIDER_DESCRIPTIONS[@]}"
echo

echo "=== Running cmd_list ==="
cmd_list
echo "cmd_list exit code: $?"

echo "=== Cleanup ==="
rm -rf "$TEST_CONFIG_DIR"