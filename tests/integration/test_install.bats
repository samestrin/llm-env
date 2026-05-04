#!/usr/bin/env bash

# Tests for install.sh:
#   1. The synthetic-providers prompt and add_synthetic_providers helper
#      have been removed.
#   2. When the default install dir is unwritable AND the user is non-root
#      AND no --install-dir flag is passed, the installer falls back to
#      $HOME/.local/bin.
#   3. When --install-dir is passed explicitly, the installer respects it
#      (no fallback) and hard-fails on unwritable explicit dirs.
#   4. show_next_steps surfaces llm-env quickstart and a PATH warning when
#      the fallback dir is not on $PATH.
#
# Tests run install.sh in --offline mode against the in-tree llm-env
# script so no network is required. The tests use the
# LLM_ENV_DEFAULT_INSTALL_DIR env var (a testability hook) to override
# the hardcoded /usr/local/bin default and point at a temp directory we
# control.

INSTALL_SH="$BATS_TEST_DIRNAME/../../install.sh"
LLM_ENV_SCRIPT="$BATS_TEST_DIRNAME/../../llm-env"

setup() {
    export TEST_TMPDIR="${BATS_TMPDIR}/install-bats-$$-${BATS_TEST_NUMBER}"
    rm -rf "$TEST_TMPDIR"
    mkdir -p "$TEST_TMPDIR"

    export ORIG_HOME="$HOME"
    export HOME="$TEST_TMPDIR/home"
    mkdir -p "$HOME"

    # Default installer-target dir we'll point installs at unless overridden.
    export LLM_ENV_DEFAULT_INSTALL_DIR="$TEST_TMPDIR/bin"
    mkdir -p "$LLM_ENV_DEFAULT_INSTALL_DIR"

    # Sanitize PATH to predictable contents.
    export PATH="/usr/bin:/bin"
}

teardown() {
    export HOME="$ORIG_HOME"
    rm -rf "$TEST_TMPDIR"
}

@test "install.sh source code: add_synthetic_providers function is removed" {
    run grep -c '^add_synthetic_providers()' "$INSTALL_SH"
    [ "$status" -ne 0 ] || [ "$output" = "0" ]
}

@test "install.sh source code: 'Add synthetic providers?' prompt is removed" {
    run grep -c 'Add synthetic providers' "$INSTALL_SH"
    [ "$status" -ne 0 ] || [ "$output" = "0" ]
}

@test "install.sh source code: no 'read -p' calls remain (no interactive prompts during install)" {
    # Acceptable: the --uninstall path may still prompt about config removal.
    # Filter out the uninstall prompt to verify only that one remains, and
    # that no install-time read prompts exist.
    local count
    count=$(grep -c 'read -p' "$INSTALL_SH" || true)
    # uninstall_llm_env contains exactly one read -p ("Remove configuration files?")
    [ "$count" -le 1 ]
}

@test "install --offline --install-dir <writable>: succeeds and copies llm-env" {
    local target="$TEST_TMPDIR/explicit-bin"
    mkdir -p "$target"

    run bash "$INSTALL_SH" --offline "$LLM_ENV_SCRIPT" --install-dir "$target"
    [ "$status" -eq 0 ]
    [ -x "$target/llm-env" ]
}

@test "install --offline does not emit synthetic-providers prompt text" {
    local target="$TEST_TMPDIR/explicit-bin"
    mkdir -p "$target"

    run bash "$INSTALL_SH" --offline "$LLM_ENV_SCRIPT" --install-dir "$target"
    [ "$status" -eq 0 ]
    ! echo "$output" | grep -q 'Add synthetic providers'
    ! echo "$output" | grep -q 'synthetic model providers'
}

@test "install --offline (default dir unwritable, non-root): falls back to ~/.local/bin" {
    # Make the "default" install dir unwritable.
    local unwritable="$TEST_TMPDIR/sysdir"
    mkdir -p "$unwritable"
    chmod 555 "$unwritable"

    export LLM_ENV_DEFAULT_INSTALL_DIR="$unwritable"

    # Skip if running as root (we can't simulate non-root from a root test runner).
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        skip "Cannot simulate non-root behavior from a root user"
    fi

    run bash "$INSTALL_SH" --offline "$LLM_ENV_SCRIPT"
    chmod 755 "$unwritable" || true

    [ "$status" -eq 0 ]
    [ -x "$HOME/.local/bin/llm-env" ]
    echo "$output" | grep -qi "\.local/bin"
}

