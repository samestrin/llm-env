#!/usr/bin/env bats

# Unit tests for the max_tool_use_concurrency provider config key.
#
# The key caps how many tool calls Claude Code runs in parallel against a
# rate-limited gateway. It parses to a plain decimal integer, which
# set_single_provider exports as CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY (see
# tests/integration/test_protocol_export.bats).
#
# Mirrors tests/unit/test_max_context_tokens.bats in shape and safety
# rationale, minus the k/m suffix (there is no unit to expand here -- a
# concurrency count is not a token count) and minus the huge-value overflow
# tier (three digits caps the range well inside any integer width).

load ../lib/bats_helpers

setup() {
    setup_test_env
    source "$BATS_TEST_DIRNAME/../../llm-env"
}

teardown() {
    teardown_test_env
}

# Write a one-provider config whose max_tool_use_concurrency is $1, load it,
# and leave the stored value in $mtc. stderr goes to $BATS_TEST_TMPDIR/warn so
# the warning text can be asserted; load_config is called directly rather than
# under `run`, which would discard the store it populates.
_load_with_value() {
    local cfg="$BATS_TEST_TMPDIR/mtc.conf"
    {
        echo "[mtc_provider]"
        echo "base_url=https://api.test.com/v1"
        echo "api_key_var=TEST_API_KEY"
        echo "default_model=test-model"
        echo "enabled=true"
        echo "protocol=anthropic"
        echo "max_tool_use_concurrency=$1"
    } > "$cfg"

    load_config "$cfg" 2>"$BATS_TEST_TMPDIR/warn"
    get_provider_value "PROVIDER_MAX_TOOL_USE_CONCURRENCY" "mtc_provider"; mtc="$__LLM_REPLY"
}

# ========================================
# Map registration
# ========================================

@test "max_tool_use_concurrency: PROVIDER_MAX_TOOL_USE_CONCURRENCY is a registered provider map" {
    [[ " $LLM_PROVIDER_MAPS " == *" PROVIDER_MAX_TOOL_USE_CONCURRENCY "* ]]
}

# ========================================
# Accepted forms
# ========================================

@test "max_tool_use_concurrency: a bare integer is stored unchanged" {
    local mtc
    _load_with_value "5"
    [ "$mtc" = "5" ]
}

@test "max_tool_use_concurrency: 1 is accepted at the lower boundary" {
    local mtc
    _load_with_value "1"
    [ "$mtc" = "1" ]
}

@test "max_tool_use_concurrency: 999 is accepted at the upper boundary" {
    local mtc
    _load_with_value "999"
    [ "$mtc" = "999" ]
}

@test "max_tool_use_concurrency: surrounding whitespace is trimmed" {
    local mtc
    _load_with_value "  5  "
    [ "$mtc" = "5" ]
}

@test "max_tool_use_concurrency: a valid value emits no warning" {
    _load_with_value "5"
    [ ! -s "$BATS_TEST_TMPDIR/warn" ]
}

# ========================================
# Rejected forms
# ========================================

@test "max_tool_use_concurrency: a non-numeric value is rejected" {
    local mtc
    _load_with_value "five"
    [ -z "$mtc" ]
}

@test "max_tool_use_concurrency: a fractional value is rejected" {
    local mtc
    _load_with_value "5.0"
    [ -z "$mtc" ]
}

@test "max_tool_use_concurrency: a negative value is rejected" {
    local mtc
    _load_with_value "-5"
    [ -z "$mtc" ]
}

@test "max_tool_use_concurrency: a leading plus is rejected" {
    local mtc
    _load_with_value "+5"
    [ -z "$mtc" ]
}

@test "max_tool_use_concurrency: a k suffix is rejected -- no unit here" {
    local mtc
    _load_with_value "5k"
    [ -z "$mtc" ]
}

@test "max_tool_use_concurrency: an m suffix is rejected -- no unit here" {
    local mtc
    _load_with_value "1m"
    [ -z "$mtc" ]
}

@test "max_tool_use_concurrency: a space before digits is rejected" {
    local mtc
    _load_with_value "5 5"
    [ -z "$mtc" ]
}

@test "max_tool_use_concurrency: an empty value is rejected" {
    local mtc
    _load_with_value ""
    [ -z "$mtc" ]
}

@test "max_tool_use_concurrency: a whitespace-only value is rejected" {
    local mtc
    _load_with_value "   "
    [ -z "$mtc" ]
}

