#!/usr/bin/env bash
# Example shell configuration for LLM Environment Manager
# Add these lines to your ~/.bashrc or ~/.zshrc

# ============================================================================
# LLM Environment Manager Configuration
# ============================================================================

# LLM Environment Manager function
llm_manager() {
    source /usr/local/bin/llm-env "$@"
}

# API Keys - Replace with your actual keys
# Get keys from:
# - Cerebras: https://cloud.cerebras.ai/
# - OpenAI: https://platform.openai.com/api-keys
# - Groq: https://console.groq.com/keys
# - OpenRouter: https://openrouter.ai/keys
export LLM_CEREBRAS_API_KEY="csk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export LLM_OPENAI_API_KEY="sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export LLM_GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export LLM_OPENROUTER_API_KEY="sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Optional: Set a default provider on shell startup
# Uncomment the line below to automatically set a provider when opening a new terminal
# llm_manager set cerebras

# Optional: Model overrides
# Uncomment and modify these to override default models for specific providers
# export OPENAI_MODEL_OVERRIDE="gpt-4o-mini"  # Use this model instead of provider default

# ============================================================================
# Useful Aliases
# ============================================================================

# Quick provider switching aliases
alias llm-cerebras='llm_manager set cerebras'
alias llm-openai='llm_manager set openai'
alias llm-groq='llm_manager set groq'
alias llm-free='llm_manager set openrouter2'  # Free tier
alias llm-status='llm_manager show'
alias llm-list='llm_manager list'
alias llm-reset='llm_manager unset'

# Quick model testing
llm_test() {
    if [[ -z "$OPENAI_API_KEY" ]]; then
        echo "❌ No LLM provider set. Use 'llm_manager set <provider>' first."
        return 1
    fi
    
    echo "Testing current LLM setup..."
    echo "Provider: $LLM_PROVIDER"
    echo "Model: $OPENAI_MODEL"
    echo "Base URL: $OPENAI_BASE_URL"
    echo
    
    # Simple test request
    curl -s -H "Authorization: Bearer $OPENAI_API_KEY" \
         -H "Content-Type: application/json" \
         -d '{"model":"'$OPENAI_MODEL'","messages":[{"role":"user","content":"Say hello in one word"}],"max_tokens":10}' \
         "$OPENAI_BASE_URL/chat/completions" | \
    python3 -c "import sys, json; data=json.load(sys.stdin); print('✅ Response:', data['choices'][0]['message']['content'].strip()) if 'choices' in data else print('❌ Error:', data.get('error', {}).get('message', 'Unknown error'))"
}

# ============================================================================
# Cost-Aware Switching Functions
# ============================================================================

# Switch to free tier when you want to conserve costs
llm_free_tier() {
    echo "🆓 Switching to free tier providers..."
    llm_manager set openrouter2  # DeepSeek free
    echo "💡 Tip: Use 'llm_paid_tier' when you need better performance"
}

# Switch to paid tier for better performance
llm_paid_tier() {
    echo "💰 Switching to paid tier for better performance..."
    llm_manager set cerebras  # Fast and affordable
    echo "💡 Tip: Use 'llm_free_tier' to conserve costs"
}

# Smart switching based on task type
llm_for_coding() {
    echo "💻 Optimizing for coding tasks..."
    llm_manager set cerebras  # qwen-3-coder-480b is great for coding
}

llm_for_speed() {
    echo "⚡ Optimizing for speed..."
    llm_manager set groq  # Fastest inference
}

llm_for_quality() {
    echo "🎯 Optimizing for quality..."
    llm_manager set openai  # Best quality responses
}

# ============================================================================
# Integration Examples
# ============================================================================

# Example function that uses the current LLM provider
ask_llm() {
    if [[ -z "$1" ]]; then
        echo "Usage: ask_llm 'your question here'"
        return 1
    fi
    
    if [[ -z "$OPENAI_API_KEY" ]]; then
        echo "❌ No LLM provider set. Use 'llm_manager set <provider>' first."
        return 1
    fi
    
    echo "🤖 Asking $LLM_PROVIDER ($OPENAI_MODEL)..."
    
    curl -s -H "Authorization: Bearer $OPENAI_API_KEY" \
         -H "Content-Type: application/json" \
         -d '{"model":"'$OPENAI_MODEL'","messages":[{"role":"user","content":"'$1'"}]}' \
         "$OPENAI_BASE_URL/chat/completions" | \
    python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'choices' in data:
        print(data['choices'][0]['message']['content'])
    else:
        print('❌ Error:', data.get('error', {}).get('message', 'Unknown error'))
except Exception as e:
    print('❌ Failed to parse response:', e)
"
}

# Example: Code review function
code_review() {
    if [[ -z "$1" ]]; then
        echo "Usage: code_review <file.py>"
        return 1
    fi
    
    if [[ ! -f "$1" ]]; then
        echo "❌ File not found: $1"
        return 1
    fi
    
    # Switch to coding-optimized provider
    llm_for_coding
    
    echo "🔍 Reviewing code in $1..."
    local code_content
    code_content=$(cat "$1")
    
    ask_llm "Please review this code for bugs, improvements, and best practices:\n\n$code_content"
}

echo "🚀 LLM Environment Manager loaded! Try 'llm_manager list' to get started."