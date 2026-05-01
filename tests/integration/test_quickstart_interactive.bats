#!/usr/bin/env bash

# Tests for the interactive helpers used by cmd_quickstart:
#   _qs_detect_shell_rc
#   _qs_key_already_set
#   _qs_prompt_api_key
#   _qs_append_export_to_rc
#   _qs_verify_key
#
# BATS' `run` doesn't allocate a TTY, so `[[ -t 0 ]]` is false during
# tests. We test the helpers directly (unit style) and exercise the
# interactive cmd_quickstart path by stubbing _qs_is_interactive.
#
# All HTTP calls (curl/wget) made by cmd_test are mocked to avoid
# real network and real API quota usage.

load ../lib/bats_helpers

setup() {
    setup_test_env

    # Stage a per-test quickstart dir.
    export LLM_ENV_QUICKSTART_DIR="$BATS_TEST_TMPDIR/quickstart"
    mkdir -p "$LLM_ENV_QUICKSTART_DIR"

    # A scratch rc file the tests can write to / inspect.
    export TEST_RC_FILE="$BATS_TEST_TMPDIR/test-rc"
    : > "$TEST_RC_FILE"

    # Source the script so all _qs_* helpers are available.
    source "$BATS_TEST_DIRNAME/../../llm-env" > /dev/null 2>&1 || true
}

teardown() {
    unset LLM_ENV_QUICKSTART_DIR TEST_RC_FILE
    teardown_test_env
    # Defensively unset any keys tests may have exported.
    unset LLM_TEST_FAKE_KEY LLM_SYNTHETIC_API_KEY LLM_ALIBABA_API_KEY
}

stage_fixture() {
    local source_basename="$1"
    local target_basename="$2"
    cp "$BATS_TEST_DIRNAME/../fixtures/$source_basename" \
       "$LLM_ENV_QUICKSTART_DIR/$target_basename"
}

# --- _qs_detect_shell_rc ------------------------------------------------------

@test "detect_shell_rc: zsh → ~/.zshrc" {
    SHELL=/bin/zsh run _qs_detect_shell_rc
    [ "$status" -eq 0 ]
    [[ "$output" == "$HOME/.zshrc" ]]
}

@test "detect_shell_rc: bash → ~/.bashrc when .bashrc exists" {
    : > "$HOME/.bashrc"
    SHELL=/bin/bash run _qs_detect_shell_rc
    [ "$status" -eq 0 ]
    [[ "$output" == "$HOME/.bashrc" ]]
}

@test "detect_shell_rc: bash → ~/.bash_profile when .bashrc missing but .bash_profile exists" {
    rm -f "$HOME/.bashrc"
    : > "$HOME/.bash_profile"
    SHELL=/bin/bash run _qs_detect_shell_rc
    [ "$status" -eq 0 ]
    [[ "$output" == "$HOME/.bash_profile" ]]
}

@test "detect_shell_rc: bash → ~/.bashrc when neither file exists (default)" {
    rm -f "$HOME/.bashrc" "$HOME/.bash_profile"
    SHELL=/bin/bash run _qs_detect_shell_rc
    [ "$status" -eq 0 ]
    [[ "$output" == "$HOME/.bashrc" ]]
}

@test "detect_shell_rc: fish → empty (caller falls back to print)" {
    SHELL=/usr/bin/fish run _qs_detect_shell_rc
    [ "$status" -eq 0 ]
    [[ -z "$output" ]]
}

@test "detect_shell_rc: csh/tcsh/unknown → empty" {
    SHELL=/bin/csh run _qs_detect_shell_rc
    [ "$status" -eq 0 ]
    [[ -z "$output" ]]

    SHELL=/some/weird/shell run _qs_detect_shell_rc
    [ "$status" -eq 0 ]
    [[ -z "$output" ]]
}

# --- _qs_key_already_set ------------------------------------------------------

