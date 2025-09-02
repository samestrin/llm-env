# LLM Environment Manager - Usage Scenarios

This document provides real-world examples of how to use the LLM Environment Manager effectively.

> **Note**: The examples in this document reference providers defined in the default configuration file: [`config/llm-env.conf`](../config/llm-env.conf). You can customize these providers or add your own by creating `~/.config/llm-env/config.conf`.

## Scenario 1: Daily Development Workflow

### Morning Setup
```bash
# Check what providers you have configured
llm-env list

# Start with an OpenRouter free tier for light tasks
llm-env set openrouter2  # DeepSeek free model

# Verify setup
llm-env show
```

### When Free Tier Runs Out
```bash
# Switch to affordable paid option
llm-env set cerebras

# Or if you need maximum speed
llm-env set groq
```

### End of Day Cleanup
```bash
# Clear environment variables
llm-env unset
```

## Scenario 2: Cost-Conscious Development

### Strategy: Start Free, Escalate as Needed

```bash
# 1. Start with completely free options
llm-env set openrouter3  # Qwen free

# 2. When free quota exhausted, move to cheap options
llm-env set cerebras     # Very affordable

# 3. For critical tasks, use premium
llm-env set openai       # Best quality

# 4. For speed-critical tasks
llm-env set groq         # Fastest inference
```

### Monthly Budget Tracking
```bash
# Create a simple usage log
echo "$(date): Switched to $LLM_PROVIDER" >> ~/llm-usage.log

# Review your usage patterns
tail -20 ~/llm-usage.log
```

## Scenario 3: Team Development

### Shared Configuration
```bash
# Team lead sets up standard configuration
cat > team-llm-config.sh << 'EOF'
#!/bin/bash
# Team LLM Configuration

# Standard providers for the team
export LLM_CEREBRAS_API_KEY="team_cerebras_key"
export LLM_GROQ_API_KEY="team_groq_key"

# Default to cost-effective option
llm-env set cerebras
echo "✅ Team LLM environment loaded (cerebras)"
EOF

# Team members source this file
source team-llm-config.sh
```

### Environment Switching for Different Tasks
```bash
# Code review (needs good reasoning)
llm-env set openai
git diff HEAD~1 | llm "Review this code change"

# Quick documentation (speed matters)
llm-env set groq
llm "Write a brief README for this function: $(cat utils.py)"

# Bulk processing (cost matters)
llm-env set openrouter2
for file in *.py; do
    llm "Summarize this file: $(cat $file)" > "$file.summary"
done
```

## Scenario 4: CI/CD Integration

### GitHub Actions Example
```yaml
# .github/workflows/ai-review.yml
name: AI Code Review
on: [pull_request]

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup LLM Environment
        run: |
          curl -o llm-env https://raw.githubusercontent.com/samestrin/llm-env/main/llm-env
          chmod +x llm-env
          echo 'llm-env() { source ./llm-env "$@"; }' >> ~/.bashrc
          source ~/.bashrc
        
      - name: AI Code Review
        env:
          LLM_CEREBRAS_API_KEY: ${{ secrets.CEREBRAS_API_KEY }}
        run: |
          llm-env set cerebras
          git diff origin/main...HEAD | llm "Review this code change"
```

### Docker Integration
```dockerfile
# Dockerfile
FROM ubuntu:22.04

# Install LLM Environment Manager
RUN curl -o /usr/local/bin/llm-env https://raw.githubusercontent.com/samestrin/llm-env/main/llm-env && \
    chmod +x /usr/local/bin/llm-env

# Add to shell profile
RUN echo 'llm-env() { source /usr/local/bin/llm-env "$@"; }' >> ~/.bashrc

# Your app code
COPY . /app
WORKDIR /app

# Use LLM in your application
CMD ["bash", "-c", "source ~/.bashrc && llm-env set cerebras && python app.py"]
```

## Scenario 5: Multi-Project Management

### Project-Specific Configurations
```bash
# Project A: High-quality documentation
cd ~/projects/important-client
echo 'llm-env set openai' > .llmrc
echo 'echo "📚 Using premium LLM for documentation"' >> .llmrc

# Project B: Rapid prototyping
cd ~/projects/prototype
echo 'llm-env set groq' > .llmrc
echo 'echo "⚡ Using fast LLM for prototyping"' >> .llmrc

# Project C: Cost-sensitive
cd ~/projects/personal
echo 'llm-env set openrouter2' > .llmrc
echo 'echo "💰 Using free LLM for personal project"' >> .llmrc
```

