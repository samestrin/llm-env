#!/usr/bin/env bats
#
# cmd_test transport, secret masking, and terminal hyperlinks.
#
#   * The API key was passed as a curl -H argument, so it appeared in argv and
#     was readable via ps / /proc on a shared host.
#   * curl -w '%{http_code}' emits "000" on a DNS or connect failure, so the
#     empty-response arm was unreachable: an unreachable host reported
#     "Unexpected response, HTTP 000" and exited 0. The wget path returns an
#     empty string instead, so the two backends disagreed.
#   * Timing used `date +%s.%N` (GNU-only; a literal "N" on BSD date) piped to
#     bc (absent on Git Bash), so response times degraded to "N/As".
#   * mask() revealed 3 of 4 characters of a short secret.
#   * link() emitted OSC 8 escapes unconditionally, despite a docstring
#     promising a plain-text fallback. Every caller wraps it in $(...), where
#     stdout is a pipe, so the escapes were baked into strings regardless of
#     whether a terminal was attached -- they landed in pipes, files and CI
#     logs verbatim.
#
# The transport tests stub curl on PATH: the suite previously made ~15 real
# network calls per run, which is slow, flaky, and impossible on a runner
# without egress.

load ../lib/bats_helpers

setup() {
    setup_test_env
    SUT="$BATS_TEST_DIRNAME/../../llm-env"
    STUB="$BATS_TEST_TMPDIR/stub"
    mkdir -p "$STUB"
    create_test_config "[oai]
base_url=https://oai.test/v1
api_key_var=LLM_OAI_KEY
default_model=oai-1
protocol=openai
enabled=true

[anth]
base_url=https://anth.test
api_key_var=LLM_ANTH_KEY
default_model=anth-1
protocol=anthropic
enabled=true" >/dev/null
}

teardown() {
    teardown_test_env
}

# Install a fake curl that echoes the given HTTP code and records its argv.
_stub_curl() {
    cat > "$STUB/curl" <<STUBEOF
#!/bin/sh
printf '%s\n' "\$@" > "$BATS_TEST_TMPDIR/curl.argv"
cat > "$BATS_TEST_TMPDIR/curl.stdin" 2>/dev/null || true
printf '%s' "$1"
STUBEOF
    chmod +x "$STUB/curl"
}

_run_test_cmd() {
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        PATH="$STUB:$PATH" LLM_OAI_KEY=sk-secret-argv-canary LLM_ANTH_KEY=sk-anth-canary \
        bash -c "source '$SUT' test ${1:-oai}"
}

# ---- the key must not be visible in argv ----

@test "cmd_test: the API key never appears in curl's argv" {
    _stub_curl 200
    _run_test_cmd oai
    [ -f "$BATS_TEST_TMPDIR/curl.argv" ]
    run grep -c 'sk-secret-argv-canary' "$BATS_TEST_TMPDIR/curl.argv"
    [ "$output" -eq 0 ] || {
        echo "API key found in curl argv (visible via ps):"
        cat "$BATS_TEST_TMPDIR/curl.argv"
        return 1
    }
}

@test "cmd_test: the anthropic key never appears in curl's argv" {
    _stub_curl 200
    _run_test_cmd anth
    run grep -c 'sk-anth-canary' "$BATS_TEST_TMPDIR/curl.argv"
    [ "$output" -eq 0 ]
}

# ---- response handling ----

@test "cmd_test: HTTP 000 is reported as a connection failure, not success" {
    _stub_curl 000
    _run_test_cmd oai
    [ "$status" -ne 0 ]
    [[ "$output" == *"onnect"* || "$output" == *"network"* || "$output" == *"reach"* ]]
    [[ "$output" != *"Unexpected response"* ]]
}

@test "cmd_test: an empty response is reported as a connection failure" {
    _stub_curl ""
    _run_test_cmd oai
    [ "$status" -ne 0 ]
}

@test "cmd_test: HTTP 200 succeeds" {
    _stub_curl 200
    _run_test_cmd oai
    [ "$status" -eq 0 ]
    [[ "$output" == *"Connected successfully"* ]]
}