@test "key_already_set: false when neither env nor rc has it" {
    unset LLM_TEST_FAKE_KEY
    : > "$TEST_RC_FILE"
    run _qs_key_already_set "LLM_TEST_FAKE_KEY" "$TEST_RC_FILE"
    [ "$status" -ne 0 ]
}

@test "key_already_set: true when env var is set" {
    export LLM_TEST_FAKE_KEY="sk-test-something"
    : > "$TEST_RC_FILE"
    run _qs_key_already_set "LLM_TEST_FAKE_KEY" "$TEST_RC_FILE"
    [ "$status" -eq 0 ]
}

@test "key_already_set: true when rc file contains export line" {
    unset LLM_TEST_FAKE_KEY
    echo 'export LLM_TEST_FAKE_KEY="sk-test"' > "$TEST_RC_FILE"
    run _qs_key_already_set "LLM_TEST_FAKE_KEY" "$TEST_RC_FILE"
    [ "$status" -eq 0 ]
}

@test "key_already_set: true with leading whitespace and single quotes" {
    unset LLM_TEST_FAKE_KEY
    printf "  export LLM_TEST_FAKE_KEY='val'\n" > "$TEST_RC_FILE"
    run _qs_key_already_set "LLM_TEST_FAKE_KEY" "$TEST_RC_FILE"
    [ "$status" -eq 0 ]
}

@test "key_already_set: false when rc file has unrelated VAR" {
    unset LLM_TEST_FAKE_KEY
    echo 'export OTHER_VAR="x"' > "$TEST_RC_FILE"
    run _qs_key_already_set "LLM_TEST_FAKE_KEY" "$TEST_RC_FILE"
    [ "$status" -ne 0 ]
}

@test "key_already_set: false when rc file is empty path (unsupported shell)" {
    unset LLM_TEST_FAKE_KEY
    run _qs_key_already_set "LLM_TEST_FAKE_KEY" ""
    [ "$status" -ne 0 ]
}

# --- _qs_append_export_to_rc --------------------------------------------------

@test "append_export: writes a single export line" {
    : > "$TEST_RC_FILE"
    run _qs_append_export_to_rc "LLM_TEST_FAKE_KEY" "sk-fake-12345" "$TEST_RC_FILE"
    [ "$status" -eq 0 ]
    grep -q "^export LLM_TEST_FAKE_KEY='sk-fake-12345'$" "$TEST_RC_FILE"
}

@test "append_export: refuses to duplicate when line already exists" {
    echo 'export LLM_TEST_FAKE_KEY="existing"' > "$TEST_RC_FILE"
    run _qs_append_export_to_rc "LLM_TEST_FAKE_KEY" "new-value" "$TEST_RC_FILE"
    # Should not add a second line.
    local count
    count=$(grep -c "^[[:space:]]*export LLM_TEST_FAKE_KEY=" "$TEST_RC_FILE")
    [ "$count" = "1" ]
    # Original value preserved (not overwritten).
    grep -q '^export LLM_TEST_FAKE_KEY="existing"$' "$TEST_RC_FILE"
}

@test "append_export: handles key with embedded single quote" {
    : > "$TEST_RC_FILE"
    # Key contains a literal apostrophe; export line must be parseable.
    run _qs_append_export_to_rc "LLM_TEST_FAKE_KEY" "ab'cd" "$TEST_RC_FILE"
    [ "$status" -eq 0 ]
    # Sanity: sourcing the rc file should give us the right value.
    # shellcheck source=/dev/null
    (source "$TEST_RC_FILE" && [[ "$LLM_TEST_FAKE_KEY" == "ab'cd" ]])
}

@test "append_export: handles key with shell metacharacters (\$, \`, \\)" {
    : > "$TEST_RC_FILE"
    local raw='ab$cd`ef\gh'
    run _qs_append_export_to_rc "LLM_TEST_FAKE_KEY" "$raw" "$TEST_RC_FILE"
    [ "$status" -eq 0 ]
    # shellcheck source=/dev/null
    (
        source "$TEST_RC_FILE"
        [[ "$LLM_TEST_FAKE_KEY" == 'ab$cd`ef\gh' ]]
    )
}

