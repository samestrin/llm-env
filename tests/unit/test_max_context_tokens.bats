#!/usr/bin/env bats

# Unit tests for the max_context_tokens provider config key.
#
# The key declares a model's real context window so Claude Code can size
# auto-compact correctly for a third-party model it does not recognize. It
# parses to a plain decimal token count, which set_single_provider exports as
# CLAUDE_CODE_MAX_CONTEXT_TOKENS (see tests/integration/test_protocol_export.bats).
#
# Style follows tests/unit/test_protocols.bats -- inline heredoc config, a
# direct load_config, and read-back through get_provider_value/__LLM_REPLY --
# but this file loads bats_helpers so setup_test_env can point HOME and
# XDG_CONFIG_HOME at a temp dir. Without that, sourcing llm-env auto-loads the
# developer's real ~/.config/llm-env/config.conf.

load ../lib/bats_helpers

setup() {
    setup_test_env
    source "$BATS_TEST_DIRNAME/../../llm-env"
}

teardown() {
    teardown_test_env
}

# Write a one-provider config whose max_context_tokens is $1, load it, and
# leave the stored value in $mct. stderr goes to $BATS_TEST_TMPDIR/warn so the
# warning text can be asserted; load_config is called directly rather than
# under `run`, which would discard the store it populates.
_load_with_value() {
    local cfg="$BATS_TEST_TMPDIR/mct.conf"
    {
        echo "[mct_provider]"
        echo "base_url=https://api.test.com/v1"
        echo "api_key_var=TEST_API_KEY"
        echo "default_model=test-model"
        echo "enabled=true"
        echo "protocol=anthropic"
        echo "max_context_tokens=$1"
    } > "$cfg"

    load_config "$cfg" 2>"$BATS_TEST_TMPDIR/warn"
    get_provider_value "PROVIDER_MAX_CONTEXT_TOKENS" "mct_provider"; mct="$__LLM_REPLY"
}

# ========================================
# Map registration
# ========================================

# The only assertion that pins the LLM_PROVIDER_MAPS edit. set_provider_value
# writes to any map name whether registered or not, so every parsing test below
# passes green even with the map list untouched -- and init_config derives its
# reset from that list, so an unregistered map is never cleared between loads.
@test "max_context_tokens: PROVIDER_MAX_CONTEXT_TOKENS is a registered provider map" {
    [[ " $LLM_PROVIDER_MAPS " == *" PROVIDER_MAX_CONTEXT_TOKENS "* ]]
}

# ========================================
# Accepted forms
# ========================================

@test "max_context_tokens: 1m expands to 1000000" {
    local mct
    _load_with_value "1m"
    [ "$mct" = "1000000" ]
}

@test "max_context_tokens: uppercase 1M expands to 1000000" {
    local mct
    _load_with_value "1M"
    [ "$mct" = "1000000" ]
}

# Decimal, not binary. 200k is 200000, not 204800 -- the k/m suffixes match the
# documented CLAUDE_CODE_AUTO_COMPACT_WINDOW range, whose maximum is exactly
# 1000000. A user who wants a power of two writes the integer out.
@test "max_context_tokens: 200k expands to 200000 decimal, not 204800" {
    local mct
    _load_with_value "200k"
    [ "$mct" = "200000" ]
}

@test "max_context_tokens: uppercase 200K expands to 200000" {
    local mct
    _load_with_value "200K"
    [ "$mct" = "200000" ]
}

@test "max_context_tokens: a bare integer is stored unchanged" {
    local mct
    _load_with_value "262144"
    [ "$mct" = "262144" ]
}

@test "max_context_tokens: 1 is accepted" {
    local mct
    _load_with_value "1"
    [ "$mct" = "1" ]
}

@test "max_context_tokens: 999999999 is accepted at the upper boundary" {
    local mct
    _load_with_value "999999999"
    [ "$mct" = "999999999" ]
}

@test "max_context_tokens: 999999k is accepted at the upper boundary via suffix" {
    local mct
    _load_with_value "999999k"
    [ "$mct" = "999999000" ]
}

