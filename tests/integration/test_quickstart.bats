#!/usr/bin/env bash

# Tests for cmd_quickstart parsing schema v2 quickstart JSON files.
#
# These tests rely on the LLM_ENV_QUICKSTART_DIR environment variable to
# point cmd_quickstart at a temp directory containing fixture JSON files,
# rather than the script's own directory.

load ../lib/bats_helpers

FIXTURES_DIR=""

setup() {
    setup_test_env

    FIXTURES_DIR="$BATS_TEST_DIRNAME/../fixtures"

    # Stage a per-test quickstart dir; individual tests copy fixtures in.
    export LLM_ENV_QUICKSTART_DIR="$BATS_TEST_TMPDIR/quickstart"
    mkdir -p "$LLM_ENV_QUICKSTART_DIR"

    # Source the script so cmd_quickstart is available.
    source "$BATS_TEST_DIRNAME/../../llm-env" > /dev/null 2>&1 || true
}

teardown() {
    unset LLM_ENV_QUICKSTART_DIR
    teardown_test_env
}

# Convenience: copy one or more fixtures into the staging dir under their
# canonical names so cmd_quickstart picks them up.
stage_fixture() {
    local source_basename="$1"
    local target_basename="$2"
    cp "$FIXTURES_DIR/$source_basename" "$LLM_ENV_QUICKSTART_DIR/$target_basename"
}

user_config() {
    echo "$XDG_CONFIG_HOME/llm-env/config.conf"
}

@test "v2: emits openai_ provider with correct fields" {
    stage_fixture quickstart-synthetic-v2.json quickstart-synthetic.json

    run cmd_quickstart
    [ "$status" -eq 0 ]

    local cfg
    cfg="$(user_config)"
    grep -q '^\[openai_synth_kimi-k2.5\]$' "$cfg"
    grep -A 6 '^\[openai_synth_kimi-k2.5\]$' "$cfg" | grep -q '^base_url=https://api.synthetic.new/openai/v1$'
    grep -A 6 '^\[openai_synth_kimi-k2.5\]$' "$cfg" | grep -q '^api_key_var=LLM_SYNTHETIC_API_KEY$'
    grep -A 6 '^\[openai_synth_kimi-k2.5\]$' "$cfg" | grep -q '^default_model=hf:moonshotai/Kimi-K2.5$'
}

@test "v2: emits anth_ provider with protocol=anthropic and anthropic endpoint" {
    stage_fixture quickstart-synthetic-v2.json quickstart-synthetic.json

    run cmd_quickstart
    [ "$status" -eq 0 ]

    local cfg
    cfg="$(user_config)"
    grep -q '^\[anth_synth_kimi-k2.5\]$' "$cfg"
    grep -A 8 '^\[anth_synth_kimi-k2.5\]$' "$cfg" | grep -q '^base_url=https://api.synthetic.new/anthropic/v1$'
    grep -A 8 '^\[anth_synth_kimi-k2.5\]$' "$cfg" | grep -q '^protocol=anthropic$'
}

@test "v2: emits per-model group when both protocols present" {
    stage_fixture quickstart-synthetic-v2.json quickstart-synthetic.json

    run cmd_quickstart
    [ "$status" -eq 0 ]

    local cfg
    cfg="$(user_config)"
    grep -q '^\[group:synth_kimi-k2.5\]$' "$cfg"
    grep -A 2 '^\[group:synth_kimi-k2.5\]$' "$cfg" | grep -q '^providers=openai_synth_kimi-k2.5,anth_synth_kimi-k2.5$'
}

@test "v2: does not emit group for openai-only model" {
    stage_fixture quickstart-synthetic-v2.json quickstart-synthetic.json

    run cmd_quickstart
    [ "$status" -eq 0 ]

    # glm-4.7-flash has only "openai" in protocols → no per-model group expected
    run grep -c '^\[group:synth_glm-4.7-flash\]$' "$(user_config)"
    [ "$output" = "0" ]
    # And no anth_ provider should exist for it either
    run grep -c '^\[anth_synth_glm-4.7-flash\]$' "$(user_config)"
    [ "$output" = "0" ]
    # But the openai_ provider should exist
    grep -q '^\[openai_synth_glm-4.7-flash\]$' "$(user_config)"
}

