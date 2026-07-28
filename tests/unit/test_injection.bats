#!/usr/bin/env bats
#
# Config-driven code execution.
#
# The accessor layer built shell code by string interpolation and ran it
# through eval:
#
#     eval "${array_name}[\"${key}\"]='${value}'"          # set_provider_value
#     eval "__LLM_REPLY=\"\${${array_name}[\"${key}\"]-}\""  # get_provider_value
#
# so a value containing an apostrophe escaped its quoting, and a section name
# containing $(...) was expanded as a command. Both were reproduced live: a
# config line `default_model=m'$(touch /tmp/PWNED)'x` and a section header
# `[a$(touch /tmp/PWNED2)b]` each executed on `source llm-env list` -- before
# any validation ran.
#
# This is reachable as a supply chain: .github/workflows/update-quickstart.yml
# scrapes model ids from live provider APIs daily and squash-merges with no
# human review, and _qs_emit_provider writes upstream_id/description/endpoints
# straight into the user's config.
#
# Every test runs the SUT in a subshell. A payload that succeeds in-process can
# corrupt the bats runner itself into reporting a pass. The canary test in
# test_harness_selftest.bats proves these payloads are genuinely executable, so
# a green run here cannot be an over-escaped fixture.

load ../lib/bats_helpers

setup() {
    setup_test_env
    SUT="$BATS_TEST_DIRNAME/../../llm-env"
}

teardown() {
    teardown_test_env
}

# Run `llm-env list` in a clean subshell against the staged hostile config.
_run_sut_list() {
    local shell_bin="${1:-bash}"
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        "$shell_bin" -c "source '$SUT' list"
}

# ---- values ----

@test "injection: a config value containing an apostrophe does not execute" {
    make_hostile_config value-squote
    _run_sut_list
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
}

@test "injection: a config value containing \$(...) does not execute" {
    make_hostile_config value-cmdsub
    _run_sut_list
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
}

@test "injection: a config value containing backticks does not execute" {
    make_hostile_config value-backtick
    _run_sut_list
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
}

# ---- section names (the accessor key) ----

@test "injection: a section name containing \$(...) does not execute" {
    make_hostile_config section-cmdsub
    _run_sut_list
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
}

@test "injection: a section name containing backticks does not execute" {
    make_hostile_config section-backtick
    _run_sut_list
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
}

@test "injection: a section name containing \${...} does not expand" {
    make_hostile_config section-brace
    _run_sut_list
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
}

@test "injection: a group name containing \$(...) does not execute" {
    make_hostile_config group-cmdsub
    _run_sut_list
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
}

# ---- rejection must be loud, and must not take the whole config down ----

@test "injection: an unsafe section name is reported, not silently dropped" {
    make_hostile_config section-cmdsub
    _run_sut_list
    [[ "$output" == *"nvalid"* ]] || [[ "$output" == *"kipping"* ]]
}

@test "injection: a hostile section does not prevent valid providers loading" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    local sentinel; sentinel="$(new_sentinel mixed)"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" <<EOF
[good]
base_url=https://good.test/v1
api_key_var=LLM_GOOD_KEY
default_model=good-1
enabled=true

[bad\$(printf pwned > '$sentinel')]
base_url=https://bad.test/v1
api_key_var=LLM_BAD_KEY
default_model=bad-1
enabled=true
EOF
    _run_sut_list
    assert_sentinel_absent "$sentinel"
    [ "$status" -eq 0 ]
    [[ "$output" == *"good"* ]]
}

# ---- cross-shell: the eval bug had a separate zsh branch ----

@test "injection: values do not execute under zsh" {
    skip_unless_command zsh
    make_hostile_config value-cmdsub
    _run_sut_list zsh
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
}

@test "injection: section names do not execute under zsh" {
    skip_unless_command zsh
    make_hostile_config section-cmdsub
    _run_sut_list zsh
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
}

@test "injection: values do not execute under bash 3.2" {
    skip_unless_real_bash 3.2
    make_hostile_config value-cmdsub
    _run_sut_list /bin/bash
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
}

@test "injection: section names do not execute under bash 3.2" {
    skip_unless_real_bash 3.2
    make_hostile_config section-cmdsub
    _run_sut_list /bin/bash
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
}

