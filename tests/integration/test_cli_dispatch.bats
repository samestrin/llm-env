#!/usr/bin/env bats
#
# Command dispatch and control flow.
#
# Four independent defects, all of which make llm-env quietly do the wrong
# thing rather than fail:
#
#   * `if ! validate_provider ...; then case $?` -- inside `if !`, $? is the
#     status of the negated pipeline, which is always 0. The "Unknown provider"
#     and "Provider disabled" messages could never print.
#   * `list) cmd_list "$@"` with no `shift`, so cmd_list's $1 is the literal
#     string "list" and `--all` was silently ignored. Disabled providers were
#     unreachable from the CLI entirely.
#   * `((x++))` evaluates to the pre-increment value, so it returns 1 when x is
#     0. Under a caller's `set -e` that aborts the sourced script -- and skips
#     the `set -u` restore at the bottom of the file.
#   * set_multiple_providers exports LLM_PROVIDER when count > 1 rather than
#     when failed == 0, so a group whose providers all failed still reported a
#     provider as active.

load ../lib/bats_helpers

setup() {
    setup_test_env
    SUT="$BATS_TEST_DIRNAME/../../llm-env"
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
description=Beta provider (disabled)
enabled=false

[group:pair]
providers=alpha,beta" >/dev/null
}

teardown() {
    teardown_test_env
}

_sut() {
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        bash -c "source '$SUT' $*"
}

# ---- C1: the error messages that could never print ----

@test "dispatch: an unknown provider is named in the error" {
    _sut set no_such_provider
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown provider"* ]]
    [[ "$output" == *"no_such_provider"* ]]
}

@test "dispatch: a disabled provider is reported as disabled, not unknown" {
    _sut set beta
    [ "$status" -ne 0 ]
    [[ "$output" == *"disabled"* ]]
    [[ "$output" != *"Unknown provider"* ]]
}

# ---- C2: list --all ----

# Only the provider table is relevant to enabled/disabled filtering: the
# "Provider groups:" section legitimately names every member of a group,
# including disabled ones, so a whole-output grep would be misleading.
_provider_table() {
    printf '%s\n' "$output" | sed -n '1,/^Provider groups:/p'
}

@test "dispatch: plain list hides disabled providers" {
    _sut list
    [ "$status" -eq 0 ]
    local table; table="$(_provider_table)"
    [[ "$table" == *"alpha"* ]]
    [[ "$table" != *"beta-1"* ]]
}

@test "dispatch: list --all shows disabled providers" {
    _sut list --all
    [ "$status" -eq 0 ]
    local table; table="$(_provider_table)"
    [[ "$table" == *"alpha"* ]]
    [[ "$table" == *"beta-1"* ]]
}

# ---- C4: errexit safety ----

@test "dispatch: sourcing under set -e survives counters starting at zero" {
    run bash -c "
        set -e
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' HOME='$HOME'
        source '$SUT' list >/dev/null
        echo REACHED_END
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"REACHED_END"* ]]
}

@test "dispatch: config validate under set -e survives an invalid config" {
    create_test_config "[broken]
base_url=not-a-url
enabled=true" >/dev/null
    run bash -c "
        set -e
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' HOME='$HOME'
        source '$SUT' config validate >/dev/null 2>&1 || true
        echo REACHED_END
    "
    [[ "$output" == *"REACHED_END"* ]]
}

@test "dispatch: set -e does not skip the nounset restore" {
    # A mid-script abort under errexit would skip the `set -u` restoration at
    # the bottom of the file, silently changing the caller's shell options.
    run bash -c "
        set -eu
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' HOME='$HOME'
        source '$SUT' list >/dev/null 2>&1 || true
        case \$- in *u*) echo NOUNSET_RESTORED ;; *) echo NOUNSET_LOST ;; esac
    "
    [[ "$output" == *"NOUNSET_RESTORED"* ]]
}

# ---- H2: group set must not claim success when everything failed ----

@test "dispatch: a group whose providers all lack keys does not export LLM_PROVIDER" {
    run bash -c "
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' HOME='$HOME'
        unset LLM_ALPHA_KEY LLM_BETA_KEY
        source '$SUT' set pair >/dev/null 2>&1
        printf 'LLM_PROVIDER=[%s]' \"\${LLM_PROVIDER:-}\"
    "
    [ "$output" = "LLM_PROVIDER=[]" ]
}

@test "dispatch: a group set reports failure when no provider could be set" {
    run bash -c "
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' HOME='$HOME'
        unset LLM_ALPHA_KEY LLM_BETA_KEY
        source '$SUT' set pair >/dev/null 2>&1
    "
    [ "$status" -ne 0 ]
}

# ---- dispatch hygiene ----

@test "dispatch: an unknown subcommand exits nonzero and says so" {
    _sut definitely-not-a-command
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown command"* ]]
}

@test "dispatch: --version reports the version" {
    _sut --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}
