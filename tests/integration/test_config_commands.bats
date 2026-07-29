#!/usr/bin/env bats
#
# Config-mutating commands.
#
# There is no dedicated test file for these today; coverage is incidental.
# They are also the commands most able to destroy a user's configuration:
#
#   * cmd_config_remove redirects awk's output INTO the live config while
#     reading from a backup it just made. The shell truncates the target before
#     awk writes a byte, so an awk failure leaves an empty config -- and the
#     single-slot .backup is overwritten on every removal, so a second remove
#     destroys the only copy of the pre-first-removal state.
#   * cmd_config_bulk never checks awk's exit status before mv, so a failed or
#     missing awk replaces the config with an empty file and still reports
#     success. It also checks existence against the IN-MEMORY config, which may
#     have come from a different tier than the file it edits.
#   * mv from a fresh temp file discards the original's permissions, silently
#     turning a chmod 600 config into 644.
#   * cmd_config_restore skipped its confirmation whenever BATS_TMPDIR was set
#     -- a test hook in production code, which bats exports to every child.

load ../lib/bats_helpers

setup() {
    setup_test_env
    SUT="$BATS_TEST_DIRNAME/../../llm-env"
    CFG="$XDG_CONFIG_HOME/llm-env/config.conf"
    create_test_config "[alpha]
base_url=https://alpha.test/v1
api_key_var=LLM_ALPHA_KEY
default_model=alpha-1
description=Alpha provider
enabled=true

[beta]
base_url=https://beta.test/v1
api_key_var=LLM_BETA_KEY
default_model=beta-1
description=Beta provider
enabled=true

[group:pair]
providers=alpha,beta" >/dev/null
}

teardown() {
    teardown_test_env
}

_sut() {
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        LLM_ENV_ASSUME_YES=1 bash -c "source '$SUT' $*"
}

# ---- remove ----

@test "config remove: deletes only the named provider" {
    _sut config remove alpha
    [ "$status" -eq 0 ]
    run grep -c '^\[alpha\]' "$CFG"
    [ "$output" -eq 0 ]
    run grep -c '^\[beta\]' "$CFG"
    [ "$output" -eq 1 ]
}

@test "config remove: leaves the config non-empty and parseable" {
    _sut config remove alpha
    [ -s "$CFG" ]
    _sut list
    [ "$status" -eq 0 ]
    [[ "$output" == *"beta"* ]]
}

@test "config remove: reports failure for a provider that does not exist" {
    # It always printed success, so a typo silently looked like a removal.
    _sut config remove no_such_provider
    [ "$status" -ne 0 ]
    [[ "$output" != *"✅ Removed"* ]]
}

@test "config remove: does not destroy the config when the section is absent" {
    local before; before="$(cat "$CFG")"
    _sut config remove no_such_provider
    local after; after="$(cat "$CFG")"
    [ "$before" = "$after" ]
}

@test "config remove: consecutive removes keep distinct backups" {
    # A single-slot .backup meant the second removal overwrote the only copy
    # of the state before the first.
    _sut config remove alpha
    _sut config remove beta
    local n
    n="$(find "$XDG_CONFIG_HOME/llm-env/backups" -name 'config-*.conf' 2>/dev/null | wc -l | tr -d ' ')"
    [ "${n:-0}" -ge 2 ] || {
        echo "expected >=2 distinct backups, found ${n:-0}:"
        find "$XDG_CONFIG_HOME/llm-env" -type f 2>/dev/null
        return 1
    }
}

@test "config remove: removes a group section too" {
    _sut config remove "group:pair"
    [ "$status" -eq 0 ]
    run grep -c '^\[group:pair\]' "$CFG"
    [ "$output" -eq 0 ]
}

@test "config remove: preserves file permissions" {
    skip_unless_posix_perms
    chmod 600 "$CFG"
    _sut config remove alpha
    local perms
    perms="$(ls -l "$CFG" | cut -c1-10)"
    [ "$perms" = "-rw-------" ]
}

# ---- bulk ----

