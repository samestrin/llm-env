# LLM Environment Manager

[![Star on GitHub](https://img.shields.io/github/stars/samestrin/llm-env?style=social)](https://github.com/samestrin/llm-env/stargazers) [![Fork on GitHub](https://img.shields.io/github/forks/samestrin/llm-env?style=social)](https://github.com/samestrin/llm-env/network/members) [![Watch on GitHub](https://img.shields.io/github/watchers/samestrin/llm-env?style=social)](https://github.com/samestrin/llm-env/watchers)

![Version 1.1.0](https://img.shields.io/badge/Version-1.1.0-blue) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Built with Bash](https://img.shields.io/badge/Built%20with-Bash-darkblue)](https://www.gnu.org/software/bash/)

A powerful bash script for seamlessly switching between different LLM providers and models. Perfect for developers who work with multiple AI services and need to quickly switch between free tiers, paid models, or different providers based on availability and cost.

**New in v1.1.0:** Enhanced with comprehensive help system, API connectivity testing, configuration backup/restore, bulk operations, and debug mode for easier troubleshooting.

## Overview

Easily manage LLM credentials for any OpenAI compatible provider including OpenAI, OpenRouter, Cerebras, Groq, and more — designed to work with applications that use the emerging `OPENAI_*` environment variable standard. It enables cost management by easily switching from free tiers to paid models when quotas are exhausted. The universal compatibility works with any tool that uses OpenAI-compatible environment variables. API keys are stored securely in your shell profile, never in code. As a pure bash script, it **just works everywhere** with **zero dependencies**.

### Supported Providers

This tool supports any OpenAI API compatible provider, including:

- **OpenAI**: Industry standard GPT models
- **Cerebras**: Fast inference with competitive pricing
- **Groq**: Lightning-fast inference
- **OpenRouter**: Access to multiple models through one API
- **And many more!**


## Installation

### Quick Install

```bash
# Download and install (recommended) - _may need sudo_
curl -fsSL https://raw.githubusercontent.com/samestrin/llm-env/main/install.sh | bash
```

### Manual Install

1. Clone this repository:
   ```bash
   git clone https://github.com/samestrin/llm-env.git
   cd llm-env
   ```

2. Copy the script to your PATH:
   ```bash
   sudo cp llm-env /usr/local/bin/
   sudo chmod +x /usr/local/bin/llm-env
   ```

3. Add the helper function to your shell profile (`~/.bashrc` or `~/.zshrc`):
   ```bash
   # LLM Environment Manager
   llm-env() {
     source /usr/local/bin/llm-env "$@"
   }
   ```

4. Set up your API keys in your shell profile:
   ```bash
   # Add these to ~/.bashrc or ~/.zshrc
   export LLM_CEREBRAS_API_KEY="your_cerebras_key_here"
   export LLM_OPENAI_API_KEY="your_openai_key_here"
   export LLM_GROQ_API_KEY="your_groq_key_here"
   export LLM_OPENROUTER_API_KEY="your_openrouter_key_here"
   ```

5. Reload your shell:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

## Usage

### Basic Commands

```bash
# List all available providers
llm-env list

# Set a provider (switches all OpenAI-compatible env vars)
llm-env set cerebras
llm-env set openai
llm-env set groq

# Show current configuration
llm-env show

# Unset all LLM environment variables
llm-env unset

# Get help
llm-env --help

# Test provider connectivity
llm-env test cerebras
```

### Example Workflow

```bash
# Start with free tier
llm-env set openrouter2  # Uses deepseek free model (if you are using the default config)

# When free tier is exhausted, switch to paid
llm-env set cerebras     # Fast and affordable

# For specific tasks, use specialized models
llm-env set groq         # For speed
llm-env set openai       # For quality
```

### Integration Examples

Once you've set a provider, any tool using OpenAI-compatible environment variables will work:

```bash
# With curl
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"'$OPENAI_MODEL'","messages":[{"role":"user","content":"Hello!"}]}' \
     $OPENAI_BASE_URL/chat/completions
```

```python
# With Python OpenAI client
python -c "import openai; print(openai.chat.completions.create(model=os.environ['OPENAI_MODEL'], messages=[{'role':'user','content':'Hello!'}]))"
```

# With **any** LLM CLI tool that supports the OpenAI API Environment Variables
```bash
qwen -p "What is the capital of France?"  # Uses current provider automatically
```

### Common Use Cases

#### 1. Development Workflow
```bash
# Use free tier for testing
llm-env set openrouter3  # qwen free model

# Switch to paid when deploying
llm-env set cerebras     # Fast and reliable
```

#### 2. Cost Optimization
```bash
# Start with cheapest option
llm-env set openrouter2  # Free deepseek

# Escalate based on needs
llm-env set groq         # When speed matters
llm-env set openai       # When quality is critical
```

#### 3. Provider Redundancy
```bash
# Primary provider down? Switch instantly
llm-env set cerebras
# If cerebras is down:
llm-env set groq
```

## Configuration

The script uses a flexible configuration system that allows you to customize providers and models without modifying the script itself.

### Quick Setup
```bash
# Create a user configuration file
source llm-env config init

# Edit your configuration
source llm-env config edit
```

### Configuration Management
```bash
# Add a new provider
source llm-env config add my-provider

# Validate configuration
source llm-env config validate

# Backup configuration
source llm-env config backup

# Restore from backup
source llm-env config restore /path/to/backup.conf

# Bulk operations
source llm-env config bulk enable cerebras openai
source llm-env config bulk disable groq openrouter
```

📖 **For detailed configuration options, examples, and advanced setup, see the [Configuration Guide](docs/configuration.md)**

## Troubleshooting

### Quick Diagnostics
```bash
# Verify setup
llm-env list
llm-env show

# Test API connectivity
llm-env test cerebras

# Enable debug mode for detailed troubleshooting
LLM_ENV_DEBUG=1 llm-env list

# Or manual test
curl -H "Authorization: Bearer $OPENAI_API_KEY" $OPENAI_BASE_URL/models
```

**For detailed troubleshooting, common issues, and solutions, see the [Troubleshooting Guide](docs/troubleshooting.md)**

## Documentation

**Complete documentation is available in the [docs](docs/) directory:**

- [Configuration Guide](docs/configuration.md) - Detailed setup and customization
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions
- [Development Guide](docs/development.md) - Contributing and development
- [Compatible Tools](docs/comprehensive.md) - Applications that work with llm-env

## Testing

**Comprehensive test suite ensures reliability across platforms and Bash versions:**

### Running Tests

```bash
# Run all tests
./tests/run_tests.sh

# Run specific test suites
./tests/run_tests.sh --unit-only
./tests/run_tests.sh --integration-only
./tests/run_tests.sh --system-only

# Run individual test files
bats tests/unit/test_validation.bats
bats tests/integration/test_providers.bats
```

### Test Structure

- **Unit Tests** (`tests/unit/`) - Core functionality and validation
- **Integration Tests** (`tests/integration/`) - Provider management and configuration
- **System Tests** (`tests/system/`) - Cross-platform compatibility and edge cases
- **Regression Tests** - Prevent known issues from reoccurring

### Current Test Results

**All test suites passing** across supported platforms:
- **Unit Tests**: 40/40 passing
- **Integration Tests**: 13/13 passing  
- **System Tests**: 40/40 passing
- **Total Coverage**: 93 test cases

**Platform Support:**
- macOS (Bash 3.2+ and 5.x)
- Ubuntu/Linux (Bash 4.0+)
- Multi-version compatibility testing

### Test Requirements

- [BATS](https://github.com/bats-core/bats-core) testing framework
- Bash 3.2+ (automatically tested across versions)
- No external dependencies required for basic tests

## Contributing

Contributions are welcome! See the [Development Guide](docs/development.md) for details on:

- Adding new providers
- Improving functionality
- Testing and validation
- Code style guidelines

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Related Tools

This tool works great with:

- [llm](https://github.com/simonw/llm) - Simon Willison's LLM CLI
- [aider](https://github.com/paul-gauthier/aider) - AI pair programming
- [LiteLLM](https://github.com/BerriAI/litellm) - A library to simplify calling all LLM APIs
- [LangChain](https://github.com/langchain-ai/langchain) - A framework for building LLM applications

It's also great with CLI coding tools, I use i with [qwen-code](https://github.com/QwenLM/qwen-code) + [qwen-prompts](https://github.com/samestrin/qwen-prompts), a collection of "hybrid prompt chaining" slash prompts, but it will work with **any tool that uses OpenAI-compatible APIs using Environmental Variables**.

Additional: [Applications, Scripts, and Frameworks compatible with llm-env](docs/comprehensive.md)

## Share

[![Twitter](https://img.shields.io/badge/X-Tweet-blue)](https://twitter.com/intent/tweet?text=Check%20out%20this%20LLM%20Environment%20Manager!&url=https://github.com/samestrin/llm-env) [![Facebook](https://img.shields.io/badge/Facebook-Share-blue)](https://www.facebook.com/sharer/sharer.php?u=https://github.com/samestrin/llm-env) [![LinkedIn](https://img.shields.io/badge/LinkedIn-Share-blue)](https://www.linkedin.com/sharing/share-offsite/?url=https://github.com/samestrin/llm-env)