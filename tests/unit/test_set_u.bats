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

@test "strict mode: sourcing survives set -euo pipefail with IFS=\$'\\n\\t'" {
    # The widely-used "bash strict mode" idiom. Its IFS has no space, and
    # __llm_split inherited it -- so every space-separated internal list
    # collapsed to one pseudo-word: init_config cleared nothing and
    # _clear_protocol_env unset nothing. Under set -e it aborted outright.
    # Found by the cumulative adversarial review, not by the suite.
    local cfg_dir="$BATS_TEST_TMPDIR/strict/.config"
    mkdir -p "$cfg_dir/llm-env"
    cat > "$cfg_dir/llm-env/config.conf" <<'EOF'
[alpha]
base_url=https://alpha.test/v1
api_key_var=LLM_ALPHA_KEY
default_model=alpha-1
enabled=true
EOF
    run env HOME="$BATS_TEST_TMPDIR/strict" XDG_CONFIG_HOME="$cfg_dir" \
        /bin/bash -c '
            set -euo pipefail
            IFS=$'"'"'\n\t'"'"'
            source '"$BATS_TEST_DIRNAME"'/../../llm-env list >/dev/null 2>&1
            echo REACHED_END
        '
    [ "$status" -eq 0 ]
    [[ "$output" == *"REACHED_END"* ]]
}

@test "strict mode: __llm_split splits on spaces regardless of the caller's IFS" {
    run env /bin/bash -c "
        IFS=\$'\\n\\t'
        source '$BATS_TEST_DIRNAME/../../llm-env' >/dev/null 2>&1
        __llm_split 'A B C'
        printf '%s' \"\${#__LLM_WORDS[@]}\"
    "
    [ "$output" = "3" ]
}

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

@test "set -u: source + set <provider> does not abort (compat)" {
    run /bin/bash -c "
        set -u
        export BASH_ASSOC_ARRAY_SUPPORT='false'
        export XDG_CONFIG_HOME='$TEST_CFG_DIR/.config'
        export LLM_ALPHA_KEY='secret-key'
        source '$BATS_TEST_DIRNAME/../../llm-env' set alpha
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "alpha" ]]
}

@test "set -u: source + unset does not abort (compat)" {
    run_setu false unset
    [ "$status" -eq 0 ]
}

@test "set -u: caller's nounset is restored after sourcing" {
    run /bin/bash -c "
        set -u
        export BASH_ASSOC_ARRAY_SUPPORT='false'
        export XDG_CONFIG_HOME='$TEST_CFG_DIR/.config'
        source '$BATS_TEST_DIRNAME/../../llm-env' list >/dev/null 2>&1
        case \$- in *u*) echo NOUNSET_ON ;; *) echo NOUNSET_OFF ;; esac
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "NOUNSET_ON" ]]
}
