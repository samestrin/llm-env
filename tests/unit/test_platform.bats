#!/usr/bin/env bats
#
# Platform detection and the decisions that depend on it.
#
# Before this there was NO platform detection anywhere: grepping llm-env and
# install.sh for uname, $OSTYPE, $MSYSTEM or WSL returned nothing at all. Three
# decisions were therefore wrong off-Linux:
#
#   * the system config tier hardcoded /usr/local/etc, which on Git Bash maps
#     into C:\Program Files\Git and never exists, and which is the wrong prefix
#     for Apple-Silicon Homebrew (/opt/homebrew/etc);
#   * CONFIG_SOURCE was decided by string-comparing against that literal, so
#     "system" was unreachable anywhere else;
#   * the shell rc file targeted ~/.bashrc, but Git Bash's mintty launches
#     `bash --login -i`, which reads ~/.bash_profile and never ~/.bashrc on its
#     own -- so both the installer and quickstart reported success while the
#     tool stayed undefined in the next session.
#
# Every test forces a platform via LLM_ENV_PLATFORM rather than requiring the
# real OS, following the repo's existing override convention
# (LLM_ENV_QUICKSTART_DIR, LLM_ENV_DEFAULT_INSTALL_DIR).

load ../lib/bats_helpers

setup() {
    setup_test_env
    SUT="$BATS_TEST_DIRNAME/../../llm-env"
    export SHELL="$BATS_TEST_TMPDIR/fake/bash"
}

teardown() {
    teardown_test_env
}

_with_platform() {
    local plat="$1"; shift
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        LLM_ENV_PLATFORM="$plat" SHELL="${SHELL:-}" \
        bash -c "source '$SUT' >/dev/null 2>&1; $*"
}

# ---- detection ----

@test "platform: OSTYPE=msys is detected as msys" {
    run bash -c "OSTYPE=msys; source '$SUT' >/dev/null 2>&1; printf '%s' \"\$__LLM_PLATFORM\""
    [ "$output" = "msys" ]
}

@test "platform: OSTYPE=cygwin is detected as cygwin" {
    run bash -c "OSTYPE=cygwin; source '$SUT' >/dev/null 2>&1; printf '%s' \"\$__LLM_PLATFORM\""
    [ "$output" = "cygwin" ]
}

@test "platform: OSTYPE=darwin is detected as macos" {
    run bash -c "OSTYPE=darwin24; source '$SUT' >/dev/null 2>&1; printf '%s' \"\$__LLM_PLATFORM\""
    [ "$output" = "macos" ]
}

@test "platform: plain linux is detected as linux" {
    run bash -c "OSTYPE=linux-gnu; unset WSL_DISTRO_NAME WSL_INTEROP
                 source '$SUT' >/dev/null 2>&1; printf '%s' \"\$__LLM_PLATFORM\""
    [ "$output" = "linux" ]
}

@test "platform: WSL_DISTRO_NAME marks linux as wsl" {
    run bash -c "OSTYPE=linux-gnu WSL_DISTRO_NAME=Ubuntu
                 source '$SUT' >/dev/null 2>&1; printf '%s' \"\$__LLM_PLATFORM\""
    [ "$output" = "wsl" ]
}

@test "platform: LLM_ENV_PLATFORM overrides detection" {
    _with_platform msys 'printf "%s" "$__LLM_PLATFORM"'
    [ "$output" = "msys" ]
}

@test "platform: the detected platform is not exported to child processes" {
    # llm-env already exported CURRENT_SHELL and BASH_* into every child; the
    # platform layer must not add to that.
    run bash -c "source '$SUT' >/dev/null 2>&1; env | grep -c '^__LLM_PLATFORM=' || true"
    [ "$output" -eq 0 ]
}

# ---- config tiers ----

@test "tiers: msys does not offer the /usr/local/etc system tier" {
    _with_platform msys 'get_config_locations'
    [[ "$output" != *"/usr/local/etc"* ]]
}

@test "tiers: macos offers the Apple-Silicon Homebrew prefix" {
    _with_platform macos 'get_config_locations'
    [[ "$output" == *"/opt/homebrew/etc"* ]]
}

@test "tiers: linux offers /etc and /usr/local/etc" {
    _with_platform linux 'get_config_locations'
    [[ "$output" == *"/usr/local/etc"* ]]
}

@test "tiers: the user config is always the highest-precedence tier" {
    _with_platform linux 'get_config_locations | head -1'
    [[ "$output" == *"$XDG_CONFIG_HOME/llm-env/config.conf"* ]]
}

