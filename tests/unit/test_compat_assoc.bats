#!/usr/bin/env bats
#
# Provider store semantics.
#
# Historically this exercised the bash-3.2 parallel-array backend, forced via
# BASH_ASSOC_ARRAY_SUPPORT=false. That forcing never worked on bash 4+:
# parse_bash_version overwrites the flag at source time, AFTER the guard that
# conditionally defines compat_assoc_*, so the functions were simply undefined
# and the whole file skipped. Every assertion here was dead on CI, which runs
# Linux/bash 5.
#
# There is now a single eval-free store on every shell, so these behaviours are
# testable everywhere -- including the value-fidelity cases (apostrophe, double
# quotes, backslash, metacharacters), which double as injection regressions:
# the old native backend interpolated values into eval and could not survive an
# apostrophe at all.

setup() {
    export LLM_ENV_DEBUG=0
    source "$BATS_TEST_DIRNAME/../../llm-env" >/dev/null 2>&1
    # Fresh map for isolation.
    clear_provider_map TESTMAP
}

@test "store set/get: stores and retrieves a value" {
    set_provider_value "TESTMAP" "alpha" "one"
    get_provider_value "TESTMAP" "alpha"
    [ "$__LLM_REPLY" = "one" ]
}

@test "store set: update-in-place overwrites existing key, no duplicate" {
    set_provider_value "TESTMAP" "alpha" "one"
    set_provider_value "TESTMAP" "alpha" "two"
    get_provider_value "TESTMAP" "alpha"
    [ "$__LLM_REPLY" = "two" ]
    get_provider_keys "TESTMAP"
    [ "${#__LLM_REPLY_KEYS[@]}" -eq 1 ]
}

@test "store set: append keeps all distinct keys" {
    set_provider_value "TESTMAP" "a" "1"
    set_provider_value "TESTMAP" "b" "2"
    set_provider_value "TESTMAP" "c" "3"
    get_provider_value "TESTMAP" "a"; [ "$__LLM_REPLY" = "1" ]
    get_provider_value "TESTMAP" "b"; [ "$__LLM_REPLY" = "2" ]
    get_provider_value "TESTMAP" "c"; [ "$__LLM_REPLY" = "3" ]
    get_provider_keys "TESTMAP"
    [ "${#__LLM_REPLY_KEYS[@]}" -eq 3 ]
}

@test "store set: preserves insertion order of keys" {
    set_provider_value "TESTMAP" "zeta" "1"
    set_provider_value "TESTMAP" "alpha" "2"
    set_provider_value "TESTMAP" "mu" "3"
    get_provider_keys "TESTMAP"
    [ "${__LLM_REPLY_KEYS[0]}" = "zeta" ]
    [ "${__LLM_REPLY_KEYS[1]}" = "alpha" ]
    [ "${__LLM_REPLY_KEYS[2]}" = "mu" ]
}

@test "store set/get: value with spaces" {
    set_provider_value "TESTMAP" "k" "hello there world"
    get_provider_value "TESTMAP" "k"
    [ "$__LLM_REPLY" = "hello there world" ]
}

@test "store set/get: value with shell metacharacters" {
    set_provider_value "TESTMAP" "k" 'a$b&c|d;e/f:g=h'
    get_provider_value "TESTMAP" "k"
    [ "$__LLM_REPLY" = 'a$b&c|d;e/f:g=h' ]
}

@test "store set/get: value with a leading dash" {
    set_provider_value "TESTMAP" "k" "-n"
    get_provider_value "TESTMAP" "k"
    [ "$__LLM_REPLY" = "-n" ]
}

@test "store set/get: value with a backslash" {
    set_provider_value "TESTMAP" "k" 'a\b\c'
    get_provider_value "TESTMAP" "k"
    [ "$__LLM_REPLY" = 'a\b\c' ]
}

@test "store set/get: value with an apostrophe" {
    set_provider_value "TESTMAP" "k" "it's a test"
    get_provider_value "TESTMAP" "k"
    [ "$__LLM_REPLY" = "it's a test" ]
}