@test "v2: emits family_latest groups" {
    stage_fixture quickstart-synthetic-v2.json quickstart-synthetic.json

    run cmd_quickstart
    [ "$status" -eq 0 ]

    local cfg
    cfg="$(user_config)"
    # "kimi" family-latest → group synth_kimi pointing at kimi-k2.5 providers
    grep -q '^\[group:synth_kimi\]$' "$cfg"
    grep -A 2 '^\[group:synth_kimi\]$' "$cfg" | grep -q '^providers=openai_synth_kimi-k2.5,anth_synth_kimi-k2.5$'

    # "glm" family-latest → group synth_glm pointing at glm-5.1
    grep -q '^\[group:synth_glm\]$' "$cfg"
    grep -A 2 '^\[group:synth_glm\]$' "$cfg" | grep -q '^providers=openai_synth_glm-5.1,anth_synth_glm-5.1$'
}

@test "v2: family_latest pointing at openai-only model becomes single-member alias" {
    stage_fixture quickstart-synthetic-v2.json quickstart-synthetic.json

    run cmd_quickstart
    [ "$status" -eq 0 ]

    # glm-flash family-latest → glm-4.7-flash, which is openai-only
    # Group should still be emitted but contain only the single openai_ provider.
    local cfg
    cfg="$(user_config)"
    grep -q '^\[group:synth_glm-flash\]$' "$cfg"
    grep -A 2 '^\[group:synth_glm-flash\]$' "$cfg" | grep -q '^providers=openai_synth_glm-4.7-flash$'
}

@test "v2: handles alibaba fixture independently" {
    stage_fixture quickstart-alibaba-v2.json quickstart-alibaba.json

    run cmd_quickstart
    [ "$status" -eq 0 ]

    local cfg
    cfg="$(user_config)"
    grep -q '^\[openai_alibaba_qwen3.5-plus\]$' "$cfg"
    grep -q '^\[anth_alibaba_qwen3.5-plus\]$' "$cfg"
    grep -q '^\[group:alibaba_qwen3.5-plus\]$' "$cfg"
    grep -q '^\[group:alibaba_qwen\]$' "$cfg"

    # Alibaba endpoints
    grep -A 6 '^\[openai_alibaba_qwen3.5-plus\]$' "$cfg" | grep -q '^base_url=https://coding-intl.dashscope.aliyuncs.com/v1$'
    grep -A 8 '^\[anth_alibaba_qwen3.5-plus\]$' "$cfg" | grep -q '^base_url=https://coding-intl.dashscope.aliyuncs.com/apps/anthropic$'
}

@test "v2: skips already-existing providers (idempotent)" {
    stage_fixture quickstart-synthetic-v2.json quickstart-synthetic.json

    run cmd_quickstart
    [ "$status" -eq 0 ]

    local cfg first_run_lines second_run_lines
    cfg="$(user_config)"
    first_run_lines=$(wc -l < "$cfg")

    # Re-run; should be a no-op.
    run cmd_quickstart
    [ "$status" -eq 0 ]
    second_run_lines=$(wc -l < "$cfg")

    [ "$first_run_lines" = "$second_run_lines" ]
}

@test "v2: rejects schema_version != 2 (legacy v1 file)" {
    stage_fixture quickstart-v1-legacy.json quickstart-synthetic.json

    run cmd_quickstart
    [ "$status" -ne 0 ]
    [[ "$output" == *"schema"* ]] || [[ "$output" == *"v1"* ]] || [[ "$output" == *"version"* ]]
}

@test "v2: rejects malformed JSON" {
    stage_fixture quickstart-malformed.json quickstart-synthetic.json

    run cmd_quickstart
    [ "$status" -ne 0 ]
}