@test "config bulk: disables the named providers" {
    _sut config bulk disable alpha
    [ "$status" -eq 0 ]
    run grep -A5 '^\[alpha\]' "$CFG"
    [[ "$output" == *"enabled=false"* ]]
}

@test "config bulk: leaves the config intact" {
    _sut config bulk disable alpha
    [ -s "$CFG" ]
    run grep -c '^\[' "$CFG"
    [ "$output" -eq 3 ]
}

@test "config bulk: reports failure for an unknown provider" {
    _sut config bulk disable no_such_provider
    [ "$status" -ne 0 ]
}

@test "config bulk: does not claim success when nothing changed" {
    _sut config bulk disable no_such_provider
    [[ "$output" != *"✅ no_such_provider"* ]]
}

@test "config bulk: preserves file permissions" {
    skip_unless_posix_perms
    chmod 600 "$CFG"
    _sut config bulk disable alpha
    local perms
    perms="$(ls -l "$CFG" | cut -c1-10)"
    [ "$perms" = "-rw-------" ]
}

@test "config bulk: handles an indented enabled= line" {
    printf '\n[gamma]\nbase_url=https://g.test/v1\napi_key_var=K\ndefault_model=m\n  enabled=true\n' >> "$CFG"
    _sut config bulk disable gamma
    run grep -c 'enabled=true' "$CFG"
    # gamma must be disabled without gaining a duplicate enabled= line.
    run grep -A6 '^\[gamma\]' "$CFG"
    [[ "$output" == *"enabled=false"* ]]
    local n
    n="$(grep -A6 '^\[gamma\]' "$CFG" | grep -c 'enabled=' || true)"
    [ "${n:-0}" -eq 1 ]
}

# ---- add ----

@test "config add: rejects a duplicate section" {
    _sut "config add alpha" <<< $'https://x.test/v1\nLLM_X_KEY\nx-1\nX provider\n'
    [ "$status" -ne 0 ]
    local n
    n="$(grep -c '^\[alpha\]' "$CFG")"
    [ "$n" -eq 1 ]
}

# ---- restore ----

@test "config restore: does not bypass confirmation because BATS_TMPDIR is set" {
    # bats exports BATS_TMPDIR to every child, so a production check on it
    # silently disabled the prompt for anyone running under bats -- including
    # developers of this project.
    # Comments explaining the removed hook are not the hook itself.
    run bash -c "grep -vE '^[[:space:]]*#' '$SUT' | grep -n 'BATS_TMPDIR'"
    [ "$status" -ne 0 ]
}

@test "config restore: declines without an explicit confirmation" {
    _sut config backup
    local bk
    bk="$(find "$XDG_CONFIG_HOME/llm-env" -name '*.conf' -path '*backup*' 2>/dev/null | head -1)"
    [ -n "$bk" ] || skip "no backup produced"
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        bash -c "source '$SUT' config restore '$bk' </dev/null"
    [ "$status" -ne 0 ]
}

# ---- backup location ----

@test "config backup: honours XDG_CONFIG_HOME" {
    # The backup dir hardcoded \$HOME/.config while get_user_config_path
    # honours XDG_CONFIG_HOME, so backups were orphaned from their config.
    _sut config backup
    [ "$status" -eq 0 ]
    run find "$XDG_CONFIG_HOME/llm-env" -name '*.conf' -path '*backup*'
    [ -n "$output" ]
}

# ---- atomicity ----

@test "config commands: a failed rewrite never truncates the live config" {
    # Simulate awk being unavailable: the command must fail loudly and leave
    # the original file byte-identical rather than empty.
    local before; before="$(cat "$CFG")"
    local stub="$BATS_TEST_TMPDIR/nobin"
    mkdir -p "$stub"
    printf '#!/bin/sh\nexit 1\n' > "$stub/awk"
    chmod +x "$stub/awk"
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        PATH="$stub:$PATH" LLM_ENV_ASSUME_YES=1 \
        bash -c "source '$SUT' config remove alpha"
    local after; after="$(cat "$CFG")"
    [ "$before" = "$after" ]
}