# ========================================
# Config integration
# ========================================

@test "max_tool_use_concurrency: a rejected value warns naming the provider and the value" {
    _load_with_value "five"
    run cat "$BATS_TEST_TMPDIR/warn"
    [[ "$output" == *"max_tool_use_concurrency"* ]]
    [[ "$output" == *"five"* ]]
    [[ "$output" == *"mtc_provider"* ]]
}

@test "max_tool_use_concurrency: a rejected value does not prevent the provider loading" {
    local mtc base
    _load_with_value "five"
    get_provider_value "PROVIDER_BASE_URLS" "mtc_provider"; base="$__LLM_REPLY"
    [ "$base" = "https://api.test.com/v1" ]
}

@test "max_tool_use_concurrency: an absent key leaves the provider out of the map" {
    local cfg="$BATS_TEST_TMPDIR/no_mtc.conf"
    {
        echo "[no_mtc_provider]"
        echo "base_url=https://api.test.com/v1"
        echo "api_key_var=TEST_API_KEY"
        echo "default_model=test-model"
        echo "enabled=true"
        echo "protocol=anthropic"
    } > "$cfg"

    load_config "$cfg"
    get_provider_keys "PROVIDER_MAX_TOOL_USE_CONCURRENCY"
    local -a keys=(${__LLM_REPLY_KEYS[@]+"${__LLM_REPLY_KEYS[@]}"})
    for k in ${keys[@]+"${keys[@]}"}; do
        [ "$k" != "no_mtc_provider" ]
    done
}

@test "max_tool_use_concurrency: several providers each keep their own value" {
    local cfg="$BATS_TEST_TMPDIR/multi.conf"
    {
        echo "[prov_a]"
        echo "base_url=https://api.test.com/v1"
        echo "api_key_var=TEST_API_KEY"
        echo "default_model=test-model"
        echo "enabled=true"
        echo "protocol=anthropic"
        echo "max_tool_use_concurrency=3"
        echo
        echo "[prov_b]"
        echo "base_url=https://api.test.com/v1"
        echo "api_key_var=TEST_API_KEY"
        echo "default_model=test-model"
        echo "enabled=true"
        echo "protocol=anthropic"
        echo "max_tool_use_concurrency=10"
    } > "$cfg"

    load_config "$cfg"
    get_provider_value "PROVIDER_MAX_TOOL_USE_CONCURRENCY" "prov_a"; local a="$__LLM_REPLY"
    get_provider_value "PROVIDER_MAX_TOOL_USE_CONCURRENCY" "prov_b"; local b="$__LLM_REPLY"
    [ "$a" = "3" ]
    [ "$b" = "10" ]
}

# ========================================
# Leading zero handling (no $(( )) octal trap)
# ========================================

@test "max_tool_use_concurrency: 05 is five, not octal five" {
    local mtc
    _load_with_value "05"
    [ "$mtc" = "5" ]
}

@test "max_tool_use_concurrency: leading zeros are stripped" {
    local mtc
    _load_with_value "0010"
    [ "$mtc" = "10" ]
}

# ========================================
# Zero
# ========================================

@test "max_tool_use_concurrency: zero is rejected" {
    local mtc
    _load_with_value "0"
    [ -z "$mtc" ]
}

@test "max_tool_use_concurrency: repeated zeros are rejected" {
    local mtc
    _load_with_value "000"
    [ -z "$mtc" ]
}

# ========================================
# Range
# ========================================

@test "max_tool_use_concurrency: four digits is rejected at the out-of-range boundary" {
    local mtc
    _load_with_value "1000"
    [ -z "$mtc" ]
}

@test "max_tool_use_concurrency: an absurd value is rejected, not wrapped" {
    local mtc
    _load_with_value "99999999999999999999"
    [ -z "$mtc" ]
}

# ========================================
# Injection safety
# ========================================

@test "max_tool_use_concurrency: a shell metacharacter payload is rejected and never runs" {
    local mtc
    _load_with_value '5; touch /tmp/mtc_pwned'
    [ -z "$mtc" ]
    [ ! -e /tmp/mtc_pwned ]
}

@test "max_tool_use_concurrency: a command substitution payload is rejected and never runs" {
    local mtc
    _load_with_value '$(touch /tmp/mtc_pwned2)'
    [ -z "$mtc" ]
    [ ! -e /tmp/mtc_pwned2 ]
}
