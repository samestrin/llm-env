#!/usr/bin/env bats

# Unit tests for bash version detection and compatibility functions

# Define the parse_bash_version function locally for testing
parse_bash_version_test() {
    local version="${BASH_VERSION:-4.0.0}"
    local major minor
    
    # Extract major and minor version numbers
    if [[ "$version" =~ ^([0-9]+)\.([0-9]+) ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
    else
        # Fallback to conservative defaults if parsing fails
        major=3
        minor=2
    fi
    
    # Set global compatibility flags
    if [[ $major -gt 4 || ($major -eq 4 && $minor -ge 0) ]]; then
        BASH_ASSOC_ARRAY_SUPPORT=true
    else
        BASH_ASSOC_ARRAY_SUPPORT=false
    fi
    
    BASH_MAJOR_VERSION=$major
    BASH_MINOR_VERSION=$minor
}

@test "parse_bash_version: detects bash 5.x correctly" {
    BASH_VERSION="5.2.37(1)-release"
    
    parse_bash_version_test
    [ "$BASH_MAJOR_VERSION" = "5" ]
    [ "$BASH_MINOR_VERSION" = "2" ]
    [ "$BASH_ASSOC_ARRAY_SUPPORT" = "true" ]
}

@test "parse_bash_version: detects bash 4.0 correctly" {
    BASH_VERSION="4.0.44(1)-release"
    
    parse_bash_version_test
    [ "$BASH_MAJOR_VERSION" = "4" ]
    [ "$BASH_MINOR_VERSION" = "0" ]
    [ "$BASH_ASSOC_ARRAY_SUPPORT" = "true" ]
}

@test "parse_bash_version: detects bash 3.2 correctly" {
    BASH_VERSION="3.2.57(1)-release"
    
    parse_bash_version_test
    [ "$BASH_MAJOR_VERSION" = "3" ]
    [ "$BASH_MINOR_VERSION" = "2" ]
    [ "$BASH_ASSOC_ARRAY_SUPPORT" = "false" ]
}

@test "parse_bash_version: handles missing BASH_VERSION" {
    unset BASH_VERSION
    
    parse_bash_version_test
    [ "$BASH_MAJOR_VERSION" = "4" ]
    [ "$BASH_MINOR_VERSION" = "0" ]
    [ "$BASH_ASSOC_ARRAY_SUPPORT" = "true" ]
}

@test "parse_bash_version: handles malformed BASH_VERSION" {
    BASH_VERSION="invalid-version-string"
    
    parse_bash_version_test
    [ "$BASH_MAJOR_VERSION" = "3" ]
    [ "$BASH_MINOR_VERSION" = "2" ]
    [ "$BASH_ASSOC_ARRAY_SUPPORT" = "false" ]
}

@test "parse_bash_version: handles edge case version formats" {
    BASH_VERSION="4.3"
    
    parse_bash_version_test
    [ "$BASH_MAJOR_VERSION" = "4" ]
    [ "$BASH_MINOR_VERSION" = "3" ]
    [ "$BASH_ASSOC_ARRAY_SUPPORT" = "true" ]
}