@test "store set/get: value with double quotes" {
    set_provider_value "TESTMAP" "k" 'say "hi"'
    get_provider_value "TESTMAP" "k"
    [ "$__LLM_REPLY" = 'say "hi"' ]
}

@test "store get: empty __LLM_REPLY on missing key" {
    set_provider_value "TESTMAP" "a" "1"
    __LLM_REPLY="SENTINEL"
    get_provider_value "TESTMAP" "missing"
    [ -z "$__LLM_REPLY" ]
}

@test "store has_provider_key: true on hit, false on miss" {
    set_provider_value "TESTMAP" "a" "1"
    has_provider_key "TESTMAP" "a"
    [ "$?" -eq 0 ]
    run has_provider_key "TESTMAP" "missing"
    [ "$status" -ne 0 ]
}

@test "store has_provider_key: key with empty value still exists" {
    set_provider_value "TESTMAP" "a" ""
    has_provider_key "TESTMAP" "a"
    [ "$?" -eq 0 ]
}

# ---- semantics unified by the single-backend rewrite ----
#
# Each of these used to differ between the native and compat backends, which is
# why golden-output assertions on cmd_list were impossible to write portably.

@test "store has_provider_key: matches exactly, not as a glob" {
    # zsh's ${arr[(I)key]} is a pattern match, so has_provider_key ARR 'op*'
    # returned true under zsh and false everywhere else.
    set_provider_value "TESTMAP" "openai" "1"
    run has_provider_key "TESTMAP" "op*"
    [ "$status" -ne 0 ]
    run has_provider_key "TESTMAP" "openai"
    [ "$status" -eq 0 ]
}

@test "store set: rejects an empty key" {
    run set_provider_value "TESTMAP" "" "value"
    [ "$status" -ne 0 ]
}

@test "store set: rejects a key with shell metacharacters" {
    run set_provider_value "TESTMAP" 'a$(id)b' "value"
    [ "$status" -ne 0 ]
    run has_provider_key "TESTMAP" 'a$(id)b'
    [ "$status" -ne 0 ]
}

@test "store set: rejects a key containing whitespace" {
    run set_provider_value "TESTMAP" "my provider" "value"
    [ "$status" -ne 0 ]
}

@test "store set: accepts dots and hyphens (quickstart v2 model ids)" {
    set_provider_value "TESTMAP" "openai_synth_kimi-k2.5" "url"
    get_provider_value "TESTMAP" "openai_synth_kimi-k2.5"
    [ "$__LLM_REPLY" = "url" ]
}

@test "store: keys differing only by hyphen vs underscore are distinct" {
    set_provider_value "TESTMAP" "a-b" "dash"
    set_provider_value "TESTMAP" "a_b" "under"
    get_provider_value "TESTMAP" "a-b";  [ "$__LLM_REPLY" = "dash" ]
    get_provider_value "TESTMAP" "a_b";  [ "$__LLM_REPLY" = "under" ]
    get_provider_keys "TESTMAP"
    [ "${#__LLM_REPLY_KEYS[@]}" -eq 2 ]
}

@test "store: clear_provider_map removes every key" {
    set_provider_value "TESTMAP" "a" "1"
    set_provider_value "TESTMAP" "b" "2"
    clear_provider_map "TESTMAP"
    get_provider_keys "TESTMAP"
    [ "${#__LLM_REPLY_KEYS[@]}" -eq 0 ]
    run has_provider_key "TESTMAP" "a"
    [ "$status" -ne 0 ]
}

@test "store: a cleared map can be repopulated" {
    # Removed providers used to persist forever on bash 3.2, because only the
    # native backend was ever reset.
    set_provider_value "TESTMAP" "old" "1"
    clear_provider_map "TESTMAP"
    set_provider_value "TESTMAP" "new" "2"
    get_provider_keys "TESTMAP"
    [ "${#__LLM_REPLY_KEYS[@]}" -eq 1 ]
    [ "${__LLM_REPLY_KEYS[0]}" = "new" ]
}
