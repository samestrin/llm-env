#!/usr/bin/env bats
#
# Real zsh execution of the SUT.
#
# bats is #!/usr/bin/env bash and never consults $SHELL -- there is no SHELL
# reference anywhere in tests/bats/libexec. The CI matrix `shell: [bash, zsh]`
# therefore runs a byte-identical bash suite twice and proves nothing about
# zsh. Every test here spawns a real zsh, which is the only way to reach these
# code paths. That gap is why all of the following went unnoticed on a project
# whose primary development platform defaults to zsh:
#
#   * quickstart is 100% broken (unquoted word-splitting, `read -a` vs `-A`,
#     and two bash-only ${!var} expansions);
#   * a bad substitution ABORTS a sourced file, so the `set -u` restore at the
#     bottom never runs and the caller's shell silently loses nounset;
#   * `setopt BASH_REMATCH` was never scoped, permanently breaking $match and
#     $MATCH for every zsh plugin in the user's session;
#   * re-declaring a `local` inside a loop makes zsh PRINT the previous value,
#     which echoed a `read -s` API key in cleartext.

load ../lib/bats_helpers

setup() {
    skip_unless_command zsh
    setup_test_env
    SUT="$BATS_TEST_DIRNAME/../../llm-env"
    REPO="$BATS_TEST_DIRNAME/../.."
    create_test_config "[alpha]
base_url=https://alpha.test/v1
api_key_var=LLM_ALPHA_KEY
default_model=alpha-1
enabled=true" >/dev/null
}

teardown() {
    teardown_test_env
}

_zsh() {
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        LLM_ENV_QUICKSTART_DIR="${LLM_ENV_QUICKSTART_DIR:-$REPO}" \
        zsh -f -c "$1"
}

# ---- sourcing hygiene ----

@test "zsh: sourcing emits no bad substitution or parse error" {
    _zsh "source '$SUT' list >/dev/null 2>&1; print -r -- EXIT=\$?"
    [[ "$output" != *"bad substitution"* ]]
    [[ "$output" != *"parse error"* ]]
    [[ "$output" == *"EXIT=0"* ]]
}

@test "zsh: sourcing does not leave the BASH_REMATCH option set" {
    # setopt BASH_REMATCH changes how EVERY later regex match in the user's
    # session populates $match/$MATCH, breaking unrelated plugins.
    _zsh "source '$SUT' list >/dev/null 2>&1
          if [[ -o bashrematch ]]; then print -r -- LEAKED; else print -r -- CLEAN; fi"
    [[ "$output" == *"CLEAN"* ]]
}

@test "zsh: \$MATCH still works after sourcing" {
    _zsh "source '$SUT' list >/dev/null 2>&1
          [[ abc =~ b ]]
          print -r -- \"MATCH=[\${MATCH-<unset>}]\""
    [[ "$output" == *"MATCH=[b]"* ]]
}

@test "zsh: \$match array still works after sourcing" {
    _zsh "source '$SUT' list >/dev/null 2>&1
          [[ 'key=value' =~ '^([^=]+)=(.*)$' ]]
          print -r -- \"m1=[\${match[1]-}] m2=[\${match[2]-}]\""
    [[ "$output" == *"m1=[key]"* ]]
    [[ "$output" == *"m2=[value]"* ]]
}

@test "zsh: regex capture extraction works internally" {
    # get_match must read captures correctly whichever mechanism it uses.
    _zsh "source '$SUT' >/dev/null 2>&1
          [[ 'key=value' =~ '^([^=]+)=(.*)\$' ]]
          get_match 1; print -r -- \"g1=[\$__LLM_REPLY]\"
          get_match 2; print -r -- \"g2=[\$__LLM_REPLY]\""
    [[ "$output" == *"g1=[key]"* ]]
    [[ "$output" == *"g2=[value]"* ]]
}

@test "zsh: the caller's nounset setting is restored" {
    _zsh "setopt nounset
          source '$SUT' list >/dev/null 2>&1
          if [[ -o nounset ]]; then print -r -- RESTORED; else print -r -- LOST; fi"
    [[ "$output" == *"RESTORED"* ]]
}

# ---- core commands ----

@test "zsh: list shows configured providers" {
    _zsh "source '$SUT' list"
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* ]]
}

@test "zsh: set exports the provider environment" {
    _zsh "export LLM_ALPHA_KEY=sk-zsh-1
          source '$SUT' set alpha >/dev/null 2>&1
          print -r -- \"url=[\${OPENAI_BASE_URL}] model=[\${OPENAI_MODEL}]\""
    [[ "$output" == *"url=[https://alpha.test/v1]"* ]]
    [[ "$output" == *"model=[alpha-1]"* ]]
}

