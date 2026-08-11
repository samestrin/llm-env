#!/usr/bin/env bats
#
# Protocol isolation when switching providers.
#
# set_single_provider exported one protocol's variables without clearing the
# other's, so `set openai` after an Anthropic provider left ANTHROPIC_BASE_URL,
# ANTHROPIC_API_KEY, ANTHROPIC_AUTH_TOKEN and the CLAUDE_CODE_* model overrides
# still exported. Claude Code reads those, so it kept routing to the previous
# host after the user believed they had switched.
#
# Worse, `export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-$auth_token}"` preserved
# a STALE value: setting provider A (which has api_key_var) and then provider B
# (which has only auth_token_var) sent A's key to B's endpoint.
#
# tests/integration/test_protocol_export.bats used to assert this leakage as
# intended behaviour ("Protocol coexistence: ... preserves ... variables").
# Those assertions are inverted as part of this change -- see that file.

load ../lib/bats_helpers

setup() {
    setup_test_env
    SUT="$BATS_TEST_DIRNAME/../../llm-env"
    create_test_config "[oai]
base_url=https://openai.test/v1
api_key_var=LLM_OAI_KEY
default_model=oai-1
protocol=openai
enabled=true

[anth_a]
base_url=https://anth-a.test
api_key_var=LLM_ANTH_A_KEY
default_model=anth-a-1
protocol=anthropic
enabled=true

[anth_b]
base_url=https://anth-b.test
auth_token_var=LLM_ANTH_B_TOKEN
default_model=anth-b-1
protocol=anthropic
enabled=true

[anth_1m]
base_url=https://anth-1m.test
api_key_var=LLM_ANTH_A_KEY
default_model=anth-1m-1
protocol=anthropic
enabled=true
max_context_tokens=1m

[anth_conc5]
base_url=https://anth-conc5.test
api_key_var=LLM_ANTH_A_KEY
default_model=anth-conc5-1
protocol=anthropic
enabled=true
max_tool_use_concurrency=5

[group:mixed]
providers=anth_1m,anth_a

[group:mixed_conc]
providers=anth_conc5,anth_a" >/dev/null
}

teardown() {
    teardown_test_env
}

# Run a sequence of `set` calls in one shell, then dump the named variables.
_after_sets() {
    local dumpvars="$1"; shift
    local seq="" p
    for p in "$@"; do
        seq="$seq source '$SUT' set $p >/dev/null 2>&1;"
    done
    dump_env_after "
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' HOME='$HOME'
        export LLM_OAI_KEY=sk-oai LLM_ANTH_A_KEY=sk-anth-a LLM_ANTH_B_TOKEN=tok-anth-b
        $seq
    " $dumpvars
}

# ---- B1: switching protocol must clear the other protocol ----

@test "isolation: switching anthropic -> openai clears ANTHROPIC_ variables" {
    _after_sets "ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL" \
        anth_a oai
    assert_env_unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL
}

@test "isolation: switching anthropic -> openai clears the CLAUDE_CODE_ overrides" {
    _after_sets "ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_SUBAGENT_MODEL" \
        anth_a oai
    assert_env_unset ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL \
                     ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_SUBAGENT_MODEL
}

# ---- B1a: the declared context window must not outlive its provider ----
#
# A stale CLAUDE_CODE_MAX_CONTEXT_TOKENS is worse than none. Claude Code
# believes it has the previous provider's window and stops auto-compacting in
# time, so the user gets hard context-overflow errors instead of the cosmetic
# unrecognized-model warning the key exists to remove. Three switch paths reach
# it and the obvious implementation only closes one.

@test "isolation: switching anthropic -> openai clears CLAUDE_CODE_MAX_CONTEXT_TOKENS" {
    _after_sets "CLAUDE_CODE_MAX_CONTEXT_TOKENS" anth_1m oai
    assert_env_unset CLAUDE_CODE_MAX_CONTEXT_TOKENS
}

@test "isolation: switching to an anthropic provider without the key clears it" {
    # Both providers are anthropic, so _clear_protocol_env openai never runs.
    # Only the anthropic branch's self-clear covers this.
    _after_sets "CLAUDE_CODE_MAX_CONTEXT_TOKENS ANTHROPIC_BASE_URL" anth_1m anth_a
    assert_env_is ANTHROPIC_BASE_URL "https://anth-a.test"
    assert_env_unset CLAUDE_CODE_MAX_CONTEXT_TOKENS
}

@test "isolation: a group member without the key does not inherit it from an earlier member" {
    # set_multiple_providers clears both protocols ONCE and sets
    # __LLM_SET_ADDITIVE=1, so no member clears another. Every other anthropic
    # variable survives that because it is exported unconditionally; a
    # conditional export would leave anth_1m's window standing against anth_a.
    _after_sets "CLAUDE_CODE_MAX_CONTEXT_TOKENS ANTHROPIC_BASE_URL" mixed
    assert_env_is ANTHROPIC_BASE_URL "https://anth-a.test"
    assert_env_unset CLAUDE_CODE_MAX_CONTEXT_TOKENS
}

@test "isolation: an anthropic provider with the key exports the expanded count" {
    _after_sets "CLAUDE_CODE_MAX_CONTEXT_TOKENS" anth_1m
    assert_env_is CLAUDE_CODE_MAX_CONTEXT_TOKENS 1000000
}

# ---- B1b: the declared tool concurrency must not outlive its provider ----
#
# Same three switch paths as B1a, same reason: a stale
# CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY from a previous provider must not
# survive onto one that declared no cap of its own.