@test "cmd_test: HTTP 401 reports authentication failure" {
    _stub_curl 401
    _run_test_cmd oai
    [ "$status" -ne 0 ]
    [[ "$output" == *"uthentication"* ]]
}

@test "cmd_test: HTTP 404 does not claim success" {
    _stub_curl 404
    _run_test_cmd oai
    [ "$status" -ne 0 ]
}

@test "cmd_test: HTTP 500 does not claim success" {
    _stub_curl 500
    _run_test_cmd oai
    [ "$status" -ne 0 ]
}

@test "cmd_test: follows redirects" {
    _stub_curl 200
    _run_test_cmd oai
    run grep -c -- '-L' "$BATS_TEST_TMPDIR/curl.argv"
    [ "$output" -ge 1 ]
}

# ---- timing without GNU date or bc ----

@test "cmd_test: reports a numeric response time without bc on PATH" {
    _stub_curl 200
    # A PATH with the ordinary tools but genuinely no bc.
    local nb="$BATS_TEST_TMPDIR/nobc"
    mkdir -p "$nb"
    local t
    for t in bash sh awk sed grep cat date printf; do
        command -v "$t" >/dev/null 2>&1 && ln -sf "$(command -v "$t")" "$nb/$t"
    done
    ln -sf "$STUB/curl" "$nb/curl"
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" PATH="$nb" \
        LLM_OAI_KEY=sk-1 "$nb/bash" -c "source '$SUT' test oai"
    [[ "$output" != *"N/As"* ]]
    [[ "$output" != *"Ns"* ]]
}

# ---- masking ----

@test "mask: never reveals most of a short secret" {
    source "$SUT" >/dev/null 2>&1
    local m
    m="$(mask "abc")";  [[ "$m" != *"bc"* ]]
    m="$(mask "abcd")"; [[ "$m" != *"bcd"* ]]
    m="$(mask "abcde")"; [[ "$m" != *"bcde"* ]]
}

@test "mask: reveals at most the last 4 characters of a long secret" {
    source "$SUT" >/dev/null 2>&1
    local m
    m="$(mask "sk-abcdefghijklmnop")"
    [[ "$m" == *"mnop" ]]
    [[ "$m" != *"lmnop" ]]
}

@test "mask: an empty secret is shown as empty, not as a mask" {
    source "$SUT" >/dev/null 2>&1
    local m; m="$(mask "")"
    [ -n "$m" ]
    [[ "$m" != *"•"* ]]
}

# ---- hyperlinks ----

@test "link: emits plain text when stdout is not a terminal" {
    run bash -c "source '$SUT' >/dev/null 2>&1; link 'https://x.test' 'label'"
    # No OSC 8 introducer.
    [[ "$output" != *$'\033]8;;'* ]]
    [[ "$output" == *"https://x.test"* ]]
}

@test "link: honours NO_COLOR" {
    run bash -c "export NO_COLOR=1 LLM_ENV_TTY=1
                 source '$SUT' >/dev/null 2>&1; link 'https://x.test' 'label'"
    [[ "$output" != *$'\033]8;;'* ]]
}

@test "link: honours TERM=dumb" {
    run bash -c "export TERM=dumb LLM_ENV_TTY=1
                 source '$SUT' >/dev/null 2>&1; link 'https://x.test' 'label'"
    [[ "$output" != *$'\033]8;;'* ]]
}

@test "link: emits OSC 8 when a capable terminal is forced" {
    run bash -c "export LLM_ENV_HYPERLINKS=1
                 source '$SUT' >/dev/null 2>&1; link 'https://x.test' 'label'"
    [[ "$output" == *$'\033]8;;'* ]]
}

@test "quickstart output contains no raw escape sequences when piped" {
    # The user-visible symptom: signup URLs rendered as ]8;;https://... in
    # pipes, files and CI logs.
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        LLM_ENV_QUICKSTART_DIR="$BATS_TEST_DIRNAME/../.." \
        bash -c "source '$SUT' quickstart all </dev/null"
    [[ "$output" != *$'\033]8;;'* ]]
}