# ---- fidelity: hardening must not corrupt legitimate values ----

@test "injection: a legitimate value with an ampersand survives intact" {
    # sanitize_config_value used to strip & $ ; | from values, corrupting real
    # URLs -- including this project's own Alibaba signup URL.
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" <<'EOF'
[acme]
base_url=https://api.acme.test/v1?a=1&b=2
api_key_var=LLM_ACME_KEY
default_model=acme-1
enabled=true
EOF
    run bash -c "
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' LLM_ACME_KEY=sk-1
        source '$SUT' set acme >/dev/null 2>&1
        printf '%s' \"\$OPENAI_BASE_URL\"
    "
    [ "$output" = "https://api.acme.test/v1?a=1&b=2" ]
}

@test "injection: a dotted provider id round-trips (kimi-k2.5 style)" {
    # Dots and hyphens are required by quickstart schema v2 model ids, so the
    # key validator must allow them and any name mangling must be reversible.
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" <<'EOF'
[openai_synth_kimi-k2.5]
base_url=https://api.synthetic.test/openai/v1
api_key_var=LLM_SYNTH_KEY
default_model=hf:moonshotai/Kimi-K2.5
enabled=true
EOF
    _run_sut_list
    [ "$status" -eq 0 ]
    [[ "$output" == *"openai_synth_kimi-k2.5"* ]]
}

@test "injection: keys differing only by - vs _ do not collide" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    cat > "$XDG_CONFIG_HOME/llm-env/config.conf" <<'EOF'
[a-b]
base_url=https://dash.test/v1
api_key_var=K1
default_model=m1
enabled=true

[a_b]
base_url=https://under.test/v1
api_key_var=K2
default_model=m2
enabled=true
EOF
    _run_sut_list
    [ "$status" -eq 0 ]
    [[ "$output" == *"dash.test"* ]]
    [[ "$output" == *"under.test"* ]]
}

# ---- structural guard ----

@test "injection: every eval in the provider store is a fixed literal" {
    # A behavioral test can only prove the payloads we thought of are inert.
    # This proves the class is unreachable by construction.
    #
    # The store is not eval-free: zsh's ${(P)name} indirect expansion is a
    # syntax error to bash's parser even inside a branch bash never executes,
    # so it has to be hidden behind eval for the file to parse at all. What
    # matters is that the eval argument is a single-quoted literal containing
    # no interpolation -- the operand comes from $1 at expansion time, not from
    # string concatenation.
    local region
    region="$(awk '/^# ---------- Provider store/,/^# ---------- Configuration Loading/' \
        "$BATS_TEST_DIRNAME/../../llm-env")"
    [ -n "$region" ]

    local line trimmed offenders=""
    while IFS= read -r line; do
        # Comments are prose about eval, not code.
        trimmed="${line#"${line%%[![:space:]]*}"}"
        case "$trimmed" in
            '#'*) continue ;;
        esac
        case "$line" in
            *eval*) ;;
            *) continue ;;
        esac
        # Permitted form only: eval '...single-quoted literal...'
        case "$line" in
            *"eval '"*) continue ;;
        esac
        offenders="$offenders$line"$'\n'
    done <<< "$region"

    if [ -n "$offenders" ]; then
        echo "eval with a non-literal argument in the provider store:"
        printf '%s' "$offenders"
        return 1
    fi
}

@test "injection: no eval in the store interpolates a variable" {
    local region
    region="$(awk '/^# ---------- Provider store/,/^# ---------- Configuration Loading/' \
        "$BATS_TEST_DIRNAME/../../llm-env")"
    # Any eval line carrying a double quote or a bare $ outside single quotes
    # would mean data is being concatenated into code.
    run grep -nE 'eval[^'\'']*"' <<< "$region"
    [ "$status" -ne 0 ]
}

@test "injection: no eval anywhere interpolates a config-derived name" {
    run grep -nE 'eval .*\$\{?(key|value|section_name|current_provider|current_group|provider)\b' \
        "$BATS_TEST_DIRNAME/../../llm-env"
    [ "$status" -ne 0 ]
}