@test "isolation: switching anthropic -> openai clears CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY" {
    _after_sets "CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY" anth_conc5 oai
    assert_env_unset CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY
}

@test "isolation: switching to an anthropic provider without the concurrency key clears it" {
    _after_sets "CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY ANTHROPIC_BASE_URL" anth_conc5 anth_a
    assert_env_is ANTHROPIC_BASE_URL "https://anth-a.test"
    assert_env_unset CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY
}

@test "isolation: a group member without the concurrency key does not inherit it from an earlier member" {
    _after_sets "CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY ANTHROPIC_BASE_URL" mixed_conc
    assert_env_is ANTHROPIC_BASE_URL "https://anth-a.test"
    assert_env_unset CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY
}

@test "isolation: an anthropic provider with the concurrency key exports it" {
    _after_sets "CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY" anth_conc5
    assert_env_is CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY 5
}

@test "isolation: switching openai -> anthropic clears OPENAI_ variables" {
    _after_sets "OPENAI_BASE_URL OPENAI_API_KEY OPENAI_MODEL" oai anth_a
    assert_env_unset OPENAI_BASE_URL OPENAI_API_KEY OPENAI_MODEL
}

@test "isolation: the newly selected provider is still fully configured" {
    # Clearing the other protocol must not damage the one being set.
    _after_sets "OPENAI_BASE_URL OPENAI_MODEL LLM_PROVIDER LLM_PROTOCOL" anth_a oai
    assert_env_is OPENAI_BASE_URL "https://openai.test/v1"
    assert_env_is OPENAI_MODEL "oai-1"
    assert_env_is LLM_PROVIDER "oai"
    assert_env_is LLM_PROTOCOL "openai"
}

# ---- B2: no credential may survive a provider switch ----

@test "isolation: provider A's API key is not reused for provider B" {
    # anth_a declares api_key_var; anth_b declares only auth_token_var. The
    # ${ANTHROPIC_API_KEY:-...} default used to carry A's key into B's request.
    _after_sets "ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL" anth_a anth_b
    assert_env_is ANTHROPIC_BASE_URL "https://anth-b.test"
    [[ "$output" != *"sk-anth-a"* ]] || {
        echo "provider A's key leaked into provider B:"; printf '%s\n' "$output"; return 1
    }
}

@test "isolation: switching between two anthropic providers updates the host" {
    _after_sets "ANTHROPIC_BASE_URL" anth_b anth_a
    assert_env_is ANTHROPIC_BASE_URL "https://anth-a.test"
}

# ---- B3: unset must be symmetric with set ----

@test "isolation: unset clears every variable that set exported" {
    dump_env_after "
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' HOME='$HOME' LLM_ANTH_A_KEY=sk-anth-a
        source '$SUT' set anth_1m >/dev/null 2>&1
        source '$SUT' unset >/dev/null 2>&1
    " ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL \
      ANTHROPIC_DEFAULT_OPUS_MODEL CLAUDE_CODE_SUBAGENT_MODEL \
      CLAUDE_CODE_MAX_CONTEXT_TOKENS LLM_PROVIDER LLM_PROTOCOL
    assert_env_unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN \
                     ANTHROPIC_MODEL ANTHROPIC_DEFAULT_OPUS_MODEL \
                     CLAUDE_CODE_SUBAGENT_MODEL CLAUDE_CODE_MAX_CONTEXT_TOKENS \
                     LLM_PROVIDER LLM_PROTOCOL
}

@test "isolation: unset clears CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY" {
    dump_env_after "
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' HOME='$HOME' LLM_ANTH_A_KEY=sk-anth-a
        source '$SUT' set anth_conc5 >/dev/null 2>&1
        source '$SUT' unset >/dev/null 2>&1
    " CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY
    assert_env_unset CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY
}

@test "isolation: unset preserves a user-set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" {
    # set_single_provider deliberately preserves this via ${...:-false}, then
    # cmd_unset destroyed it unconditionally -- losing a value the user put in
    # their own profile.
    dump_env_after "
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' HOME='$HOME' LLM_ANTH_A_KEY=sk-anth-a
        export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=true
        source '$SUT' set anth_a >/dev/null 2>&1
        source '$SUT' unset >/dev/null 2>&1
    " CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
    assert_env_is CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC true
}

@test "isolation: unset clears OPENAI_MODEL_OVERRIDE" {
    # Documented in cmd_help and honoured by set_single_provider, but never
    # cleared -- so it kept silently overriding every subsequent set.
    dump_env_after "
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' HOME='$HOME' LLM_OAI_KEY=sk-oai
        export OPENAI_MODEL_OVERRIDE=forced-model
        source '$SUT' set oai >/dev/null 2>&1
        source '$SUT' unset >/dev/null 2>&1
    " OPENAI_MODEL_OVERRIDE
    assert_env_unset OPENAI_MODEL_OVERRIDE
}

# ---- cross-shell ----

@test "isolation: protocol switching clears correctly under zsh" {
    skip_unless_command zsh
    run zsh -f -c "
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' HOME='$HOME'
        export LLM_OAI_KEY=sk-oai LLM_ANTH_A_KEY=sk-anth-a
        source '$SUT' set anth_a >/dev/null 2>&1
        source '$SUT' set oai >/dev/null 2>&1
        print -r -- \"ANTH=[\${ANTHROPIC_BASE_URL:-}]\"
    "
    [[ "$output" == *"ANTH=[]"* ]]
}
