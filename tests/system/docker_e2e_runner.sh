#!/usr/bin/env bash
#
# docker_e2e_runner.sh — orchestrates an end-to-end test of llm-env inside
# a fresh Ubuntu container. This runs the actual install path on a clean
# Linux box (default bash 5.x, no shell tools beyond curl), exercises
# `quickstart`, `list`, and `set`, and optionally validates a live API
# call against the synthetic endpoint.
#
# Usage:
#   tests/system/docker_e2e_runner.sh [--with-live-api]
#
# Exit codes:
#   0   all checks passed
#   2   docker unavailable (caller should skip rather than fail)
#   1   real test failure
#
# Env vars:
#   LLM_SYNTHETIC_API_KEY   passed to the container for live API tests
#   LLM_ENV_DOCKER_IMAGE    override default (ubuntu:22.04)
#   LLM_ENV_DOCKER_KEEP     keep container/HOME on exit for debugging

set -euo pipefail

WITH_LIVE_API=false
[[ "${1:-}" == "--with-live-api" ]] && WITH_LIVE_API=true

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE="${LLM_ENV_DOCKER_IMAGE:-ubuntu:22.04}"

# --- pre-flight ----------------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
    echo "docker not installed; skipping" >&2
    exit 2
fi

if ! docker info >/dev/null 2>&1; then
    echo "docker daemon not reachable; skipping" >&2
    exit 2
fi

# --- run ----------------------------------------------------------------

# A single shell script run inside the container. Composed inline so
# the parent runner stays self-contained (no extra files to mount).
read -r -d '' CONTAINER_SCRIPT <<'EOF' || true
set -euo pipefail

echo "::: container OS info :::"
. /etc/os-release && echo "$PRETTY_NAME"
echo "bash: $BASH_VERSION"

echo "::: installing curl + python3 :::"
DEBIAN_FRONTEND=noninteractive apt-get update -qq
# python3 is only used by the test harness to compute expected
# section counts from the source JSONs; llm-env itself has no
# python dependency.
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl python3

# Copy mounted source to a writable location (install.sh writes
# adjacent files during quickstart).
cp -r /repo /tmp/llm-env-src
cd /tmp/llm-env-src

echo "::: installing llm-env via install.sh --offline :::"
export INSTALL_DIR=/tmp/llm-env-install
mkdir -p "$INSTALL_DIR"
# The installer hard-codes /usr/local/bin in places; rewrite for an
# unprivileged install path.
sed "s|/usr/local/bin|$INSTALL_DIR|g" install.sh > /tmp/install-patched.sh
chmod +x /tmp/install-patched.sh
/tmp/install-patched.sh --offline ./llm-env </dev/null

test -x "$INSTALL_DIR/llm-env"
"$INSTALL_DIR/llm-env" --version

echo "::: running quickstart against an isolated HOME :::"
export HOME=/tmp/test-home
export XDG_CONFIG_HOME="$HOME/.config"
mkdir -p "$XDG_CONFIG_HOME"

# Point cmd_quickstart at the JSONs in the source tree (the installed
# script lives in INSTALL_DIR but the JSONs do not).
export LLM_ENV_QUICKSTART_DIR=/tmp/llm-env-src
"$INSTALL_DIR/llm-env" quickstart >/tmp/quickstart.log 2>&1 || {
    echo "quickstart FAILED:"
    cat /tmp/quickstart.log
    exit 1
}

# Count emitted sections, and compare against the *expected* counts
# computed from the source JSONs (so the test self-adapts as the
# daily scraper adds/removes models or shifts protocol availability).
config="$XDG_CONFIG_HOME/llm-env/config.conf"
provider_count=$(grep -cE '^\[(openai|anth)_' "$config")
group_count=$(grep -cE '^\[group:' "$config")

# Use python (preinstalled in ubuntu:22.04) to compute expected counts.
read -r expected_providers expected_groups < <(python3 - <<'PY' /tmp/llm-env-src
import json, sys
root = sys.argv[1]
total_providers = 0
total_groups = 0
for name in ("quickstart-synthetic.json", "quickstart-alibaba.json"):
    with open(f"{root}/{name}") as f:
        data = json.load(f)
    for m in data["models"]:
        # One [protocol_vendor_id] section per (model, protocol) pair.
        total_providers += len(m["protocols"])
        # One per-model group only when both protocols available.
        if "openai" in m["protocols"] and "anthropic" in m["protocols"]:
            total_groups += 1
    # One family-latest group per family (always emitted; degrades to
    # single-member when latest model has only one protocol).
    total_groups += len(data["family_latest"])
print(total_providers, total_groups)
PY
)

