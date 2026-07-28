#!/usr/bin/env bats
#
# Quickstart JSON parsing and the scraped-catalog supply chain.
#
# quickstart-*.json is refreshed daily by scripts/update_quickstart.py against
# live provider APIs and squash-merged with NO human review
# (.github/workflows/update-quickstart.yml). _qs_emit_provider then writes those
# scraped strings straight into the user's config, which llm-env sources on
# every invocation. That makes the parser and its validation a supply-chain
# boundary, not a convenience.
#
# The store no longer evals values, so a hostile string can no longer execute.
# These tests cover the remaining exposure: fields that are written verbatim
# without validation, and parser bugs that corrupt or drop legitimate entries.

load ../lib/bats_helpers

setup() {
    setup_test_env
    SUT="$BATS_TEST_DIRNAME/../../llm-env"
    REPO="$BATS_TEST_DIRNAME/../.."
    QS="$BATS_TEST_TMPDIR/qs"
    mkdir -p "$QS"
    source "$SUT" >/dev/null 2>&1
}

teardown() {
    teardown_test_env
}

_run_quickstart() {
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        LLM_ENV_QUICKSTART_DIR="$QS" \
        bash -c "source '$SUT' quickstart ${1:-all} </dev/null"
}

_cfg() { printf '%s' "$XDG_CONFIG_HOME/llm-env/config.conf"; }

# ---- parser: escaped quotes ----

@test "qs parser: a value containing an escaped quote is not truncated" {
    local out
    out="$(_qs_json_string '{"description": "say \"hi\" now"}' description)"
    # The grep -o '"[^"]*"' form stopped at the backslash and wrote the
    # truncated remains into the user's config as a description.
    [ "$out" != 'say \' ]
    [[ "$out" == *hi* ]]
}

@test "qs parser: an escaped quote does not corrupt the emitted config" {
    cat > "$QS/quickstart-synthetic.json" <<'EOF'
{
  "schema_version": "2",
  "vendor_short": "synth",
  "api_key_var": "LLM_SYNTHETIC_API_KEY",
  "endpoints": { "openai": "https://api.synthetic.test/openai/v1" },
  "models": [
    { "id": "m1", "description": "the \"fast\" one", "protocols": ["openai"] }
  ]
}
EOF
    _run_quickstart synthetic
    [ -f "$(_cfg)" ]
    # A truncated description must never end the line with a dangling backslash,
    # which would make the next config line a continuation.
    run grep -c '\\$' "$(_cfg)"
    [ "$output" -eq 0 ]
}

# ---- parser: nested objects in family_latest ----

@test "qs parser: extract_string_pairs skips nested objects" {
    local out
    out="$(_qs_extract_string_pairs '{"kimi":"kimi-k2.5","nested":{"inner":"boom"},"glm":"glm-5"}')"
    # Its own docstring claims nested objects are skipped; the flattened grep
    # emitted inner=boom, which became a bogus [group:*] section.
    [[ "$out" != *"inner=boom"* ]]
    [[ "$out" == *"kimi=kimi-k2.5"* ]]
    [[ "$out" == *"glm=glm-5"* ]]
}

# ---- validation of scraped fields ----

@test "qs validation: a hostile upstream_id is rejected, not written to config" {
    make_hostile_quickstart upstream_id "$QS"
    _run_quickstart synthetic
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
    if [ -f "$(_cfg)" ]; then
        run grep -c 'printf pwned' "$(_cfg)"
        [ "$output" -eq 0 ]
    fi
}

@test "qs validation: a hostile endpoint URL is rejected" {
    make_hostile_quickstart endpoints "$QS"
    _run_quickstart synthetic
    assert_sentinel_absent "$LLM_ENV_TEST_SENTINEL"
    if [ -f "$(_cfg)" ]; then
        run grep -c 'printf pwned' "$(_cfg)"
        [ "$output" -eq 0 ]
    fi
}

