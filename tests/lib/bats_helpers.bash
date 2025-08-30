#!/usr/bin/env bash

# BATS helper functions for llm-env testing
# Addresses associative array scoping issues in BATS environment

# Global array management helpers for BATS
declare_global_arrays() {
    local array_support="${1:-$BASH_ASSOC_ARRAY_SUPPORT}"
    local declare_global_support="${BASH_DECLARE_GLOBAL_SUPPORT:-false}"
    
    if [[ "$array_support" == "true" ]]; then
        # Declare native associative arrays
        if [[ "$declare_global_support" == "true" ]]; then
            # Bash 4.2+ with declare -g support
            declare -gA PROVIDER_BASE_URLS
            declare -gA PROVIDER_API_KEY_VARS  
            declare -gA PROVIDER_DEFAULT_MODELS
            declare -gA PROVIDER_DESCRIPTIONS
            declare -gA PROVIDER_ENABLED
        else
            # Bash 4.0-4.1 with associative arrays but no declare -g
            declare -A PROVIDER_BASE_URLS
            declare -A PROVIDER_API_KEY_VARS  
            declare -A PROVIDER_DEFAULT_MODELS
            declare -A PROVIDER_DESCRIPTIONS
            declare -A PROVIDER_ENABLED
        fi
    else
        # Compatibility mode for Bash < 4.0
        if [[ "$declare_global_support" == "true" ]]; then
            # Bash 4.2+ with declare -g support
            declare -ga AVAILABLE_PROVIDERS
            declare -ga PROVIDER_BASE_URLS_KEYS PROVIDER_BASE_URLS_VALUES
            declare -ga PROVIDER_API_KEY_VARS_KEYS PROVIDER_API_KEY_VARS_VALUES
            declare -ga PROVIDER_DEFAULT_MODELS_KEYS PROVIDER_DEFAULT_MODELS_VALUES
            declare -ga PROVIDER_DESCRIPTIONS_KEYS PROVIDER_DESCRIPTIONS_VALUES
            declare -ga PROVIDER_ENABLED_KEYS PROVIDER_ENABLED_VALUES
        else
            # Older Bash versions without declare -g
            declare -a AVAILABLE_PROVIDERS
            declare -a PROVIDER_BASE_URLS_KEYS PROVIDER_BASE_URLS_VALUES
            declare -a PROVIDER_API_KEY_VARS_KEYS PROVIDER_API_KEY_VARS_VALUES
            declare -a PROVIDER_DEFAULT_MODELS_KEYS PROVIDER_DEFAULT_MODELS_VALUES
            declare -a PROVIDER_DESCRIPTIONS_KEYS PROVIDER_DESCRIPTIONS_VALUES
            declare -a PROVIDER_ENABLED_KEYS PROVIDER_ENABLED_VALUES
        fi
    fi
}

# Clear all provider arrays for test isolation
clear_provider_arrays() {
    local array_support="${1:-$BASH_ASSOC_ARRAY_SUPPORT}"
    
    if [[ "$array_support" == "true" ]]; then
        # Clear native associative arrays
        unset PROVIDER_BASE_URLS PROVIDER_API_KEY_VARS PROVIDER_DEFAULT_MODELS PROVIDER_DESCRIPTIONS PROVIDER_ENABLED
    else  
        # Clear compatibility arrays
        unset AVAILABLE_PROVIDERS
        unset PROVIDER_BASE_URLS_KEYS PROVIDER_BASE_URLS_VALUES
        unset PROVIDER_API_KEY_VARS_KEYS PROVIDER_API_KEY_VARS_VALUES
        unset PROVIDER_DEFAULT_MODELS_KEYS PROVIDER_DEFAULT_MODELS_VALUES
        unset PROVIDER_DESCRIPTIONS_KEYS PROVIDER_DESCRIPTIONS_VALUES
        unset PROVIDER_ENABLED_KEYS PROVIDER_ENABLED_VALUES
    fi
}

# Initialize test environment with proper array setup
init_test_environment() {
    local compatibility_mode="${1:-false}"
    
    # Set bash compatibility mode
    export BASH_ASSOC_ARRAY_SUPPORT="$([[ "$compatibility_mode" == "true" ]] && echo "false" || echo "true")"
    
    # Clear any existing arrays
    clear_provider_arrays
    
    # Declare global arrays for this test session
    declare_global_arrays
}

