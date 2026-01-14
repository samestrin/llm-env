#!/usr/bin/env bash
# Bash Compatibility Library
# Provides associative array functionality for bash versions < 4.0

# Associative array compatibility layer using parallel indexed arrays
# Each "associative array" is represented by:
# - {name}_KEYS: indexed array of keys
# - {name}_VALUES: indexed array of values (parallel to keys)

# Set a key-value pair in a compatibility associative array
compat_assoc_set() {
    local array_name="$1"
    local key="$2"
    local value="$3"
    
    if [[ -z "$array_name" || -z "$key" ]]; then
        return 1
    fi
    
    local keys_array="${array_name}_KEYS"
    local values_array="${array_name}_VALUES"
    
    # Initialize arrays if they don't exist (but don't overwrite existing ones)
    if ! declare -p "$keys_array" >/dev/null 2>&1; then
        eval "${keys_array}=()"
    fi
    if ! declare -p "$values_array" >/dev/null 2>&1; then
        eval "${values_array}=()"
    fi
    
    # Get current arrays
    local -a keys
    local -a values
    eval "keys=(\"\${${keys_array}[@]}\")" 2>/dev/null || keys=()
    eval "values=(\"\${${values_array}[@]}\")" 2>/dev/null || values=()
    
    # Look for existing key
    local i
    for ((i=0; i<${#keys[@]}; i++)); do
        if [[ "${keys[i]}" == "$key" ]]; then
            # Update existing key
            values[i]="$value"
            # Use printf to avoid word splitting issues
            eval "${keys_array}=($(printf '%q ' "${keys[@]}"))"
            eval "${values_array}=($(printf '%q ' "${values[@]}"))"
            return 0
        fi
    done
    
    # Add new key-value pair
    keys+=("$key")
    values+=("$value")
    eval "${keys_array}=($(printf '%q ' "${keys[@]}"))"
    eval "${values_array}=($(printf '%q ' "${values[@]}"))"
}

# Get a value from a compatibility associative array
compat_assoc_get() {
    local array_name="$1"
    local key="$2"
    
    if [[ -z "$array_name" || -z "$key" ]]; then
        return 1
    fi
    
    local keys_array="${array_name}_KEYS"
    local values_array="${array_name}_VALUES"
    
    # Get current arrays
    local -a keys
    local -a values
    eval "keys=(\"\${${keys_array}[@]}\")" 2>/dev/null || keys=()
    eval "values=(\"\${${values_array}[@]}\")" 2>/dev/null || values=()
    
    # Look for key
    local i
    for ((i=0; i<${#keys[@]}; i++)); do
        if [[ "${keys[i]}" == "$key" ]]; then
            echo "${values[i]}"
            return 0
        fi
    done

    # Key not found - return 0 (success) with empty output
    # Caller should check for empty string if needed
    return 0
}

# Get all keys from a compatibility associative array
compat_assoc_keys() {
    local array_name="$1"
    
    if [[ -z "$array_name" ]]; then
        return 1
    fi
    
    local keys_array="${array_name}_KEYS"
    
    # Get and output keys
    eval "local -a keys=(\"\${${keys_array}[@]}\")"
    printf '%s\n' "${keys[@]}"
}

# Check if a key exists in a compatibility associative array
compat_assoc_has_key() {
    local array_name="$1"
    local key="$2"
    
    if [[ -z "$array_name" || -z "$key" ]]; then
        return 1
    fi
    
    local keys_array="${array_name}_KEYS"
    
    # Get current keys
    local -a keys
    eval "keys=(\"\${${keys_array}[@]}\")"
    
    # Look for key
    local i
    for ((i=0; i<${#keys[@]}; i++)); do
        if [[ "${keys[i]}" == "$key" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Get the number of key-value pairs in a compatibility associative array
compat_assoc_size() {
    local array_name="$1"
    
    if [[ -z "$array_name" ]]; then
        return 1
    fi
    
    local keys_array="${array_name}_KEYS"
    
    # Get keys and count them
    eval "local -a keys=(\"\${${keys_array}[@]}\")"
    echo "${#keys[@]}"
}