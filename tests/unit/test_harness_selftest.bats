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