@test "max_context_tokens: surrounding whitespace is trimmed" {
    local mct
    _load_with_value "  1m  "
    [ "$mct" = "1000000" ]
}

@test "max_context_tokens: a valid value emits no warning" {
    local mct
    _load_with_value "1m"
    [ ! -s "$BATS_TEST_TMPDIR/warn" ]
}

# ========================================
# Rejected forms
# ========================================
#
# Rejection stores nothing: the value is empty AND the provider never appears
# in the map's key registry. set_provider_value appends to that registry on
# first write regardless of value, so storing "" would permanently register the
# provider and make get_provider_keys report a key that was never configured.

@test "max_context_tokens: a non-numeric value is rejected" {
    local mct
    _load_with_value "abc"
    [ -z "$mct" ]
    ! has_provider_key "PROVIDER_MAX_CONTEXT_TOKENS" "mct_provider"
}

@test "max_context_tokens: a fractional value is rejected" {
    local mct
    _load_with_value "1.5m"
    [ -z "$mct" ]
}

@test "max_context_tokens: a negative value is rejected" {
    local mct
    _load_with_value "-5"
    [ -z "$mct" ]
}

@test "max_context_tokens: a leading plus is rejected" {
    local mct
    _load_with_value "+7"
    [ -z "$mct" ]
}

@test "max_context_tokens: underscore digit grouping is rejected" {
    local mct
    _load_with_value "1_000_000"
    [ -z "$mct" ]
}

@test "max_context_tokens: comma digit grouping is rejected" {
    local mct
    _load_with_value "1,000,000"
    [ -z "$mct" ]
}

@test "max_context_tokens: a space before the suffix is rejected" {
    local mct
    _load_with_value "1 m"
    [ -z "$mct" ]
}

@test "max_context_tokens: exponent notation is rejected" {
    local mct
    _load_with_value "1e6"
    [ -z "$mct" ]
}

@test "max_context_tokens: a doubled suffix is rejected" {
    local mct
    _load_with_value "1mm"
    [ -z "$mct" ]
}

@test "max_context_tokens: a two-letter unit is rejected" {
    local mct
    _load_with_value "1km"
    [ -z "$mct" ]
}

@test "max_context_tokens: an embedded suffix is rejected" {
    local mct
    _load_with_value "12k34"
    [ -z "$mct" ]
}

@test "max_context_tokens: a bare suffix letter is rejected" {
    local mct
    _load_with_value "m"
    [ -z "$mct" ]
    _load_with_value "k"
    [ -z "$mct" ]
}

@test "max_context_tokens: an empty value is rejected" {
    local mct
    _load_with_value ""
    [ -z "$mct" ]
    ! has_provider_key "PROVIDER_MAX_CONTEXT_TOKENS" "mct_provider"
}

@test "max_context_tokens: a whitespace-only value is rejected" {
    local mct
    _load_with_value "   "
    [ -z "$mct" ]
}

# ========================================
# Diagnostics and blast radius
# ========================================

@test "max_context_tokens: a rejected value warns naming the provider and the value" {
    local mct warn
    _load_with_value "abc"
    warn="$(cat "$BATS_TEST_TMPDIR/warn")"
    [[ "$warn" == *"max_context_tokens"* ]]
    [[ "$warn" == *"abc"* ]]
    [[ "$warn" == *"mct_provider"* ]]
}

# A bad value invalidates the key, not the provider. Dropping the whole section
# would take a working endpoint offline over an advisory hint.
@test "max_context_tokens: a rejected value does not prevent the provider loading" {
    local mct base
    _load_with_value "abc"
    get_provider_value "PROVIDER_BASE_URLS" "mct_provider"; base="$__LLM_REPLY"
    [ "$base" = "https://api.test.com/v1" ]
}

@test "max_context_tokens: an absent key leaves the provider out of the map" {
    local cfg="$BATS_TEST_TMPDIR/absent.conf"
    cat > "$cfg" << 'EOF'
[no_mct]
base_url=https://api.test.com/v1
api_key_var=TEST_API_KEY
default_model=test-model
enabled=true
protocol=anthropic
EOF

    load_config "$cfg"

    local mct
    get_provider_value "PROVIDER_MAX_CONTEXT_TOKENS" "no_mct"; mct="$__LLM_REPLY"
    [ -z "$mct" ]
    ! has_provider_key "PROVIDER_MAX_CONTEXT_TOKENS" "no_mct"
}

