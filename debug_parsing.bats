#!/usr/bin/env bats

@test "debug parsing step by step" {
    # Create test config
    export TEST_HOME="$BATS_TMPDIR/debug-parse-$$"
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

    echo "Config file contents:" >&3
    cat "$TEST_HOME/.config/llm-env/config.conf" >&3
    echo "---" >&3
    
    # Initialize empty arrays first
    declare -A PROVIDER_BASE_URLS
    declare -A PROVIDER_API_KEY_VARS  
    declare -A PROVIDER_DEFAULT_MODELS
    declare -A PROVIDER_DESCRIPTIONS
    declare -A PROVIDER_ENABLED
    declare -a AVAILABLE_PROVIDERS
    
    # Define load_config function manually for debugging
    load_config() {
        local config_file="$1"
        echo "Loading config from: $config_file" >&3
        [[ ! -f "$config_file" ]] && { echo "Config file not found: $config_file" >&3; return 1; }
        
        local current_provider=""
        local line_num=0
        
        while IFS= read -r line || [[ -n "$line" ]]; do
            ((line_num++))
            echo "Line $line_num: '$line'" >&3
            
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && { echo "  -> Skipping comment" >&3; continue; }
            [[ "$line" =~ ^[[:space:]]*$ ]] && { echo "  -> Skipping empty" >&3; continue; }
            
            # Provider section header
            if [[ "$line" =~ ^\[([^]]+)\]$ ]]; then
                current_provider="${BASH_REMATCH[1]}"
                echo "  -> Found provider: '$current_provider'" >&3
                continue
            fi
            
            # Skip if no current provider
            [[ -z "$current_provider" ]] && { echo "  -> No current provider, skipping" >&3; continue; }
            
            # Parse key=value pairs
            if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${BASH_REMATCH[2]}"
                
                # Trim whitespace
                key="$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
                value="$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
                
                echo "  -> Key: '$key', Value: '$value'" >&3
                
                case "$key" in
                    base_url)
                        PROVIDER_BASE_URLS["$current_provider"]="$value"
                        echo "    -> Set base_url for $current_provider" >&3
                        ;;
                    api_key_var)
                        PROVIDER_API_KEY_VARS["$current_provider"]="$value"
                        echo "    -> Set api_key_var for $current_provider" >&3
                        ;;
                    default_model)
                        PROVIDER_DEFAULT_MODELS["$current_provider"]="$value"
                        echo "    -> Set default_model for $current_provider" >&3
                        ;;
                    description)
                        PROVIDER_DESCRIPTIONS["$current_provider"]="$value"
                        echo "    -> Set description for $current_provider" >&3
                        ;;
                    enabled)
                        PROVIDER_ENABLED["$current_provider"]="$value"
                        echo "    -> Set enabled for $current_provider" >&3
                        ;;
                    *)
                        echo "    -> Unknown key: $key" >&3
                        ;;
                esac
            else
                echo "  -> Line does not match key=value pattern" >&3
            fi
        done < "$config_file"
        
        echo "After parsing:" >&3
        echo "PROVIDER_BASE_URLS keys: ${!PROVIDER_BASE_URLS[*]}" >&3
        return 0
    }
    
    # Test the parsing
    load_config "$TEST_HOME/.config/llm-env/config.conf"
    
    echo "Final result:" >&3
    echo "PROVIDER_BASE_URLS[test_provider]: ${PROVIDER_BASE_URLS[test_provider]:-EMPTY}" >&3
    
    [[ -n "${PROVIDER_BASE_URLS[test_provider]:-}" ]]
}