#!/usr/bin/env bats
#
# set -u (nounset) safety.
#
# llm-env is sourced into the user's interactive shell, so a user with
# `set -u` in their profile inherits it. On bash < 4.4 (notably the macOS
# system bash 3.2), expanding an empty array as "${arr[@]}" raises
# "unbound variable" and aborts. These tests source llm-env under `set -u`
# with the system bash and assert it does not abort. On bash >= 4.4 the
# empty-array expansion is already safe, so the test passes trivially there.

setup() {
    export LLM_ENV_DEBUG=0
    # Config with providers but no groups (PROVIDER_GROUPS empty -> the common
    # empty-array case), plus a second run below covers the no-providers case.
    TEST_CFG_DIR="$BATS_TMPDIR/llm-env-setu-$$"
    mkdir -p "$TEST_CFG_DIR/.config/llm-env"
    cat > "$TEST_CFG_DIR/.config/llm-env/config.conf" << 'EOF'
[alpha]
base_url=https://api.alpha.test/v1
api_key_var=LLM_ALPHA_KEY
default_model=alpha-1
enabled=true
EOF
}

teardown() {
    rm -rf "$TEST_CFG_DIR"
}

# Helper: source llm-env under `set -u` with the system bash and a command.
run_setu() {
    local mode="$1" cmd="$2"
    run /bin/bash -c "
        set -u
        export BASH_ASSOC_ARRAY_SUPPORT='$mode'
        export XDG_CONFIG_HOME='$TEST_CFG_DIR/.config'
        source '$BATS_TEST_DIRNAME/../../llm-env' $cmd
    "
}

@test "set -u: source + list does not abort (compat, providers no groups)" {
    run_setu false list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "alpha" ]]
}

@test "set -u: source + show does not abort (compat)" {
    run_setu false show
    [ "$status" -eq 0 ]
}

@test "set -u: source + config validate does not abort (compat)" {
    run_setu false "config validate"
    [ "$status" -eq 0 ]
}

@test "set -u: source + list --all does not abort (compat)" {
    run_setu false "list --all"
    [ "$status" -eq 0 ]
}

@test "set -u: empty config (no providers) does not abort (compat)" {
    : > "$TEST_CFG_DIR/.config/llm-env/config.conf"
    run_setu false list
    [ "$status" -eq 0 ]
}

@test "set -u: source + list does not abort (native path)" {
    run_setu true list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "alpha" ]]
}
