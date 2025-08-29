#!/usr/bin/env bats

@test "debug load_config function directly" {
    # Create test config
    export TEST_HOME="$BATS_TMPDIR/load-config-debug-$$"
    mkdir -p "$TEST_HOME/.config/llm-env"
    
    cat > "$TEST_HOME/test.conf" << 'EOF'
[test_provider]
base_url=https://api.example.com/v1
api_key_var=LLM_TEST_API_KEY
default_model=test-model-v1
description=Test provider
enabled=true
EOF

    # Initialize arrays manually
    declare -A PROVIDER_BASE_URLS
    declare -A PROVIDER_API_KEY_VARS  
    declare -A PROVIDER_DEFAULT_MODELS
    declare -A PROVIDER_DESCRIPTIONS
    declare -A PROVIDER_ENABLED
    
    # Enable debug
    export LLM_ENV_DEBUG=1
    
    # Define load_config manually with debug output
    load_config() {
        local config_file="$1"
        echo "DEBUG: load_config called with: $config_file" >&3
        [[ ! -f "$config_file" ]] && { echo "Config file not found: $config_file" >&3; return 1; }
        
        local current_provider=""
        local line_num=0
        
        while IFS= read -r line || [[ -n "$line" ]]; do
            ((line_num++))
            echo "DEBUG: Line $line_num: '$line'" >&3
            
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ "$line" =~ ^[[:space:]]*$ ]] && continue
            
            # Provider section header
            if [[ "$line" =~ ^\[([^]]+)\]$ ]]; then
                current_provider="${BASH_REMATCH[1]}"
                echo "DEBUG: Found provider: '$current_provider'" >&3
                continue
            fi
            
            # Skip if no current provider
            [[ -z "$current_provider" ]] && continue
            
            # Parse key=value pairs
            if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${BASH_REMATCH[2]}"
                
                # Trim whitespace
                key="$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
                value="$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
                
                echo "DEBUG: Setting $current_provider.$key = '$value'" >&3
                
                case "$key" in
                    base_url)
                        PROVIDER_BASE_URLS["$current_provider"]="$value"
                        echo "DEBUG: PROVIDER_BASE_URLS[$current_provider] set to '${PROVIDER_BASE_URLS[$current_provider]}'" >&3
                        ;;
                    api_key_var)
                        PROVIDER_API_KEY_VARS["$current_provider"]="$value"
                        ;;
                    default_model)
                        PROVIDER_DEFAULT_MODELS["$current_provider"]="$value"
                        ;;
                    description)
                        PROVIDER_DESCRIPTIONS["$current_provider"]="$value"
                        ;;
                    enabled)
                        PROVIDER_ENABLED["$current_provider"]="$value"
                        ;;
                esac
            fi
        done < "$config_file"
        
        echo "DEBUG: After parsing, PROVIDER_BASE_URLS keys: ${!PROVIDER_BASE_URLS[*]}" >&3
        echo "DEBUG: test_provider base_url: ${PROVIDER_BASE_URLS[test_provider]:-EMPTY}" >&3
        return 0
    }
    
    # Test load_config
    run load_config "$TEST_HOME/test.conf"
    echo "load_config status: $status" >&3
    
    [ "$status" -eq 0 ]
    [[ -n "${PROVIDER_BASE_URLS[test_provider]:-}" ]]
}