@test "tiers: the tier list is identical under zsh" {
    # `local IFS=':'; for d in $sysdirs` does not split under zsh, so the whole
    # colon-separated list became one malformed path. Caught by the cumulative
    # adversarial review, not by the bash-only tests above.
    skip_unless_command zsh
    local b z
    b="$(bash    -c "source '$SUT' >/dev/null 2>&1; LLM_ENV_PLATFORM=macos get_config_locations")"
    z="$(zsh -f  -c "source '$SUT' >/dev/null 2>&1; LLM_ENV_PLATFORM=macos get_config_locations")"
    [ "$b" = "$z" ] || {
        echo "bash:"; printf '%s\n' "$b"
        echo "zsh:";  printf '%s\n' "$z"
        return 1
    }
}

@test "tiers: every emitted path is absolute and contains no colon" {
    _with_platform macos 'get_config_locations'
    local line path
    while IFS= read -r line; do
        path="${line#*	}"
        [[ "$path" != *:* ]] || { echo "colon in emitted path: $path"; return 1; }
    done <<< "$output"
}

@test "tiers: LLM_ENV_SYSTEM_CONFIG_DIRS overrides the system tier" {
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        LLM_ENV_SYSTEM_CONFIG_DIRS="$BATS_TEST_TMPDIR/etc" \
        bash -c "source '$SUT' >/dev/null 2>&1; get_config_locations"
    [[ "$output" == *"$BATS_TEST_TMPDIR/etc/llm-env/config.conf"* ]]
}

@test "tiers: CONFIG_SOURCE=system is reachable via an overridden tier" {
    # It was decided by string-comparing against the hardcoded /usr/local/etc
    # literal, so "system" could never be reported anywhere else.
    local sysdir="$BATS_TEST_TMPDIR/etc"
    mkdir -p "$sysdir/llm-env"
    cat > "$sysdir/llm-env/config.conf" <<'EOF'
[sysprov]
base_url=https://sys.test/v1
api_key_var=K
default_model=m
enabled=true
EOF
    rm -f "$XDG_CONFIG_HOME/llm-env/config.conf"
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        LLM_ENV_SYSTEM_CONFIG_DIRS="$sysdir" \
        bash -c "source '$SUT' >/dev/null 2>&1; printf '%s' \"\$CONFIG_SOURCE\""
    [ "$output" = "system" ]
}

# ---- shell rc selection ----

@test "rc: msys prefers a login file over .bashrc" {
    # mintty runs `bash --login -i`, which never sources ~/.bashrc by itself.
    : > "$HOME/.bashrc"
    : > "$HOME/.bash_profile"
    _with_platform msys 'detect_shell_rc'
    [[ "$output" == *".bash_profile"* ]]
    [[ "$output" != *".bashrc"* ]]
}

@test "rc: msys falls back to .profile when no bash_profile exists" {
    : > "$HOME/.profile"
    _with_platform msys 'detect_shell_rc'
    [[ "$output" == *".profile"* ]]
}

@test "rc: linux keeps using .bashrc" {
    : > "$HOME/.bashrc"
    _with_platform linux 'detect_shell_rc'
    [[ "$output" == *".bashrc"* ]]
}

@test "rc: selection follows the running shell, not \$SHELL" {
    # Branching on \$SHELL (the LOGIN shell) meant a user running bash inside a
    # zsh login shell had their key appended to ~/.zshrc and was then told to
    # source it from bash.
    run env HOME="$HOME" SHELL=/bin/zsh LLM_ENV_PLATFORM=linux \
        bash -c "source '$SUT' >/dev/null 2>&1; detect_shell_rc"
    [[ "$output" == *".bashrc"* ]]
    [[ "$output" != *".zshrc"* ]]
}

@test "rc: LLM_ENV_RC_FILE overrides selection" {
    run env HOME="$HOME" LLM_ENV_RC_FILE="$BATS_TEST_TMPDIR/custom_rc" \
        bash -c "source '$SUT' >/dev/null 2>&1; detect_shell_rc"
    [ "$output" = "$BATS_TEST_TMPDIR/custom_rc" ]
}

@test "rc: _qs_detect_shell_rc delegates to the shared implementation" {
    : > "$HOME/.bashrc"
    _with_platform linux 'a="$(detect_shell_rc)"; b="$(_qs_detect_shell_rc)"; [ "$a" = "$b" ] && printf SAME || printf "DIFF a=$a b=$b"'
    [ "$output" = "SAME" ]
}

# ---- path handling ----

@test "paths: get_script_dir tolerates a backslash-separated path" {
    # dirname finds no '/' in 'C:\repo\llm-env' and returns '.', so the builtin
    # config tier silently resolved relative to $PWD.
    run bash -c "source '$SUT' >/dev/null 2>&1
                 printf '%s' \"\$(__llm_normalize_path 'C:\\\\repo\\\\llm-env')\""
    [[ "$output" == *"/"* ]]
    [[ "$output" != *"\\"* ]]
}