### Auto-switching on Directory Change
```bash
# Add to ~/.bashrc or ~/.zshrc
cd() {
    builtin cd "$@"
    if [[ -f .llmrc ]]; then
        echo "🔄 Loading project LLM configuration..."
        source .llmrc
    fi
}
```

## Scenario 6: Provider Redundancy

### Automatic Fallback
```bash
# Smart switching function
llm_smart_set() {
    local providers=("cerebras" "groq" "openrouter")
    
    for provider in "${providers[@]}"; do
        echo "🔄 Trying $provider..."
        if llm-env set "$provider" 2>/dev/null; then
            # Test with a simple request
            if curl -s -f -H "Authorization: Bearer $OPENAI_API_KEY" \
                    "$OPENAI_BASE_URL/models" >/dev/null; then
                echo "✅ Successfully connected to $provider"
                return 0
            fi
        fi
    done
    
    echo "❌ All providers failed"
    return 1
}
```

### Health Check Script
```bash
#!/bin/bash
# llm-health-check.sh

echo "🏥 LLM Provider Health Check"
echo "============================="

for provider in cerebras openai groq openrouter; do
    echo -n "$provider: "
    
    if llm-env set "$provider" 2>/dev/null; then
        if timeout 10 curl -s -f -H "Authorization: Bearer $OPENAI_API_KEY" \
                "$OPENAI_BASE_URL/models" >/dev/null 2>&1; then
            echo "✅ Healthy"
        else
            echo "❌ Unhealthy (API error)"
        fi
    else
        echo "❌ Not configured"
    fi
done

llm-env unset
```

## Scenario 7: Integration with Popular Tools

### With Simon Willison's LLM CLI
```bash
# Install llm if you haven't already
# See: https://llm.datasette.io/en/stable/setup.html
pip install llm

# Use with different providers
llm-env set cerebras
llm "Explain this code: $(cat script.py)"

llm-env set groq
llm "Translate this to Spanish: Hello world"
```

### With Aider (AI Pair Programming)
```bash
# Set provider before using aider
llm-env set cerebras
aider --model $OPENAI_MODEL --api-base $OPENAI_BASE_URL

# Or create a wrapper script
cat > aider-cerebras << 'EOF'
#!/bin/bash
llm-env set cerebras
aider --model $OPENAI_MODEL --api-base $OPENAI_BASE_URL "$@"
EOF
chmod +x aider-cerebras
```

### With Custom Python Scripts
```python
#!/usr/bin/env python3
# ai-helper.py
import os
import openai

# The environment is already set by llm-env
client = openai.OpenAI(
    api_key=os.environ['OPENAI_API_KEY'],
    base_url=os.environ['OPENAI_BASE_URL']
)

def ask_ai(question):
    response = client.chat.completions.create(
        model=os.environ['OPENAI_MODEL'],
        messages=[{"role": "user", "content": question}]
    )
    return response.choices[0].message.content

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        print(ask_ai(" ".join(sys.argv[1:])))
    else:
        print("Usage: python ai-helper.py 'your question'")
```

```bash
# Use the Python script with different providers
llm-env set cerebras
python ai-helper.py "What's the weather like?"

llm-env set groq
python ai-helper.py "Write a haiku about coding"
```

## Tips for Effective Usage

1. **Start Free**: Always begin with free tiers for testing
2. **Monitor Costs**: Keep track of which providers you're using
3. **Task-Specific Switching**: Use fast providers for bulk tasks, quality providers for important work
4. **Backup Plans**: Always have multiple providers configured
5. **Team Coordination**: Establish team standards for provider usage
6. **Automation**: Use scripts to automatically switch based on context

## Troubleshooting Common Issues

### Provider Not Working
```bash
# Check configuration
llm-env show

# Test API connectivity
curl -H "Authorization: Bearer $OPENAI_API_KEY" "$OPENAI_BASE_URL/models"

# Try different provider
llm-env set groq
```

### Rate Limits
```bash
# Switch to different provider when rate limited
echo "Rate limited on $LLM_PROVIDER, switching..."
llm-env set cerebras  # or another provider
```

### API Key Issues
```bash
# Verify API keys are set
llm-env list

# Check specific key
echo "Cerebras key: ${LLM_CEREBRAS_API_KEY:0:10}..."
```
