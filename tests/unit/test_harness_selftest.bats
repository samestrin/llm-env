#!/usr/bin/env bats
#
# Self-tests for tests/lib/bats_helpers.sh.
#
# The helper library is itself untested and unlinted today, yet all 250 tests
# depend on it. These tests pin the properties that make the rest of the suite
# trustworthy:
#
#   * it must run on every shell the product supports (bash 3.2 is macOS's
#     system bash and a first-class target), and
#   * it must not degrade silently when an optional external tool is absent,
#     because a silently-degraded helper turns a real failure into a pass.

setup() {
    HELPERS="$BATS_TEST_DIRNAME/../lib/bats_helpers.sh"
    SUT="$BATS_TEST_DIRNAME/../../llm-env"
    # Load for the in-process tests. Deliberately does NOT call setup_test_env:
    # these tests exercise the helper library itself, so they must not depend on
    # the very setup path they are validating.
    source "$HELPERS"
}

# ---- bash 3.2 compatibility of the helper library itself ----

@test "helpers: library sources cleanly under real bash 3.2" {
    if [[ ! -x /bin/bash ]] || ! /bin/bash --version | head -1 | grep -q 'version 3\.2'; then
        skip "no real bash 3.2 at /bin/bash"
    fi
    run /bin/bash -c "source '$HELPERS' && echo SOURCED_OK"
    [ "$status" -eq 0 ]
    [[ "$output" == *"SOURCED_OK"* ]]
    # `local -n` is bash 4.3+; on 3.2 it aborts with "local: -n: invalid option".
    [[ "$output" != *"invalid option"* ]]
}

@test "helpers: get_compat_value works under real bash 3.2" {
    if [[ ! -x /bin/bash ]] || ! /bin/bash --version | head -1 | grep -q 'version 3\.2'; then
        skip "no real bash 3.2 at /bin/bash"
    fi
    run /bin/bash -c "
        source '$HELPERS'
        K=(alpha beta gamma); V=(one two three)
        get_compat_value K V beta
    "
    [ "$status" -eq 0 ]
    [ "$output" = "two" ]
}

@test "helpers: get_compat_value returns nonzero for a missing key" {
    K=(alpha beta); V=(one two)
    run get_compat_value K V nope
    [ "$status" -ne 0 ]
}

# ---- no silent degradation on missing optional tools ----

@test "helpers: get_system_load_factor works without bc or free on PATH" {
    # Git Bash ships neither bc nor free; macOS ships no free. A helper that
    # silently returns a wrong factor makes perf-test failures unreproducible.
    # Build a PATH that has the ordinary tools but genuinely lacks bc and free.
    local stub="$BATS_TEST_TMPDIR/nobin"
    mkdir -p "$stub"
    local t
    for t in bash sh awk sed uptime printf grep cat; do
        command -v "$t" >/dev/null 2>&1 && ln -sf "$(command -v "$t")" "$stub/$t"
    done
    run env PATH="$stub" CI=1 "$stub/bash" -c "source '$HELPERS'; get_system_load_factor"
    [ "$status" -eq 0 ]
    # Must be a bare integer, not empty and not a float or an error string.
    [[ "$output" =~ ^[0-9]+$ ]]
    [ "$output" -ge 100 ]
}

@test "helpers: calculate_dynamic_timeout never returns below its base" {
    run calculate_dynamic_timeout 2500
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+$ ]]
    [ "$output" -ge 2500 ]
}

# ---- portable millisecond clock ----

@test "helpers: now_ms returns a plausible integer millisecond timestamp" {
    run now_ms
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+$ ]]
    # Sanity: after 2020-01-01 (1577836800000 ms) and before year 2100.
    [ "$output" -gt 1577836800000 ]
    [ "$output" -lt 4102444800000 ]
}

@test "helpers: now_ms is monotonic across calls" {
    local a b
    a="$(now_ms)"
    b="$(now_ms)"
    [ "$b" -ge "$a" ]
}

@test "helpers: now_ms works without GNU date %N" {
    # BSD date (macOS <= 13) prints a literal "N" for %N; a helper that does
    # arithmetic on that produces garbage rather than failing loudly.
    local stub="$BATS_TEST_TMPDIR/bsddate"
    mkdir -p "$stub"
    cat > "$stub/date" <<'STUB'
#!/bin/sh
case "$1" in
    +%s%N) echo "1785000000N" ;;
    +%s)   echo "1785000000" ;;
    *)     echo "1785000000" ;;
esac
STUB
    chmod +x "$stub/date"
    run env PATH="$stub:$PATH" bash -c "source '$HELPERS'; now_ms"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+$ ]]
    [[ "$output" != *"N"* ]]
}

# ---- real-HOME protection ----

@test "helpers: snapshot_real_home records the developer's real rc files" {
    snapshot_real_home
    [ -n "${LLM_ENV_REAL_HOME_SNAPSHOT:-}" ]
    run assert_no_real_home_writes
    [ "$status" -eq 0 ]
}

# ---- cross-shell execution harness ----
#
# bats is #!/usr/bin/env bash and never consults $SHELL (verified: no SHELL
# reference anywhere in tests/bats/libexec/). The CI "shell: [bash, zsh]"
# matrix therefore runs a byte-identical bash suite twice. Real zsh and real
# bash-3.2 coverage requires explicitly spawning those interpreters.

@test "harness: run_in_shell executes the SUT under real zsh" {
    skip_unless_command zsh
    run_in_shell zsh "$SUT" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"LLM Environment Manager"* ]]
}

@test "harness: run_in_shell executes the SUT under real bash 3.2" {
    skip_unless_real_bash 3.2
    run_in_shell /bin/bash "$SUT" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"LLM Environment Manager"* ]]
}

