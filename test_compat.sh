#!/usr/bin/env bash

# Simple test script to verify bash compatibility
echo "Testing bash compatibility..."

# Force compatibility mode for testing
BASH_ASSOC_ARRAY_SUPPORT=false

# Source the main script  
source llm-env

echo "Configuration loaded successfully!"
echo "Available providers: ${AVAILABLE_PROVIDERS[*]}"

# Test a simple provider access
if has_provider_key "PROVIDER_BASE_URLS" "cerebras"; then
    echo "Cerebras base URL: $(get_provider_value "PROVIDER_BASE_URLS" "cerebras")"
else
    echo "Cerebras not found!"
fi