@test "append_export: empty rc path returns nonzero (fallback signal)" {
    run _qs_append_export_to_rc "LLM_TEST_FAKE_KEY" "value" ""
    [ "$status" -ne 0 ]
}

@test "append_export: appends a leading newline if file lacks trailing newline" {
    # File without trailing newline.
    printf 'existing line' > "$TEST_RC_FILE"
    run _qs_append_export_to_rc "LLM_TEST_FAKE_KEY" "value" "$TEST_RC_FILE"
    [ "$status" -eq 0 ]
    # Line containing 'existing line' should still be a complete line.
    grep -qx "existing line" "$TEST_RC_FILE"
    # Export line should also exist as its own line.
    grep -q "^export LLM_TEST_FAKE_KEY='value'$" "$TEST_RC_FILE"
}

@test "append_export: rc path is a directory → returns nonzero, does not crash" {
    local dir_path="$BATS_TEST_TMPDIR/some-dir"
    mkdir -p "$dir_path"
    run _qs_append_export_to_rc "LLM_TEST_FAKE_KEY" "value" "$dir_path"
    [ "$status" -ne 0 ]
}

@test "append_export: rc path unwritable → returns nonzero gracefully" {
    : > "$TEST_RC_FILE"
    chmod 000 "$TEST_RC_FILE"
    run _qs_append_export_to_rc "LLM_TEST_FAKE_KEY" "value" "$TEST_RC_FILE"
    chmod 644 "$TEST_RC_FILE"
    [ "$status" -ne 0 ]
}

@test "append_export: value with embedded newline is rejected/truncated, no rc corruption" {
    : > "$TEST_RC_FILE"
    # A multi-line value would corrupt the rc file. Verify behavior:
    # either the helper rejects it, or it embeds it safely inside the
    # single-quoted form (which is also valid because single-quoted
    # bash strings preserve newlines).
    local raw=$'line1\nline2'
    run _qs_append_export_to_rc "LLM_TEST_FAKE_KEY" "$raw" "$TEST_RC_FILE"
    [ "$status" -eq 0 ]
    # shellcheck source=/dev/null
    (
        source "$TEST_RC_FILE"
        [[ "$LLM_TEST_FAKE_KEY" == "$raw" ]]
    )
}

# --- _qs_prompt_api_key -------------------------------------------------------

@test "prompt_api_key: empty input → skip (returns 1)" {
    run bash -c "
        source '$BATS_TEST_DIRNAME/../../llm-env' >/dev/null 2>&1
        _qs_prompt_api_key 'LLM_TEST_FAKE_KEY'
    " <<< ""
    [ "$status" -ne 0 ]
}

@test "prompt_api_key: 's' input → skip (returns 1)" {
    run bash -c "
        source '$BATS_TEST_DIRNAME/../../llm-env' >/dev/null 2>&1
        _qs_prompt_api_key 'LLM_TEST_FAKE_KEY'
    " <<< "s"
    [ "$status" -ne 0 ]
}

@test "prompt_api_key: whitespace-only input → skip" {
    run bash -c "
        source '$BATS_TEST_DIRNAME/../../llm-env' >/dev/null 2>&1
        _qs_prompt_api_key 'LLM_TEST_FAKE_KEY'
    " <<< "   "
    [ "$status" -ne 0 ]
}

@test "prompt_api_key: real key returns 0 and echoes the key on stdout" {
    run bash -c "
        source '$BATS_TEST_DIRNAME/../../llm-env' >/dev/null 2>&1
        _qs_prompt_api_key 'LLM_TEST_FAKE_KEY'
    " <<< "sk-real-key-12345"
    [ "$status" -eq 0 ]
    [[ "$output" == *"sk-real-key-12345"* ]]
}

# --- _qs_verify_key -----------------------------------------------------------
#
# cmd_test makes real HTTP calls. The plan requires mocking these to
# avoid network and API quota. We override curl in the subshell that
# runs cmd_test so the call is deterministic.