@test "max_context_tokens: each bad provider warns once" {
    local cfg="$BATS_TEST_TMPDIR/two_bad.conf"
    cat > "$cfg" << 'EOF'
[bad_one]
base_url=https://api.test.com/v1
api_key_var=TEST_API_KEY
default_model=test-model
enabled=true
max_context_tokens=abc

[bad_two]
base_url=https://api.test.com/v1
api_key_var=TEST_API_KEY
default_model=test-model
enabled=true
max_context_tokens=xyz
EOF

    load_config "$cfg" 2>"$BATS_TEST_TMPDIR/warn"

    local count
    count="$(grep -c "max_context_tokens" "$BATS_TEST_TMPDIR/warn")"
    [ "$count" -eq 2 ]
}

@test "max_context_tokens: several providers each keep their own value" {
    local cfg="$BATS_TEST_TMPDIR/many.conf"
    cat > "$cfg" << 'EOF'
[one_m]
base_url=https://api.test.com/v1
api_key_var=TEST_API_KEY
default_model=model-a
enabled=true
protocol=anthropic
max_context_tokens=1m

[two_hundred_k]
base_url=https://api.test.com/v1
api_key_var=TEST_API_KEY
default_model=model-b
enabled=true
protocol=anthropic
max_context_tokens=200k
EOF

    load_config "$cfg"

    local a b
    get_provider_value "PROVIDER_MAX_CONTEXT_TOKENS" "one_m"; a="$__LLM_REPLY"
    get_provider_value "PROVIDER_MAX_CONTEXT_TOKENS" "two_hundred_k"; b="$__LLM_REPLY"
    [ "$a" = "1000000" ]
    [ "$b" = "200000" ]
}

# The value is parsed with `case` globbing, never [[ =~ ]], so BASH_REMATCH and
# zsh's $match survive the call. load_config reads captures through get_match
# while iterating lines; a validator that clobbered them would corrupt whatever
# the parser read next. This config puts a rejected value directly before the
# lines most at risk.
@test "max_context_tokens: a rejected value does not disturb later parsing" {
    local cfg="$BATS_TEST_TMPDIR/rematch.conf"
    cat > "$cfg" << 'EOF'
[first]
max_context_tokens=not-a-number
base_url=https://first.test/v1
api_key_var=FIRST_KEY
default_model=first-model
enabled=true

[second]
base_url=https://second.test/v1
api_key_var=SECOND_KEY
default_model=second-model
enabled=true
EOF

    load_config "$cfg" 2>/dev/null

    local first_base second_base second_model
    get_provider_value "PROVIDER_BASE_URLS" "first"; first_base="$__LLM_REPLY"
    get_provider_value "PROVIDER_BASE_URLS" "second"; second_base="$__LLM_REPLY"
    get_provider_value "PROVIDER_DEFAULT_MODELS" "second"; second_model="$__LLM_REPLY"

    [ "$first_base" = "https://first.test/v1" ]
    [ "$second_base" = "https://second.test/v1" ]
    [ "$second_model" = "second-model" ]
}

# A CRLF config must behave identically to an LF one. load_config strips the
# trailing CR before the key dispatch; if that ever regressed, the value would
# arrive as "200k\r" and be rejected as non-numeric.
@test "max_context_tokens: a CRLF config parses the value" {
    local cfg="$BATS_TEST_TMPDIR/crlf.conf"
    printf '[crlf_provider]\r\nbase_url=https://api.test.com/v1\r\napi_key_var=TEST_API_KEY\r\ndefault_model=test-model\r\nenabled=true\r\nprotocol=anthropic\r\nmax_context_tokens=200k\r\n' > "$cfg"

    load_config "$cfg"

    local mct
    get_provider_value "PROVIDER_MAX_CONTEXT_TOKENS" "crlf_provider"; mct="$__LLM_REPLY"
    [ "$mct" = "200000" ]
}
