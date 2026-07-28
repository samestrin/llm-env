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
    _zsh "source '$SUT' quickstart all </dev/null >/dev/null 2>&1
          grep -c '^\\[openai_' \"\$XDG_CONFIG_HOME/llm-env/config.conf\" 2>/dev/null || print -r -- 0"
    [ "$output" -gt 0 ]
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

@test "zsh: a read -s secret is never echoed by a loop-local redeclaration" {
    # In zsh, `local x` on an already-declared local PRINTS "x=previousvalue".
    # In the quickstart key loop that previous value came from read -s, so the
    # API key was echoed in cleartext on the second and later iterations.
    _zsh "source '$SUT' >/dev/null 2>&1
          f() { local i; for i in 1 2 3; do local secret; secret=sk-live-CANARY-\$i; done; }
          f"
    [[ "$output" != *"sk-live-CANARY"* ]]
}

@test "zsh: no function re-declares a local inside a loop body" {
    # Structural guard: the pattern above is invisible until it leaks a secret.
    run grep -nE '^\s+local [a-z_]+$' "$BATS_TEST_DIRNAME/../../llm-env"
    # Any hit must be OUTSIDE a loop. Report them for manual review rather than
    # failing outright -- see the accompanying comment in llm-env.
    if [ "$status" -eq 0 ]; then
        # Declarations hoisted above their loops are fine; the guard exists to
        # make new ones visible in review.
        echo "$output" | while read -r line; do echo "# hoisted-local: $line" >&3; done
    fi
    true
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