# Validate array state for debugging
validate_array_state() {
    local array_support="${1:-$BASH_ASSOC_ARRAY_SUPPORT}"
    
    echo "Array Support Mode: $array_support" >&2
    
    if [[ "$array_support" == "true" ]]; then
        echo "Native Arrays Status:" >&2
        echo "  PROVIDER_BASE_URLS: ${#PROVIDER_BASE_URLS[@]} entries" >&2
        echo "  PROVIDER_API_KEY_VARS: ${#PROVIDER_API_KEY_VARS[@]} entries" >&2
        echo "  PROVIDER_DEFAULT_MODELS: ${#PROVIDER_DEFAULT_MODELS[@]} entries" >&2
    else
        echo "Compatibility Arrays Status:" >&2
        echo "  AVAILABLE_PROVIDERS: ${#AVAILABLE_PROVIDERS[@]} entries" >&2  
        echo "  BASE_URLS: ${#PROVIDER_BASE_URLS_KEYS[@]} keys, ${#PROVIDER_BASE_URLS_VALUES[@]} values" >&2
        echo "  API_KEY_VARS: ${#PROVIDER_API_KEY_VARS_KEYS[@]} keys, ${#PROVIDER_API_KEY_VARS_VALUES[@]} values" >&2
    fi
}

# Helper to safely set provider data in tests
set_test_provider() {
    local provider_name="$1"
    local base_url="$2" 
    local api_key_var="$3"
    local model="$4"
    local description="$5"
    local enabled="${6:-true}"
    local array_support="${7:-$BASH_ASSOC_ARRAY_SUPPORT}"
    
    if [[ "$array_support" == "true" ]]; then
        # Use native associative arrays
        PROVIDER_BASE_URLS["$provider_name"]="$base_url"
        PROVIDER_API_KEY_VARS["$provider_name"]="$api_key_var"
        PROVIDER_DEFAULT_MODELS["$provider_name"]="$model"  
        PROVIDER_DESCRIPTIONS["$provider_name"]="$description"
        PROVIDER_ENABLED["$provider_name"]="$enabled"
    else
        # Use compatibility arrays
        AVAILABLE_PROVIDERS+=("$provider_name")
        
        PROVIDER_BASE_URLS_KEYS+=("$provider_name")
        PROVIDER_BASE_URLS_VALUES+=("$base_url")
        
        PROVIDER_API_KEY_VARS_KEYS+=("$provider_name")
        PROVIDER_API_KEY_VARS_VALUES+=("$api_key_var")
        
        PROVIDER_DEFAULT_MODELS_KEYS+=("$provider_name")
        PROVIDER_DEFAULT_MODELS_VALUES+=("$model")
        
        PROVIDER_DESCRIPTIONS_KEYS+=("$provider_name")
        PROVIDER_DESCRIPTIONS_VALUES+=("$description")
        
        PROVIDER_ENABLED_KEYS+=("$provider_name")
        PROVIDER_ENABLED_VALUES+=("$enabled")
    fi
}