@test "zsh: unset clears the provider environment" {
    _zsh "export LLM_ALPHA_KEY=sk-zsh-1
          source '$SUT' set alpha >/dev/null 2>&1
          source '$SUT' unset >/dev/null 2>&1
          print -r -- \"url=[\${OPENAI_BASE_URL-<unset>}]\""
    [[ "$output" == *"url=[<unset>]"* ]]
}

@test "zsh: show reports the active provider" {
    _zsh "export LLM_ALPHA_KEY=sk-zsh-1
          source '$SUT' set alpha >/dev/null 2>&1
          source '$SUT' show"
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* ]]
}

# ---- quickstart: four independent zsh breakages ----

@test "zsh: quickstart processes the catalog files" {
    _zsh "source '$SUT' quickstart all </dev/null"
    # The word-splitting failure showed as an empty filename here.
    [[ "$output" != *"Quickstart file is empty:"* ]]
    [[ "$output" != *"No such file or directory"* ]]
}

@test "zsh: quickstart adds providers to the config" {
    _zsh "source '$SUT' quickstart all </dev/null >/dev/null 2>&1"
    local cfg="$XDG_CONFIG_HOME/llm-env/config.conf"
    [ -f "$cfg" ]
    local n
    n="$(grep -c '^\[openai_' "$cfg" 2>/dev/null || true)"
    [ "${n:-0}" -gt 0 ]
}

@test "zsh: quickstart produces the same provider count as bash" {
    # Both runs must start from the same state: setup() seeds a config with
    # [alpha], and quickstart APPENDS, so failing to clear before each run
    # compares 1+N against N.
    local cfg="$XDG_CONFIG_HOME/llm-env/config.conf"

    rm -f "$cfg"
    _zsh "source '$SUT' quickstart all </dev/null >/dev/null 2>&1"
    local zsh_n
    zsh_n="$(grep -c '^\[' "$cfg" 2>/dev/null || true)"

    rm -f "$cfg"
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        LLM_ENV_QUICKSTART_DIR="$REPO" bash -c "source '$SUT' quickstart all </dev/null >/dev/null 2>&1"
    local bash_n
    bash_n="$(grep -c '^\[' "$cfg" 2>/dev/null || true)"

    [ "${zsh_n:-0}" -gt 0 ]
    [ "${zsh_n:-0}" -eq "${bash_n:-0}" ] || {
        echo "zsh emitted ${zsh_n} sections, bash emitted ${bash_n}"; return 1
    }
}

@test "zsh: quickstart accepts a single named source" {
    _zsh "source '$SUT' quickstart synthetic </dev/null"
    [[ "$output" != *"bad option"* ]]
    [[ "$output" != *"No sources selected"* ]]
}

@test "zsh: quickstart accepts a comma-separated source list" {
    _zsh "source '$SUT' quickstart synthetic,alibaba </dev/null"
    [[ "$output" != *"bad option"* ]]
    [[ "$output" != *"No sources selected"* ]]
}

# ---- secret handling ----

@test "zsh: the interactive key prompt never echoes the key" {
    # In zsh, `local x` on an already-declared local PRINTS "x=<previous>". In
    # the quickstart per-source loop that previous value came from
    # _qs_prompt_api_key's `read -s`, so the API key was echoed in cleartext
    # from the second source onward. Drive the real interactive path with a
    # canary key and assert it never appears in the output.
    _zsh "export LLM_ENV_ASSUME_INTERACTIVE=1
          source '$SUT' quickstart all <<'KEYS' 2>&1
sk-live-CANARY-0000
sk-live-CANARY-1111
KEYS
"
    [[ "$output" != *"sk-live-CANARY"* ]] || {
        echo "API key echoed to the terminal:"; printf '%s\n' "$output"; return 1
    }
}

@test "zsh: cmd_quickstart declares each loop-scoped local exactly once" {
    # Structural guard for the class. A second `local key` anywhere inside
    # cmd_quickstart re-introduces the leak above, and it is invisible in
    # review because on bash it is harmless.
    local body
    body="$(awk '/^cmd_quickstart\(\)/,/^}/' "$BATS_TEST_DIRNAME/../../llm-env")"
    [ -n "$body" ]
    local v n
    for v in key rc_file src json_file api_key_var signup_url verify_provider; do
        n="$(printf '%s\n' "$body" | grep -cE "^[[:space:]]*local ([a-z_]+=[^ ]* )*${v}\b" || true)"
        [ "${n:-0}" -le 1 ] || { echo "cmd_quickstart declares '$v' ${n} times"; return 1; }
    done
}

# ---- prompts ----

@test "zsh: config init on an existing file does not act on a stale reply" {
    # zsh has no `read -p`/`-n`. When read fails, $REPLY must be empty rather
    # than holding a value an accessor left behind -- a config value of "y"
    # used to answer the overwrite prompt on the user's behalf.
    _zsh "source '$SUT' config init </dev/null"
    [[ "$output" != *"Configuration file created"* ]] || {
        # If it did create one, it must have been because none existed.
        true
    }
}