@test "qs validation: a description containing a newline cannot forge a section" {
    cat > "$QS/quickstart-synthetic.json" <<'EOF'
{
  "schema_version": "2",
  "vendor_short": "synth",
  "api_key_var": "LLM_SYNTHETIC_API_KEY",
  "endpoints": { "openai": "https://api.synthetic.test/openai/v1" },
  "models": [
    { "id": "m1", "description": "ok\n[injected]\nbase_url=https://evil.test/v1",
      "protocols": ["openai"] }
  ]
}
EOF
    _run_quickstart synthetic
    if [ -f "$(_cfg)" ]; then
        run grep -c '^\[injected\]' "$(_cfg)"
        [ "$output" -eq 0 ]
    fi
}

@test "qs validation: a non-http endpoint is rejected" {
    cat > "$QS/quickstart-synthetic.json" <<'EOF'
{
  "schema_version": "2",
  "vendor_short": "synth",
  "api_key_var": "LLM_SYNTHETIC_API_KEY",
  "endpoints": { "openai": "file:///etc/passwd" },
  "models": [ { "id": "m1", "protocols": ["openai"] } ]
}
EOF
    _run_quickstart synthetic
    if [ -f "$(_cfg)" ]; then
        run grep -c 'file:///etc/passwd' "$(_cfg)"
        [ "$output" -eq 0 ]
    fi
}

# ---- diagnostics rather than silence ----

@test "qs: a model with no protocols array is reported, not silently dropped" {
    cat > "$QS/quickstart-synthetic.json" <<'EOF'
{
  "schema_version": "2",
  "vendor_short": "synth",
  "api_key_var": "LLM_SYNTHETIC_API_KEY",
  "endpoints": { "openai": "https://api.synthetic.test/openai/v1" },
  "models": [
    { "id": "has-proto", "protocols": ["openai"] },
    { "id": "no-proto" }
  ]
}
EOF
    _run_quickstart synthetic
    [[ "$output" == *"no-proto"* ]]
}

# ---- post-emit reload ----

@test "qs: emitted providers are visible without re-sourcing" {
    cat > "$QS/quickstart-synthetic.json" <<'EOF'
{
  "schema_version": "2",
  "vendor_short": "synth",
  "api_key_var": "LLM_SYNTHETIC_API_KEY",
  "endpoints": { "openai": "https://api.synthetic.test/openai/v1" },
  "models": [ { "id": "m1", "protocols": ["openai"] } ]
}
EOF
    # cmd_quickstart never re-ran init_config, so the in-memory provider set
    # was stale and _qs_verify_key always reported the brand-new key as failed.
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        LLM_ENV_QUICKSTART_DIR="$QS" bash -c "
            source '$SUT' quickstart synthetic </dev/null >/dev/null 2>&1
            has_provider_key PROVIDER_BASE_URLS openai_synth_m1 && echo VISIBLE || echo STALE
        "
    [[ "$output" == *"VISIBLE"* ]]
}

# ---- the id drift that broke CI on main ----

@test "qs: no hardcoded provider id that the shipped catalog does not contain" {
    # main is red today because the docker E2E hardcodes openai_synth_kimi-k2.5
    # while the scraper renamed that model to kimi-k2.7-code and auto-merged.
    # Any id literal in the source must exist in the shipped JSON.
    local id ids
    # Strip comment lines: prose explaining a previously-hardcoded id is not
    # itself a hardcoded id.
    ids="$(grep -vE '^[[:space:]]*#' "$REPO/llm-env" \
           | grep -oE '(anth|openai)_synth_[A-Za-z0-9._-]+' | sort -u || true)"
    for id in $ids; do
        local model="${id#*_synth_}"
        grep -q "\"id\": \"$model\"" "$REPO/quickstart-synthetic.json" \
            || { echo "llm-env references $id but quickstart-synthetic.json has no model '$model'"; return 1; }
    done
}

@test "qs: the shipped catalog files parse and emit providers" {
    # Guards the daily auto-merge: a scraper change that breaks the schema must
    # fail here rather than silently shipping an unusable catalog.
    run env HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
        LLM_ENV_QUICKSTART_DIR="$REPO" bash -c "source '$SUT' quickstart all </dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" != *"missing required top-level fields"* ]]
    [[ "$output" != *"Quickstart file is empty"* ]]
    local n
    n="$(grep -c '^\[' "$(_cfg)" 2>/dev/null || true)"
    [ "${n:-0}" -gt 10 ]
}
