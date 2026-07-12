#!/usr/bin/env bats
#
# Accessor return-value contract (performance refactor).
#
# The scalar accessors return via the global $REPLY instead of echoing to
# stdout, so callers stop forking a subshell per read. $REPLY is empty for a
# missing OR empty key (existence is decided only by has_provider_key). These
# tests pin that contract on both the native (BASH_ASSOC_ARRAY_SUPPORT=true)
# and the bash-3.2 compat (=false) paths.

setup() {
    export LLM_ENV_DEBUG=0
    source "$BATS_TEST_DIRNAME/../../llm-env" >/dev/null 2>&1
}

# ---- get_provider_value: native path ----

@test "get_provider_value: sets REPLY to the value (native)" {
    export BASH_ASSOC_ARRAY_SUPPORT="true"
    source "$BATS_TEST_DIRNAME/../../llm-env" >/dev/null 2>&1
    set_provider_value "PROVIDER_BASE_URLS" "acme" "https://api.acme.test/v1"
    REPLY="SENTINEL"
    get_provider_value "PROVIDER_BASE_URLS" "acme"
    [ "$REPLY" = "https://api.acme.test/v1" ]
}

@test "get_provider_value: REPLY empty on missing key (native)" {
    export BASH_ASSOC_ARRAY_SUPPORT="true"
    source "$BATS_TEST_DIRNAME/../../llm-env" >/dev/null 2>&1
    REPLY="SENTINEL"
    get_provider_value "PROVIDER_BASE_URLS" "does_not_exist"
    [ -z "$REPLY" ]
}

@test "get_provider_value: emits no stdout (native)" {
    export BASH_ASSOC_ARRAY_SUPPORT="true"
    source "$BATS_TEST_DIRNAME/../../llm-env" >/dev/null 2>&1
    set_provider_value "PROVIDER_BASE_URLS" "acme" "https://api.acme.test/v1"
    run get_provider_value "PROVIDER_BASE_URLS" "acme"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ---- get_provider_value: compat (bash 3.2) path ----

@test "get_provider_value: sets REPLY to the value (compat)" {
    export BASH_ASSOC_ARRAY_SUPPORT="false"
    source "$BATS_TEST_DIRNAME/../../llm-env" >/dev/null 2>&1
    set_provider_value "PROVIDER_BASE_URLS" "acme" "https://api.acme.test/v1"
    REPLY="SENTINEL"
    get_provider_value "PROVIDER_BASE_URLS" "acme"
    [ "$REPLY" = "https://api.acme.test/v1" ]
}

@test "get_provider_value: REPLY empty on missing key (compat)" {
    export BASH_ASSOC_ARRAY_SUPPORT="false"
    source "$BATS_TEST_DIRNAME/../../llm-env" >/dev/null 2>&1
    REPLY="SENTINEL"
    get_provider_value "PROVIDER_BASE_URLS" "does_not_exist"
    [ -z "$REPLY" ]
}

@test "get_provider_value: emits no stdout (compat)" {
    export BASH_ASSOC_ARRAY_SUPPORT="false"
    source "$BATS_TEST_DIRNAME/../../llm-env" >/dev/null 2>&1
    set_provider_value "PROVIDER_BASE_URLS" "acme" "https://api.acme.test/v1"
    run get_provider_value "PROVIDER_BASE_URLS" "acme"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "get_provider_value: empty stored value yields empty REPLY (compat)" {
    export BASH_ASSOC_ARRAY_SUPPORT="false"
    source "$BATS_TEST_DIRNAME/../../llm-env" >/dev/null 2>&1
    set_provider_value "PROVIDER_ENABLED" "acme" ""
    REPLY="SENTINEL"
    get_provider_value "PROVIDER_ENABLED" "acme"
    [ -z "$REPLY" ]
}

# ---- get_var_value ----

@test "get_var_value: sets REPLY to the variable's value" {
    export LLM_ACCESSOR_TEST_VAR="secret-token-123"
    REPLY="SENTINEL"
    get_var_value "LLM_ACCESSOR_TEST_VAR"
    [ "$REPLY" = "secret-token-123" ]
}

@test "get_var_value: REPLY empty for unset variable" {
    unset LLM_ACCESSOR_UNSET_VAR 2>/dev/null || true
    REPLY="SENTINEL"
    get_var_value "LLM_ACCESSOR_UNSET_VAR"
    [ -z "$REPLY" ]
}

@test "get_var_value: emits no stdout" {
    export LLM_ACCESSOR_TEST_VAR="secret-token-123"
    run get_var_value "LLM_ACCESSOR_TEST_VAR"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ---- get_match ----

@test "get_match: sets REPLY from BASH_REMATCH capture group" {
    [[ "key=value" =~ ^([^=]+)=(.*)$ ]]
    REPLY="SENTINEL"
    get_match 1
    [ "$REPLY" = "key" ]
    get_match 2
    [ "$REPLY" = "value" ]
}

@test "get_match: emits no stdout" {
    [[ "abc=def" =~ ^([^=]+)=(.*)$ ]]
    run get_match 1
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ---- structural guard: no subshell forks reintroduced ----

@test "source has no \$(get_provider_value ...) call sites" {
    run grep -n '\$(get_provider_value' "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -ne 0 ]
}

@test "source has no \$(get_var_value ...) call sites" {
    run grep -n '\$(get_var_value' "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -ne 0 ]
}

@test "source has no \$(get_match ...) call sites" {
    run grep -n '\$(get_match' "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -ne 0 ]
}

@test "parser trims without echo|sed subshells" {
    run grep -nE '\$\(echo "\$(key|value)" \| sed' "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -ne 0 ]
}

# ---- O(N) compat-layer structural guards (shell-agnostic; run everywhere) ----

@test "compat_assoc_set no longer rewrites the whole array with printf %q" {
    run grep -n "printf '%q'" "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -ne 0 ]
}

@test "dead code compat_assoc_size is removed" {
    run grep -n "compat_assoc_size" "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -ne 0 ]
}