@test "install --offline --install-dir <unwritable>: hard-fails (explicit choice respected)" {
    local unwritable="$TEST_TMPDIR/blocked"
    mkdir -p "$unwritable"
    chmod 555 "$unwritable"

    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        skip "Cannot simulate non-root behavior from a root user"
    fi

    run bash "$INSTALL_SH" --offline "$LLM_ENV_SCRIPT" --install-dir "$unwritable"
    chmod 755 "$unwritable" || true

    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "sudo"
}

@test "install --offline shows quickstart hint in next-steps" {
    local target="$TEST_TMPDIR/explicit-bin"
    mkdir -p "$target"

    run bash "$INSTALL_SH" --offline "$LLM_ENV_SCRIPT" --install-dir "$target"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "llm-env quickstart"
}

@test "install fallback to ~/.local/bin: warns when not on PATH" {
    local unwritable="$TEST_TMPDIR/sysdir"
    mkdir -p "$unwritable"
    chmod 555 "$unwritable"

    export LLM_ENV_DEFAULT_INSTALL_DIR="$unwritable"
    # PATH does not contain $HOME/.local/bin

    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        skip "Cannot simulate non-root behavior from a root user"
    fi

    run bash "$INSTALL_SH" --offline "$LLM_ENV_SCRIPT"
    chmod 755 "$unwritable" || true

    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "PATH"
    echo "$output" | grep -q "\.local/bin"
}

@test "install fallback to ~/.local/bin: no PATH warning when already on PATH" {
    local unwritable="$TEST_TMPDIR/sysdir"
    mkdir -p "$unwritable"
    chmod 555 "$unwritable"

    export LLM_ENV_DEFAULT_INSTALL_DIR="$unwritable"
    export PATH="$HOME/.local/bin:$PATH"

    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        skip "Cannot simulate non-root behavior from a root user"
    fi

    run bash "$INSTALL_SH" --offline "$LLM_ENV_SCRIPT"
    chmod 755 "$unwritable" || true

    [ "$status" -eq 0 ]
    # The visible "add this to PATH" warning should not appear.
    ! echo "$output" | grep -qi "Add .* to your PATH"
}

@test "install --install-dir <new-dir>: creates the dir if its parent is writable" {
    # Don't pre-create the target — the installer should mkdir -p for us.
    local target="$TEST_TMPDIR/created-bin"
    [ ! -e "$target" ]

    run bash "$INSTALL_SH" --offline "$LLM_ENV_SCRIPT" --install-dir "$target"
    [ "$status" -eq 0 ]
    [ -x "$target/llm-env" ]
}

@test "uninstall finds llm-env at ~/.local/bin when default is unwritable" {
    # Simulate prior install at ~/.local/bin
    mkdir -p "$HOME/.local/bin"
    cp "$LLM_ENV_SCRIPT" "$HOME/.local/bin/llm-env"
    chmod 755 "$HOME/.local/bin/llm-env"

    # Make the default install dir unwritable so the uninstaller can't reach it
    local unwritable="$TEST_TMPDIR/sysdir"
    mkdir -p "$unwritable"
    chmod 555 "$unwritable"
    export LLM_ENV_DEFAULT_INSTALL_DIR="$unwritable"

    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        skip "Cannot simulate non-root from a root user"
    fi

    # Pipe 'n' so the "Remove configuration files?" prompt gets a definitive answer.
    run bash -c "echo n | bash '$INSTALL_SH' --uninstall"
    chmod 755 "$unwritable" || true

    [ "$status" -eq 0 ]
    [ ! -e "$HOME/.local/bin/llm-env" ]
}

@test "uninstall respects --install-dir even when passed after --uninstall" {
    local target="$TEST_TMPDIR/explicit-bin"
    mkdir -p "$target"
    cp "$LLM_ENV_SCRIPT" "$target/llm-env"
    chmod 755 "$target/llm-env"

    run bash -c "echo n | bash '$INSTALL_SH' --uninstall --install-dir '$target'"
    [ "$status" -eq 0 ]
    [ ! -e "$target/llm-env" ]
}

@test "install --offline --install-dir embeds dir in shell function literal" {
    local target="$TEST_TMPDIR/explicit-bin"
    mkdir -p "$target"

    # Force a known shell so we get a known rc file.
    SHELL="/bin/bash" run bash "$INSTALL_SH" --offline "$LLM_ENV_SCRIPT" --install-dir "$target"
    [ "$status" -eq 0 ]

    # Shell function should be added to ~/.bashrc (or bash_profile fallback).
    local rc=""
    if [ -f "$HOME/.bashrc" ]; then
        rc="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        rc="$HOME/.bash_profile"
    fi

    [ -n "$rc" ]
    grep -q "$target/llm-env" "$rc"
}
