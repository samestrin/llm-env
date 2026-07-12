#!/usr/bin/env bats
#
# Bash-3.2 compatibility associative-array layer.
#
# compat_assoc_set updates/appends a single element (O(1)) instead of
# rewriting the whole parallel array with printf '%q' + eval (O(N) per set,
# O(N^2) per load). These tests characterize the behavior that MUST be
# preserved: update-in-place, append, insertion order, and fidelity for
# arbitrary values (including an apostrophe, which the native eval path
# cannot survive). They force the compat path via BASH_ASSOC_ARRAY_SUPPORT.

setup() {
    export LLM_ENV_DEBUG=0
    export BASH_ASSOC_ARRAY_SUPPORT="false"
    source "$BATS_TEST_DIRNAME/../../llm-env" >/dev/null 2>&1
    # The compat associative-array backend only exists on bash < 4.0. On bash
    # 4+/zsh, parse_bash_version resets BASH_ASSOC_ARRAY_SUPPORT to true at source
    # time and compat_assoc_set is never defined, so these behavioral tests can
    # only run where that backend is actually active (i.e. bash 3.2).
    if ! declare -f compat_assoc_set >/dev/null 2>&1; then
        skip "compat associative-array path not active (native bash 4+/zsh backend)"
    fi
    # Fresh arrays for isolation
    unset TESTMAP_KEYS TESTMAP_VALUES
    TESTMAP_KEYS=(); TESTMAP_VALUES=()
}

@test "compat set/get: stores and retrieves a value" {
    set_provider_value "TESTMAP" "alpha" "one"
    get_provider_value "TESTMAP" "alpha"
    [ "$REPLY" = "one" ]
}

@test "compat set: update-in-place overwrites existing key, no duplicate" {
    set_provider_value "TESTMAP" "alpha" "one"
    set_provider_value "TESTMAP" "alpha" "two"
    get_provider_value "TESTMAP" "alpha"
    [ "$REPLY" = "two" ]
    get_provider_keys "TESTMAP"
    [ "${#REPLY_KEYS[@]}" -eq 1 ]
}

@test "compat set: append keeps all distinct keys" {
    set_provider_value "TESTMAP" "a" "1"
    set_provider_value "TESTMAP" "b" "2"
    set_provider_value "TESTMAP" "c" "3"
    get_provider_value "TESTMAP" "a"; [ "$REPLY" = "1" ]
    get_provider_value "TESTMAP" "b"; [ "$REPLY" = "2" ]
    get_provider_value "TESTMAP" "c"; [ "$REPLY" = "3" ]
    get_provider_keys "TESTMAP"
    [ "${#REPLY_KEYS[@]}" -eq 3 ]
}

@test "compat set: preserves insertion order of keys" {
    set_provider_value "TESTMAP" "zeta" "1"
    set_provider_value "TESTMAP" "alpha" "2"
    set_provider_value "TESTMAP" "mu" "3"
    get_provider_keys "TESTMAP"
    [ "${REPLY_KEYS[0]}" = "zeta" ]
    [ "${REPLY_KEYS[1]}" = "alpha" ]
    [ "${REPLY_KEYS[2]}" = "mu" ]
}

@test "compat set/get: value with spaces" {
    set_provider_value "TESTMAP" "k" "hello there world"
    get_provider_value "TESTMAP" "k"
    [ "$REPLY" = "hello there world" ]
}

@test "compat set/get: value with shell metacharacters" {
    set_provider_value "TESTMAP" "k" 'a$b&c|d;e/f:g=h'
    get_provider_value "TESTMAP" "k"
    [ "$REPLY" = 'a$b&c|d;e/f:g=h' ]
}

@test "compat set/get: value with a leading dash" {
    set_provider_value "TESTMAP" "k" "-n"
    get_provider_value "TESTMAP" "k"
    [ "$REPLY" = "-n" ]
}

@test "compat set/get: value with a backslash" {
    set_provider_value "TESTMAP" "k" 'a\b\c'
    get_provider_value "TESTMAP" "k"
    [ "$REPLY" = 'a\b\c' ]
}

@test "compat set/get: value with an apostrophe" {
    set_provider_value "TESTMAP" "k" "it's a test"
    get_provider_value "TESTMAP" "k"
    [ "$REPLY" = "it's a test" ]
}

@test "compat set/get: value with double quotes" {
    set_provider_value "TESTMAP" "k" 'say "hi"'
    get_provider_value "TESTMAP" "k"
    [ "$REPLY" = 'say "hi"' ]
}

@test "compat get: empty REPLY on missing key" {
    set_provider_value "TESTMAP" "a" "1"
    REPLY="SENTINEL"
    get_provider_value "TESTMAP" "missing"
    [ -z "$REPLY" ]
}

@test "compat has_provider_key: true on hit, false on miss" {
    set_provider_value "TESTMAP" "a" "1"
    has_provider_key "TESTMAP" "a"
    [ "$?" -eq 0 ]
    run has_provider_key "TESTMAP" "missing"
    [ "$status" -ne 0 ]
}

@test "compat has_provider_key: key with empty value still exists" {
    set_provider_value "TESTMAP" "a" ""
    has_provider_key "TESTMAP" "a"
    [ "$?" -eq 0 ]
}

# Structural guards for the O(N) rewrite (printf %q removal, dead-code removal)
# live in test_accessor_contract.bats so they run on every shell, not only where
# the compat backend is active (this file's setup skips on bash 4+/zsh).