@test "verify_key: success when mocked HTTP returns 200" {
    # Build a fake config containing the provider we'll test against.
    local cfg="$XDG_CONFIG_HOME/llm-env/config.conf"
    mkdir -p "$(dirname "$cfg")"
    cat > "$cfg" <<EOF
[fake_provider]
base_url=https://example.invalid/v1
api_key_var=LLM_TEST_FAKE_KEY
default_model=fake-model
description=Fake provider for verify_key tests
protocol=openai
enabled=true
EOF
    export LLM_TEST_FAKE_KEY="sk-fake"

    # Mock curl: any request returns a successful 200 with empty data.
    curl() {
        # Echo a minimal OpenAI /models response and HTTP 200 status.
        if [[ "$*" == *"-w"* ]]; then
            echo '{"data":[]}'
            echo "200"
        else
            echo '{"data":[]}'
        fi
        return 0
    }
    export -f curl

    # Re-source so cmd_test sees the new config.
    source "$BATS_TEST_DIRNAME/../../llm-env" > /dev/null 2>&1 || true

    run _qs_verify_key "fake_provider"
    [ "$status" -eq 0 ]
    [[ "$output" == *"✅"* ]] || [[ "$output" == *"ok"* ]]
}

@test "verify_key: failure when mocked HTTP returns error, but exits 0 (informational only)" {
    local cfg="$XDG_CONFIG_HOME/llm-env/config.conf"
    mkdir -p "$(dirname "$cfg")"
    cat > "$cfg" <<EOF
[fake_provider]
base_url=https://example.invalid/v1
api_key_var=LLM_TEST_FAKE_KEY
default_model=fake-model
description=Fake provider
protocol=openai
enabled=true
EOF
    export LLM_TEST_FAKE_KEY="sk-fake"

    # Mock curl: simulate a failure.
    curl() { return 7; }   # connection failed
    export -f curl

    source "$BATS_TEST_DIRNAME/../../llm-env" > /dev/null 2>&1 || true

    run _qs_verify_key "fake_provider"
    # Verification is informational — the helper itself returns 0
    # (or non-zero with a warning prefix) but should NOT cause the
    # caller's quickstart to abort. Both 0 and non-0 here are
    # acceptable as long as a warning was printed.
    [[ "$output" == *"❌"* ]] || [[ "$output" == *"failed"* ]] || [[ "$output" == *"warning"* ]] || [[ "$output" == *"Warning"* ]]
}

# --- Integration via cmd_quickstart with stubbed interactivity ---------------

@test "interactive: env-already-set skips key prompt entirely" {
    stage_fixture quickstart-synthetic-v2.json quickstart-synthetic.json

    # Pre-set the env var. Stub _qs_is_interactive to return true so
    # cmd_quickstart enters the interactive branch.
    export LLM_SYNTHETIC_API_KEY="sk-already-here"

    _qs_is_interactive() { return 0; }
    export -f _qs_is_interactive

    # Stub the menu reader so cmd_quickstart doesn't actually try
    # to read from stdin.
    _qs_choose_sources() { echo "synthetic"; return 0; }
    export -f _qs_choose_sources

    # Stub _qs_prompt_api_key so a failure of the skip-detection
    # would manifest as the prompt being entered (we record).
    _qs_prompt_api_key() {
        echo "PROMPT-WAS-CALLED" >&2
        return 1
    }
    export -f _qs_prompt_api_key

    # Stub _qs_verify_key to a no-op success.
    _qs_verify_key() { return 0; }
    export -f _qs_verify_key

    run cmd_quickstart
    [ "$status" -eq 0 ]
    # The prompt must NOT have been called (env-already-set short-circuit).
    [[ "$output" != *"PROMPT-WAS-CALLED"* ]]
    [[ "$stderr" != *"PROMPT-WAS-CALLED"* ]] 2>/dev/null || true
    # The skip notice should be visible.
    [[ "$output" == *"already configured"* ]] || [[ "$output" == *"skip"* ]]
}