echo "providers emitted: $provider_count (expected $expected_providers)"
echo "groups emitted:    $group_count (expected $expected_groups)"

[[ "$provider_count" -eq "$expected_providers" ]] || {
    echo "FAIL: provider count mismatch"
    exit 1
}
[[ "$group_count" -eq "$expected_groups" ]] || {
    echo "FAIL: group count mismatch"
    exit 1
}

echo "::: list shows new providers :::"
"$INSTALL_DIR/llm-env" list >/tmp/list.log 2>&1 || true
grep -q 'openai_synth_kimi-k2.5' /tmp/list.log || {
    echo "FAIL: openai_synth_kimi-k2.5 not in list output"
    cat /tmp/list.log
    exit 1
}
grep -q 'anth_synth_kimi-k2.5' /tmp/list.log || {
    echo "FAIL: anth_synth_kimi-k2.5 not in list output"
    cat /tmp/list.log
    exit 1
}

echo "::: source set synth_kimi-k2.5 activates both protocols :::"
# Use a fake key for the offline check; live API call comes later.
export LLM_SYNTHETIC_API_KEY="${LLM_SYNTHETIC_API_KEY:-test-fake-key}"

# Source set inside a sub-shell to capture exported vars.
output=$(bash -c "
    source $INSTALL_DIR/llm-env set synth_kimi-k2.5 >/dev/null 2>&1
    echo openai=\$OPENAI_BASE_URL
    echo anthropic=\$ANTHROPIC_BASE_URL
    echo provider=\$LLM_PROVIDER
")
echo "$output"
echo "$output" | grep -q '^openai=https://api.synthetic.new/openai/v1$' || {
    echo "FAIL: OPENAI_BASE_URL not set"
    exit 1
}
echo "$output" | grep -q '^anthropic=https://api.synthetic.new/anthropic/v1$' || {
    echo "FAIL: ANTHROPIC_BASE_URL not set"
    exit 1
}
echo "$output" | grep -q 'openai_synth_kimi-k2.5,anth_synth_kimi-k2.5' || {
    echo "FAIL: LLM_PROVIDER did not contain both providers"
    exit 1
}

echo "::: family-latest alias resolves :::"
output=$(bash -c "
    source $INSTALL_DIR/llm-env set synth_glm >/dev/null 2>&1
    echo model=\$OPENAI_MODEL
")
echo "$output"
# We don't pin the exact id (scraper may shift latest) but it must be a glm
echo "$output" | grep -qiE '^model=.*glm' || {
    echo "FAIL: synth_glm did not resolve to a glm model"
    exit 1
}

if [[ "${LLM_ENV_WITH_LIVE_API:-false}" == "true" ]]; then
    echo "::: LIVE API: running llm-env test against openai_synth_kimi-k2.5 :::"
    if [[ -z "${LLM_SYNTHETIC_API_KEY:-}" || "$LLM_SYNTHETIC_API_KEY" == "test-fake-key" ]]; then
        echo "SKIP: live API requested but no real LLM_SYNTHETIC_API_KEY"
    else
        bash -c "
            source $INSTALL_DIR/llm-env set openai_synth_kimi-k2.5 >/dev/null 2>&1
            $INSTALL_DIR/llm-env test openai_synth_kimi-k2.5
        " || {
            echo "FAIL: live API test failed"
            exit 1
        }
    fi
fi

echo "::: ALL CHECKS PASSED :::"
EOF

# --- spawn ---------------------------------------------------------------

DOCKER_ARGS=(
    --rm
    -v "$REPO_ROOT:/repo:ro"
    -e "LLM_ENV_WITH_LIVE_API=$WITH_LIVE_API"
)

if [[ "$WITH_LIVE_API" == "true" && -n "${LLM_SYNTHETIC_API_KEY:-}" ]]; then
    DOCKER_ARGS+=(-e "LLM_SYNTHETIC_API_KEY=$LLM_SYNTHETIC_API_KEY")
fi

if [[ "${LLM_ENV_DOCKER_KEEP:-}" == "1" ]]; then
    # Drop --rm so the container persists for inspection.
    DOCKER_ARGS=("${DOCKER_ARGS[@]/--rm/}")
fi

docker run "${DOCKER_ARGS[@]}" "$IMAGE" bash -c "$CONTAINER_SCRIPT"