# Helper to get provider data in tests
get_test_provider() {
    local array_name="$1"
    local provider_name="$2"
    local array_support="${3:-$BASH_ASSOC_ARRAY_SUPPORT}"
    
    if [[ "$array_support" == "true" ]]; then
        # Use native array access
        case "$array_name" in
            "PROVIDER_BASE_URLS") echo "${PROVIDER_BASE_URLS[$provider_name]:-}" ;;
            "PROVIDER_API_KEY_VARS") echo "${PROVIDER_API_KEY_VARS[$provider_name]:-}" ;;
            "PROVIDER_DEFAULT_MODELS") echo "${PROVIDER_DEFAULT_MODELS[$provider_name]:-}" ;;
            "PROVIDER_DESCRIPTIONS") echo "${PROVIDER_DESCRIPTIONS[$provider_name]:-}" ;;
            "PROVIDER_ENABLED") echo "${PROVIDER_ENABLED[$provider_name]:-}" ;;
            *) return 1 ;;
        esac
    else
        # Use compatibility array search
        case "$array_name" in
            "PROVIDER_BASE_URLS") 
                get_compat_value PROVIDER_BASE_URLS_KEYS PROVIDER_BASE_URLS_VALUES "$provider_name" ;;
            "PROVIDER_API_KEY_VARS")
                get_compat_value PROVIDER_API_KEY_VARS_KEYS PROVIDER_API_KEY_VARS_VALUES "$provider_name" ;;
            "PROVIDER_DEFAULT_MODELS")
                get_compat_value PROVIDER_DEFAULT_MODELS_KEYS PROVIDER_DEFAULT_MODELS_VALUES "$provider_name" ;;
            "PROVIDER_DESCRIPTIONS")
                get_compat_value PROVIDER_DESCRIPTIONS_KEYS PROVIDER_DESCRIPTIONS_VALUES "$provider_name" ;;
            "PROVIDER_ENABLED")
                get_compat_value PROVIDER_ENABLED_KEYS PROVIDER_ENABLED_VALUES "$provider_name" ;;
            *) return 1 ;;
        esac
    fi
}

# Helper function for compatibility array value lookup
get_compat_value() {
    local keys_array_name="$1"
    local values_array_name="$2"
    local search_key="$3"
    
    # Get array references
    local -n keys_ref="$keys_array_name"
    local -n values_ref="$values_array_name"
    
    # Linear search for key
    for i in "${!keys_ref[@]}"; do
        if [[ "${keys_ref[$i]}" == "$search_key" ]]; then
            echo "${values_ref[$i]:-}"
            return 0
        fi
    done
    
    return 1
}

# Test setup helper that ensures proper environment
setup_test_env() {
    local compatibility_mode="${1:-false}"
    
    # Initialize test environment
    init_test_environment "$compatibility_mode"
    
    # Create temporary test directory
    export BATS_TEST_TMPDIR="$BATS_TMPDIR/llm-env-bats-$$"
    mkdir -p "$BATS_TEST_TMPDIR"
    
    # Set up isolated config environment
    export ORIG_XDG_CONFIG_HOME="$XDG_CONFIG_HOME"
    export ORIG_HOME="$HOME"
    export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/.config"
    export HOME="$BATS_TEST_TMPDIR"
}

# Test teardown helper that cleans up environment
teardown_test_env() {
    # Restore original environment
    export XDG_CONFIG_HOME="$ORIG_XDG_CONFIG_HOME"
    export HOME="$ORIG_HOME"
    
    # Clear arrays
    clear_provider_arrays
    
    # Clean up temp directory
    [[ -n "$BATS_TEST_TMPDIR" ]] && rm -rf "$BATS_TEST_TMPDIR"
    unset BATS_TEST_TMPDIR
    
    # Clear test environment variables
    unset LLM_PROVIDER OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
}

# Helper to create test configuration files
create_test_config() {
    local config_content="$1"
    local config_dir="${2:-$XDG_CONFIG_HOME/llm-env}"
    
    mkdir -p "$config_dir"
    echo "$config_content" > "$config_dir/config.conf"
    echo "$config_dir/config.conf"
}

# Helper to verify provider exists in current configuration
assert_provider_exists() {
    local provider_name="$1"
    local array_support="${2:-$BASH_ASSOC_ARRAY_SUPPORT}"
    
    if [[ "$array_support" == "true" ]]; then
        [[ -n "${PROVIDER_BASE_URLS[$provider_name]:-}" ]]
    else
        for provider in "${AVAILABLE_PROVIDERS[@]}"; do
            [[ "$provider" == "$provider_name" ]] && return 0
        done
        return 1
    fi
}

# Helper to verify provider count
assert_provider_count() {
    local expected_count="$1"
    local array_support="${2:-$BASH_ASSOC_ARRAY_SUPPORT}"
    local actual_count
    
    if [[ "$array_support" == "true" ]]; then
        actual_count="${#PROVIDER_BASE_URLS[@]}"
    else
        actual_count="${#AVAILABLE_PROVIDERS[@]}"
    fi
    
    [[ "$actual_count" -eq "$expected_count" ]]
}