@test "v2: emits no groups (and no anth_ providers) when endpoints.anthropic is missing" {
    cat > "$LLM_ENV_QUICKSTART_DIR/quickstart-synthetic.json" <<'EOF'
{
  "schema_version": "2",
  "generated_at": "2026-04-30T06:00:00Z",
  "source": "synthetic",
  "vendor_short": "synth",
  "endpoints": {
    "openai": "https://api.synthetic.new/openai/v1"
  },
  "api_key_var": "LLM_SYNTHETIC_API_KEY",
  "signup_url": "https://synthetic.new/",
  "models": [
    {
      "id": "kimi-k2.5",
      "family": "kimi",
      "version": "2.5",
      "description": "Kimi K2.5",
      "protocols": ["openai", "anthropic"],
      "upstream_id": "hf:moonshotai/Kimi-K2.5"
    }
  ],
  "family_latest": { "kimi": "kimi-k2.5" }
}
EOF

    run cmd_quickstart
    [ "$status" -eq 0 ]

    local cfg
    cfg="$(user_config)"
    # The anthropic endpoint isn't available, so even though the model's
    # protocols list anthropic, no anth_ provider should be emitted.
    run grep -c '^\[anth_synth_kimi-k2.5\]$' "$cfg"
    [ "$output" = "0" ]
    run grep -c '^\[group:synth_kimi-k2.5\]$' "$cfg"
    [ "$output" = "0" ]
    # openai_ provider still emitted; family_latest group becomes single-member alias.
    grep -q '^\[openai_synth_kimi-k2.5\]$' "$cfg"
    grep -A 2 '^\[group:synth_kimi\]$' "$cfg" | grep -q '^providers=openai_synth_kimi-k2.5$'
}

@test "v2: empty models[] is a graceful no-op" {
    cat > "$LLM_ENV_QUICKSTART_DIR/quickstart-synthetic.json" <<'EOF'
{
  "schema_version": "2",
  "generated_at": "2026-04-30T06:00:00Z",
  "source": "synthetic",
  "vendor_short": "synth",
  "endpoints": {
    "openai": "https://api.synthetic.new/openai/v1",
    "anthropic": "https://api.synthetic.new/anthropic/v1"
  },
  "api_key_var": "LLM_SYNTHETIC_API_KEY",
  "signup_url": "https://synthetic.new/",
  "models": [],
  "family_latest": {}
}
EOF

    run cmd_quickstart
    [ "$status" -eq 0 ]

    # Config should be created (touched) but contain no provider sections from this run.
    local cfg
    cfg="$(user_config)"
    run grep -c '^\[openai_synth_' "$cfg"
    [ "$output" = "0" ]
    run grep -c '^\[group:synth_' "$cfg"
    [ "$output" = "0" ]
}

@test "v2: rejects model id containing INI-breaking characters" {
    cat > "$LLM_ENV_QUICKSTART_DIR/quickstart-synthetic.json" <<'EOF'
{
  "schema_version": "2",
  "generated_at": "2026-04-30T06:00:00Z",
  "source": "synthetic",
  "vendor_short": "synth",
  "endpoints": {
    "openai": "https://api.synthetic.new/openai/v1",
    "anthropic": "https://api.synthetic.new/anthropic/v1"
  },
  "api_key_var": "LLM_SYNTHETIC_API_KEY",
  "signup_url": "https://synthetic.new/",
  "models": [
    {
      "id": "bad[id",
      "family": "kimi",
      "version": "1",
      "description": "Bad",
      "protocols": ["openai"],
      "upstream_id": "x"
    }
  ],
  "family_latest": {}
}
EOF

    run cmd_quickstart
    # Either fail loudly or skip the bad model and emit none of it.
    [ "$status" -ne 0 ] || {
        local cfg
        cfg="$(user_config)"
        run grep -c '\[openai_synth_bad' "$cfg"
        [ "$output" = "0" ]
    }
}

@test "v2: missing JSON files exits with helpful error" {
    # LLM_ENV_QUICKSTART_DIR is empty
    run cmd_quickstart
    [ "$status" -ne 0 ]
    [[ "$output" == *"quickstart-synthetic.json"* ]] || [[ "$output" == *"No quickstart"* ]]
}