@test "harness: run_in_shell surfaces a nonzero exit from the SUT" {
    run_in_shell bash "$SUT" definitely-not-a-command
    [ "$status" -ne 0 ]
}

@test "harness: skip_unless_command skips for a nonexistent binary" {
    # Runs in a subshell so the skip does not abort this test.
    run bash -c "source '$HELPERS'; skip() { echo \"SKIPPED: \$1\"; exit 0; }; \
                 skip_unless_command definitely-not-installed-xyz; echo NOT_SKIPPED"
    [[ "$output" == *"SKIPPED"* ]]
    [[ "$output" != *"NOT_SKIPPED"* ]]
}

# ---- injection sentinels ----

@test "harness: new_sentinel returns a path that does not yet exist" {
    local s; s="$(new_sentinel demo)"
    [ -n "$s" ]
    [ ! -e "$s" ]
    run assert_sentinel_absent "$s"
    [ "$status" -eq 0 ]
}

@test "harness: assert_sentinel_absent fails once the sentinel is created" {
    local s; s="$(new_sentinel demo2)"
    printf 'pwned' > "$s"
    run assert_sentinel_absent "$s"
    [ "$status" -ne 0 ]
}

@test "harness canary: the injection payload is genuinely executable" {
    # If this ever fails, every injection regression test is vacuous -- the
    # payload got escaped somewhere in the fixture pipeline and proves nothing.
    # This reproduces the exact shape of the pre-fix accessor eval.
    local s; s="$(new_sentinel canary)"
    local payload
    payload="\$(printf pwned > '$s')"
    # shellcheck disable=SC2034
    declare -A CANARY_MAP
    eval "x=\"\${CANARY_MAP[\"${payload}\"]-}\"" 2>/dev/null || true
    assert_sentinel_present "$s"
}

# ---- config fixture builders ----

@test "harness: write_config_with_eol crlf produces CRLF terminators" {
    local cfg
    cfg="$(write_config_with_eol crlf "[acme]
base_url=https://a.test/v1")"
    [ -f "$cfg" ]
    # Every line must end CR LF, and there must be at least one CR.
    run grep -c $'\r$' "$cfg"
    [ "$output" -ge 2 ]
}

@test "harness: write_config_with_eol lf produces no CR at all" {
    local cfg
    cfg="$(write_config_with_eol lf "[acme]
base_url=https://a.test/v1")"
    # Assert the file exists first: grep on a missing file also returns
    # nonzero, which would make this assertion pass vacuously.
    [ -f "$cfg" ]
    [ -s "$cfg" ]
    run grep -c $'\r' "$cfg"
    [ "$status" -ne 0 ]
}

@test "harness: make_hostile_config emits a config and exports its sentinel" {
    # Must NOT be called in a command substitution: the subshell would discard
    # the sentinel path. It returns via globals for exactly that reason.
    make_hostile_config value-cmdsub
    [ -n "${LLM_ENV_TEST_CONFIG:-}" ]
    [ -f "$LLM_ENV_TEST_CONFIG" ]
    [ -n "${LLM_ENV_TEST_SENTINEL:-}" ]
    [ ! -e "$LLM_ENV_TEST_SENTINEL" ]
    grep -q '^\[' "$LLM_ENV_TEST_CONFIG"
    # The payload must actually be present in the fixture, otherwise every
    # injection test built on it proves nothing.
    grep -q 'printf pwned' "$LLM_ENV_TEST_CONFIG"
}

@test "harness: every make_hostile_config vector writes a payload-bearing config" {
    local v
    for v in value-squote value-cmdsub value-backtick section-cmdsub \
             section-backtick section-brace group-cmdsub; do
        make_hostile_config "$v"
        [ -f "$LLM_ENV_TEST_CONFIG" ] || { echo "vector $v produced no file"; return 1; }
        [ -s "$LLM_ENV_TEST_CONFIG" ] || { echo "vector $v produced an empty file"; return 1; }
        [ ! -e "$LLM_ENV_TEST_SENTINEL" ] || { echo "vector $v pre-created its sentinel"; return 1; }
    done
}

# ---- environment capture ----

@test "harness: dump_env_after distinguishes unset from empty" {
    # dump_env_after already populates $status/$output like `run`; wrapping it
    # in another `run` would let the inner one swallow the output.
    dump_env_after "export SET_AND_EMPTY=''; unset NEVER_SET_VAR" \
        SET_AND_EMPTY NEVER_SET_VAR
    [ "$status" -eq 0 ]
    [[ "$output" == *"SET_AND_EMPTY="* ]]
    [[ "$output" != *"SET_AND_EMPTY=<unset>"* ]]
    [[ "$output" == *"NEVER_SET_VAR=<unset>"* ]]
}

@test "harness: assert_env_unset and assert_env_is read the dump" {
    dump_env_after "export DEMO_VAR=hello; unset OTHER_VAR" DEMO_VAR OTHER_VAR
    assert_env_is DEMO_VAR hello
    assert_env_unset OTHER_VAR
}

@test "helpers: assert_no_real_home_writes detects a modified rc file" {
    # Point the snapshot at a scratch "home" so we never touch the real one.
    local fake="$BATS_TEST_TMPDIR/fakehome"
    mkdir -p "$fake"
    printf 'original\n' > "$fake/.bashrc"

    LLM_ENV_REAL_HOME_OVERRIDE="$fake" snapshot_real_home
    printf 'tampered\n' >> "$fake/.bashrc"
    run env LLM_ENV_REAL_HOME_OVERRIDE="$fake" bash -c "
        source '$HELPERS'
        LLM_ENV_REAL_HOME_SNAPSHOT='$LLM_ENV_REAL_HOME_SNAPSHOT'
        assert_no_real_home_writes
    "
    [ "$status" -ne 0 ]
}
