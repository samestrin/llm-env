#!/usr/bin/env bats
#
# Accessor return-value contract.
#
# The scalar accessors return via the global $__LLM_REPLY instead of echoing to
# stdout, so callers stop forking a subshell per read. $__LLM_REPLY is empty for
# a missing OR empty key; existence is decided only by has_provider_key.
#
# These used to be duplicated into "(native)" and "(compat)" pairs, forced with
# BASH_ASSOC_ARRAY_SUPPORT. That forcing was inert on bash 4+ -- the flag is
# overwritten by parse_bash_version at source time, after the guard that
# conditionally defined compat_assoc_* -- so both halves of every pair ran the
# same native path and the compat half proved nothing. There is one backend
# now, so each behaviour is asserted once and holds on every shell.

setup() {
    export LLM_ENV_DEBUG=0
    source "$BATS_TEST_DIRNAME/../../llm-env" >/dev/null 2>&1
    clear_provider_map PROVIDER_BASE_URLS
    clear_provider_map PROVIDER_ENABLED
}

# ---- get_provider_value ----

@test "get_provider_value: sets __LLM_REPLY to the value" {
    set_provider_value "PROVIDER_BASE_URLS" "acme" "https://api.acme.test/v1"
    __LLM_REPLY="SENTINEL"
    get_provider_value "PROVIDER_BASE_URLS" "acme"
    [ "$__LLM_REPLY" = "https://api.acme.test/v1" ]
}

@test "get_provider_value: __LLM_REPLY empty on missing key" {
    __LLM_REPLY="SENTINEL"
    get_provider_value "PROVIDER_BASE_URLS" "does_not_exist"
    [ -z "$__LLM_REPLY" ]
}

@test "get_provider_value: empty stored value yields empty __LLM_REPLY" {
    set_provider_value "PROVIDER_ENABLED" "acme" ""
    __LLM_REPLY="SENTINEL"
    get_provider_value "PROVIDER_ENABLED" "acme"
    [ -z "$__LLM_REPLY" ]
}

@test "get_provider_value: emits no stdout" {
    set_provider_value "PROVIDER_BASE_URLS" "acme" "https://api.acme.test/v1"
    run get_provider_value "PROVIDER_BASE_URLS" "acme"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "get_provider_value: a missing key is indistinguishable from an empty value" {
    # Documented invariant: callers must use has_provider_key for existence.
    set_provider_value "PROVIDER_ENABLED" "empty" ""
    get_provider_value "PROVIDER_ENABLED" "empty";   local a="$__LLM_REPLY"
    get_provider_value "PROVIDER_ENABLED" "missing"; local b="$__LLM_REPLY"
    [ "$a" = "$b" ]
    has_provider_key "PROVIDER_ENABLED" "empty"
    run has_provider_key "PROVIDER_ENABLED" "missing"
    [ "$status" -ne 0 ]
}

# ---- get_var_value ----

@test "get_var_value: sets __LLM_REPLY to the variable's value" {
    export LLM_ACCESSOR_TEST_VAR="secret-token-123"
    __LLM_REPLY="SENTINEL"
    get_var_value "LLM_ACCESSOR_TEST_VAR"
    [ "$__LLM_REPLY" = "secret-token-123" ]
}

@test "get_var_value: __LLM_REPLY empty for unset variable" {
    unset LLM_ACCESSOR_UNSET_VAR 2>/dev/null || true
    __LLM_REPLY="SENTINEL"
    get_var_value "LLM_ACCESSOR_UNSET_VAR"
    [ -z "$__LLM_REPLY" ]
}

@test "get_var_value: emits no stdout" {
    export LLM_ACCESSOR_TEST_VAR="secret-token-123"
    run get_var_value "LLM_ACCESSOR_TEST_VAR"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ---- get_match ----

@test "get_match: sets __LLM_REPLY from the regex capture group" {
    [[ "key=value" =~ ^([^=]+)=(.*)$ ]]
    __LLM_REPLY="SENTINEL"
    get_match 1
    [ "$__LLM_REPLY" = "key" ]
    get_match 2
    [ "$__LLM_REPLY" = "value" ]
}

@test "get_match: emits no stdout" {
    [[ "abc=def" =~ ^([^=]+)=(.*)$ ]]
    run get_match 1
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ---- structural guards: no subshell forks reintroduced ----
#
# The accessors exist in this shape purely to avoid a fork per read. A
# $(accessor ...) call site silently reverts that, so guard it structurally --
# a performance regression is otherwise invisible until someone profiles.

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

@test "source has no \$(has_provider_key ...) call sites" {
    run grep -n '\$(has_provider_key' "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -ne 0 ]
}

@test "source has no \$(get_provider_keys ...) call sites" {
    run grep -n '\$(get_provider_keys' "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -ne 0 ]
}

@test "parser trims without echo|sed subshells" {
    run grep -nE '\$\(echo "\$(key|value)" \| sed' "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -ne 0 ]
}

# ---- structural guards: the removed backends stay removed ----
#
# These replace two guards that became vacuous once compat_assoc_* was deleted
# (they grepped for strings that can no longer appear, so they always passed).

@test "the dual-backend associative array code is gone" {
    run grep -nE 'compat_assoc_(set|get|keys|has_key|size)' "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -ne 0 ]
}

@test "no declare -A / -gA remains: it broke bash 4.0/4.1 scoping" {
    # A bare `declare -A` inside init_config created function-locals that died
    # on return, emptying the provider set on bash 4.0/4.1.
    run grep -nE '^[[:space:]]*declare -g?A ' "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -ne 0 ]
}

@test "init_config derives its reset from the single map list" {
    # The two backends drifted because each repeated the map names. The reset
    # must iterate LLM_PROVIDER_MAPS so it cannot fall out of sync again.
    run grep -n 'for __m in \$LLM_PROVIDER_MAPS' "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -eq 0 ]
}
