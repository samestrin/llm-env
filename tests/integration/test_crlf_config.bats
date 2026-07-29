#!/usr/bin/env bats
#
# CRLF tolerance in the config parser.
#
# load_config matches section headers with `^\[([^]]+)\]$`. A trailing CR sits
# between the `]` and end-of-line, defeating the `$` anchor, so no section ever
# matches -- yet load_config still returns 0 and init_config still reports
# CONFIG_SOURCE="user". The result is a config that silently loads ZERO
# providers with no diagnostic, which is the worst possible failure mode.
#
# This matters beyond a CRLF checkout: Git for Windows defaults to
# core.autocrlf=true, but a Windows user editing the config in Notepad
# produces CRLF regardless of what .gitattributes says. The runtime fix has to
# stand on its own.

load ../lib/bats_helpers

setup() {
    setup_test_env
    SUT="$BATS_TEST_DIRNAME/../../llm-env"
    CFG_BODY="[acme]
base_url=https://api.acme.test/v1
api_key_var=LLM_ACME_KEY
default_model=acme-large
description=Acme test provider
enabled=true

[beta]
base_url=https://api.beta.test/v1
api_key_var=LLM_BETA_KEY
default_model=beta-small
enabled=true"
}

teardown() {
    teardown_test_env
}

# ---- the core defect ----

@test "crlf: a CRLF config loads its providers" {
    write_config_with_eol crlf "$CFG_BODY" >/dev/null
    run_in_shell bash "$SUT" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"acme"* ]]
    [[ "$output" == *"beta"* ]]
}

@test "crlf: a CRLF config yields the same provider set as LF" {
    write_config_with_eol lf "$CFG_BODY" >/dev/null
    run_in_shell bash "$SUT" list
    local lf_out="$output"

    write_config_with_eol crlf "$CFG_BODY" >/dev/null
    run_in_shell bash "$SUT" list
    local crlf_out="$output"

    [ "$lf_out" = "$crlf_out" ]
}

@test "crlf: values carry no trailing carriage return into the environment" {
    write_config_with_eol crlf "$CFG_BODY" >/dev/null
    run bash -c "
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' LLM_ACME_KEY=sk-test-123
        source '$SUT' set acme >/dev/null 2>&1
        printf '[%s]' \"\$OPENAI_BASE_URL\"
    "
    [ "$status" -eq 0 ]
    # A surviving CR would render as "[...v1\r]" and break URL comparisons.
    [ "$output" = "[https://api.acme.test/v1]" ]
}

@test "crlf: a lone-CR (classic Mac) config loads its providers" {
    write_config_with_eol cr "$CFG_BODY" >/dev/null
    run_in_shell bash "$SUT" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"acme"* ]]
}

@test "crlf: a mixed LF/CRLF config loads every provider" {
    write_config_with_eol mixed "$CFG_BODY" >/dev/null
    run_in_shell bash "$SUT" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"acme"* ]]
    [[ "$output" == *"beta"* ]]
}

# ---- fail loudly, not silently ----

@test "crlf: a non-empty config that yields zero sections warns" {
    # Regardless of the CRLF fix, a config that parses to nothing must say so
    # rather than presenting an empty provider list as success.
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    printf 'this is not ini at all\njust prose\n' > "$XDG_CONFIG_HOME/llm-env/config.conf"
    run_in_shell bash "$SUT" list
    [[ "$output" == *"no provider sections"* ]] || [[ "$output" == *"No provider sections"* ]]
}

@test "crlf: an empty config file does not trigger the zero-section warning" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    : > "$XDG_CONFIG_HOME/llm-env/config.conf"
    run_in_shell bash "$SUT" list
    [[ "$output" != *"no provider sections"* ]]
    [[ "$output" != *"No provider sections"* ]]
}

@test "crlf: a comment-only config does not trigger the zero-section warning" {
    mkdir -p "$XDG_CONFIG_HOME/llm-env"
    printf '# just a comment\n\n# another\n' > "$XDG_CONFIG_HOME/llm-env/config.conf"
    run_in_shell bash "$SUT" list
    [[ "$output" != *"no provider sections"* ]]
    [[ "$output" != *"No provider sections"* ]]
}

# ---- cross-shell ----

@test "crlf: a CRLF config loads under zsh" {
    skip_unless_command zsh
    write_config_with_eol crlf "$CFG_BODY" >/dev/null
    run_in_shell zsh "$SUT" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"acme"* ]]
}

@test "crlf: a CRLF config loads under bash 3.2" {
    skip_unless_real_bash 3.2
    write_config_with_eol crlf "$CFG_BODY" >/dev/null
    run_in_shell /bin/bash "$SUT" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"acme"* ]]
}

# ---- repository hygiene ----

@test "crlf: .gitattributes pins LF for every shell-parsed file type" {
    local ga="$BATS_TEST_DIRNAME/../../.gitattributes"
    [ -f "$ga" ]
    # Without eol=lf, `text=auto` still honours Git for Windows' default
    # core.autocrlf=true on checkout, and `source llm-env` dies on line 20.
    grep -q 'eol=lf' "$ga"
}

@test "crlf: no tracked shell-parsed file contains a carriage return" {
    cd "$BATS_TEST_DIRNAME/../.." || return 1
    local f bad=""
    while IFS= read -r f; do
        [ -f "$f" ] || continue
        if grep -qU $'\r' "$f" 2>/dev/null; then
            bad="$bad $f"
        fi
    done < <(git ls-files 'llm-env' '*.sh' '*.bats' '*.conf' '*.json' 2>/dev/null)
    [ -z "$bad" ] || { echo "CR found in:$bad"; return 1; }
}
