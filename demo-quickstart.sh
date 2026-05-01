#!/usr/bin/env bash
# demo-quickstart.sh - Demo script for llm-env quickstart integration
#
# This script demonstrates:
#   1. One-command provider setup via `llm-env quickstart`
#   2. Setting providers from Synthetic and Alibaba Coding Plan
#   3. Testing API connectivity
#   4. Making a live API call
#
# Prerequisites:
#   - llm-env installed (https://github.com/samestrin/llm-env)
#   - At least one API key set:
#       export LLM_SYNTHETIC_API_KEY='your-synthetic-key'
#       export LLM_ALIBABA_API_KEY='your-alibaba-key'
#
# Usage:
#   bash demo-quickstart.sh              # Run full demo
#   bash demo-quickstart.sh --cleanup    # Restore original config

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_CONFIG="${XDG_CONFIG_HOME:-${HOME}/.config}/llm-env/config.conf"
BACKUP_CONFIG="${USER_CONFIG}.demo-backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

step() {
    echo -e "${GREEN}▶ $1${NC}"
    echo
}

pause() {
    echo
    echo -e "${YELLOW}  Press Enter to continue...${NC}"
    read -r
    echo
}

cleanup() {
    if [[ -f "$BACKUP_CONFIG" ]]; then
        mv "$BACKUP_CONFIG" "$USER_CONFIG"
        echo -e "${GREEN}Restored original configuration from backup.${NC}"
    else
        echo -e "${YELLOW}No backup found at $BACKUP_CONFIG${NC}"
    fi
}

# Handle --cleanup flag
if [[ "${1:-}" == "--cleanup" ]]; then
    cleanup
    exit 0
fi

banner "llm-env Quickstart Demo"

echo -e "This demo shows how ${BOLD}llm-env quickstart${NC} adds providers from"
echo -e "${BOLD}Synthetic${NC} and the ${BOLD}Alibaba Cloud Coding Plan${NC} in one command."
echo
echo -e "Providers added by quickstart:"
echo -e "  ${BLUE}Synthetic:${NC}     MiniMax-M2.5, GLM-5, Kimi-K2.5"
echo -e "  ${BLUE}Alibaba:${NC}       qwen3.5-plus, kimi-k2.5, glm-5, MiniMax-M2.5"
echo
echo -e "Referral code ${BOLD}LLMENV_QUICKSTART${NC} is shown automatically."

pause

# ── Step 1: Backup existing config ──────────────────────────────

banner "Step 1: Backup Existing Configuration"

if [[ -f "$USER_CONFIG" ]]; then
    cp "$USER_CONFIG" "$BACKUP_CONFIG"
    step "Backed up existing config to $BACKUP_CONFIG"
    rm "$USER_CONFIG"
    step "Removed existing config for clean demo"
else
    step "No existing config found - starting fresh"
fi

pause

# ── Step 2: Run quickstart ──────────────────────────────────────

banner "Step 2: Run Quickstart"

step "Running: llm-env quickstart"
echo -e "${YELLOW}--- quickstart output ---${NC}"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/llm-env" quickstart
echo -e "${YELLOW}--- end output ---${NC}"

pause

# ── Step 3: List providers ──────────────────────────────────────

banner "Step 3: List Available Providers"

step "Running: llm-env list"
echo -e "${YELLOW}--- list output ---${NC}"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/llm-env" list
echo -e "${YELLOW}--- end output ---${NC}"

pause

# ── Step 4: Set a provider and test ─────────────────────────────

banner "Step 4: Set Provider & Test Connectivity"

# Pick a provider based on available keys (schema v2 names)
DEMO_PROVIDER=""
if [[ -n "${LLM_ALIBABA_API_KEY:-}" ]]; then
    DEMO_PROVIDER="openai_alibaba_qwen3.6-plus"
elif [[ -n "${LLM_SYNTHETIC_API_KEY:-}" ]]; then
    DEMO_PROVIDER="openai_synth_minimax-m2.5"
fi

if [[ -n "$DEMO_PROVIDER" ]]; then
    step "Running: llm-env set $DEMO_PROVIDER"
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/llm-env" set "$DEMO_PROVIDER"

    echo
    step "Running: llm-env show"
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/llm-env" show

    pause

    step "Running: llm-env test $DEMO_PROVIDER"
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/llm-env" test "$DEMO_PROVIDER" || true

    pause

    # ── Step 5: Live API call ───────────────────────────────────

    banner "Step 5: Live API Call"

    step "Making a chat completion request..."
    echo -e "  Model:    ${BOLD}$OPENAI_MODEL${NC}"
    echo -e "  Endpoint: ${BOLD}$OPENAI_BASE_URL${NC}"
    echo

    RESPONSE=$(curl -s "$OPENAI_BASE_URL/chat/completions" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "'"$OPENAI_MODEL"'",
            "messages": [{"role": "user", "content": "In one sentence, what makes you a good coding assistant?"}],
            "max_tokens": 100
        }' 2>&1) || true

    echo -e "${YELLOW}--- API response ---${NC}"
    if command -v python3 >/dev/null 2>&1; then
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    else
        echo "$RESPONSE"
    fi
    echo -e "${YELLOW}--- end response ---${NC}"
else
    echo -e "${RED}No API keys found. Set one of:${NC}"
    echo "  export LLM_ALIBABA_API_KEY='sk-sp-your-key'"
    echo "  export LLM_SYNTHETIC_API_KEY='your-key'"
    echo
    echo -e "${YELLOW}Skipping set/test/API call steps.${NC}"
fi

pause

# ── Step 6: Idempotency check ──────────────────────────────────

banner "Step 6: Idempotency Check (Run Quickstart Again)"

step "Running quickstart a second time..."
echo -e "${YELLOW}--- quickstart output ---${NC}"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/llm-env" quickstart
echo -e "${YELLOW}--- end output ---${NC}"

pause

# ── Cleanup ─────────────────────────────────────────────────────

banner "Demo Complete"

echo -e "Summary:"
echo -e "  ${GREEN}✓${NC} Quickstart added providers in one command"
echo -e "  ${GREEN}✓${NC} Referral code LLMENV_QUICKSTART displayed automatically"
echo -e "  ${GREEN}✓${NC} Providers work with standard OpenAI-compatible tools"
echo -e "  ${GREEN}✓${NC} Idempotent - safe to run multiple times"
echo

if [[ -f "$BACKUP_CONFIG" ]]; then
    echo -e "To restore your original config:"
    echo -e "  ${BOLD}bash $SCRIPT_DIR/demo-quickstart.sh --cleanup${NC}"
    echo
fi

echo -e "Learn more: ${BOLD}https://github.com/samestrin/llm-env${NC}"
echo
