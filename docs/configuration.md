# Configuration Guide

This guide provides comprehensive information about configuring LLM Environment Manager for your specific needs.

## Configuration System Overview

The script uses a flexible configuration system that allows you to customize providers and models without modifying the script itself. This enables:

- **Custom Providers**: Add your own LLM providers
- **Model Overrides**: Change default models for existing providers
- **Provider Customization**: Modify base URLs, API key variables, and descriptions
- **Provider Management**: Enable/disable providers as needed

## Configuration File Precedence

Configuration files are loaded in this order of precedence (first found wins):

1. `~/.config/llm-env/config.conf` (user-specific)
2. `/usr/local/etc/llm-env/config.conf` (system-wide)
3. `./config/llm-env.conf` (bundled defaults)

## Quick Setup

### Interactive Configuration

```bash
# Create a user configuration file
llm-env config init

# Edit your configuration
llm-env config edit
```

### Manual Configuration

Create `~/.config/llm-env/config.conf` with your custom settings:

```bash
# Create the directory
mkdir -p ~/.config/llm-env

# Create your configuration file
touch ~/.config/llm-env/config.conf
```

## Configuration Format

The configuration uses INI format with sections for each provider:

```ini
[provider_name]
base_url=https://api.example.com/v1
api_key_var=LLM_PROVIDER_API_KEY
default_model=model-name
description=Provider description
protocol=openai
enabled=true
```

### Configuration Fields

- **base_url**: The API endpoint URL
- **api_key_var**: Environment variable name for the API key
- **default_model**: Default model to use with this provider
- **description**: Human-readable description
- **enabled**: Whether this provider is available (true/false)
- **protocol**: API protocol type - `openai` (default) or `anthropic`

### Protocol Support

By default, all providers use the OpenAI protocol, exporting `OPENAI_*` environment variables. For providers that use the Anthropic API natively (like Anthropic Claude), you can set `protocol=anthropic` to export native `ANTHROPIC_*` variables instead.

**OpenAI Protocol (default):**
- Exports: `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`
- Uses: `Authorization: Bearer <key>` header

**Anthropic Protocol:**
- Exports: `ANTHROPIC_API_KEY`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_MODEL`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_DEFAULT_OPUS_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`, `ANTHROPIC_DEFAULT_HAIKU_MODEL`, `CLAUDE_CODE_SUBAGENT_MODEL`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`
- Uses: `x-api-key: <key>` and `anthropic-version: 2023-06-01` headers

## Configuration Examples

### Adding a Custom Provider

```ini
# Local Ollama instance
[ollama]
base_url=http://localhost:11434/v1
api_key_var=LLM_OLLAMA_API_KEY
default_model=llama3.2:latest
description=Local Ollama instance
enabled=true

# Custom OpenAI-compatible service
[my-service]
base_url=https://my-llm-service.com/v1
api_key_var=LLM_MYSERVICE_API_KEY
default_model=custom-model-v1
description=My custom LLM service
enabled=true
```

### Configuring Anthropic (Native Protocol)

For direct Anthropic API access with native `ANTHROPIC_*` environment variables:

```ini
# Anthropic Claude - Native API
[anthropic]
base_url=https://api.anthropic.com/v1
api_key_var=LLM_ANTHROPIC_API_KEY
default_model=claude-sonnet-4-20250514
protocol=anthropic
description=Anthropic Claude with native API
enabled=true
```

When you run `llm-env set anthropic`, this exports:
- `ANTHROPIC_API_KEY` - Your API key
- `ANTHROPIC_BASE_URL` - https://api.anthropic.com/v1
- `ANTHROPIC_MODEL` - claude-sonnet-4-20250514
- `ANTHROPIC_DEFAULT_OPUS_MODEL` - Model for opus plan mode (defaults to main model)
- `ANTHROPIC_DEFAULT_SONNET_MODEL` - Model for most tasks (defaults to main model)
- `ANTHROPIC_DEFAULT_HAIKU_MODEL` - Model primarily used for summarization (defaults to main model)
- `CLAUDE_CODE_SUBAGENT_MODEL` - Model to use when starting subagents (defaults to main model)
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` - Flag to reduce non-essential API traffic (defaults to false)

The `llm-env test anthropic` command uses proper Anthropic authentication headers (`x-api-key` and `anthropic-version`).

### Provider Groups

Groups let you set multiple providers with a single command. This is useful when tools need both `OPENAI_*` and `ANTHROPIC_*` variables simultaneously (e.g., Claude Code using Anthropic for chat but an OpenAI-compatible provider for embeddings).

```ini
# Define a group with [group:name] syntax
[group:default]
providers=cerebras,anthropic

[group:dev]
providers=groq,anthropic
```

Usage:
```bash
# Set all providers in the "default" group
llm-env set default

# Or use comma-separated providers directly (no config needed)
llm-env set cerebras,anthropic
```

Each provider in the group sets its own protocol's variables. For example, if `cerebras` uses `openai` protocol and `anthropic` uses `anthropic` protocol, both `OPENAI_*` and `ANTHROPIC_*` variables are set.

Groups appear in `llm-env list` output:
```
Provider groups:

   default       → cerebras,anthropic
   dev           → groq,anthropic
```

### Quickstart JSON Schema (v2)

The `llm-env quickstart` command reads two curated JSON files at the top of the repository — `quickstart-synthetic.json` and `quickstart-alibaba.json` — and emits provider and group sections into your user config. The files follow schema v2; the parser refuses anything missing `schema_version: "2"`.

#### What gets emitted

For each model in the JSON, the parser writes up to two provider sections plus a group binding them, using the naming scheme `<protocol>_<vendor-short>_<model>`:

```ini
[openai_synth_kimi-k2.5]
base_url=https://api.synthetic.new/openai/v1
api_key_var=LLM_SYNTHETIC_API_KEY
default_model=hf:moonshotai/Kimi-K2.5
description=Kimi K2.5 from synthetic.new
enabled=true

[anth_synth_kimi-k2.5]
base_url=https://api.synthetic.new/anthropic/v1
api_key_var=LLM_SYNTHETIC_API_KEY
default_model=hf:moonshotai/Kimi-K2.5
protocol=anthropic
description=Kimi K2.5 from synthetic.new
enabled=true

[group:synth_kimi-k2.5]
providers=openai_synth_kimi-k2.5,anth_synth_kimi-k2.5
```

A model only gets a per-model group if both protocols are available for it. Where only one protocol is exposed, only that protocol's provider is emitted (no group).

#### Family-latest aliases

The JSON also carries a `family_latest` map, keyed by *effective family*. An effective family is the family name plus an optional subtype (e.g., `glm`, `glm-flash`, `qwen-coder`, `qwen-thinking`, `deepseek-r`). Each entry produces a group section that resolves to whichever model is currently latest in that family:

```ini
[group:synth_glm]
providers=openai_synth_glm-5.1,anth_synth_glm-5.1

[group:synth_qwen-coder]
providers=openai_synth_qwen3-coder-480b-a35b-instruct,anth_synth_qwen3-coder-480b-a35b-instruct
```

So `llm-env set synth_glm` always points at the newest GLM, even when the daily refresh promotes a new version.

#### Where the JSONs come from

The files are produced by `scripts/update_quickstart.py`, which runs daily via `.github/workflows/update-quickstart.yml`. It:

1. Fetches the synthetic `/openai/v1/models` endpoint and the Alibaba Coding Plan docs page (the latter via a reader proxy, since Alibaba's CDN aggressively caches stale content).
2. Classifies each model by family / version / subtype.
3. Suppresses quantization variants (e.g., `-NVFP4`, `-FP8`) so each base model appears once.
4. Probes each Synthetic model against the anthropic endpoint to determine real protocol availability.
5. Validates the output and opens a PR if anything changed.

Manual edits to the JSONs are fine but will be overwritten by the next daily refresh; permanent customizations belong in your user config (`~/.config/llm-env/config.conf`).

### Claude Code Specific Configuration

For enhanced Claude Code compatibility during Anthropic outages, you can override the Claude-specific model variables by setting them as environment variables before running `llm-env set anthropic`:

```bash
export ANTHROPIC_DEFAULT_OPUS_MODEL="your-custom-model"
export ANTHROPIC_DEFAULT_SONNET_MODEL="your-custom-model"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="your-custom-model"
export CLAUDE_CODE_SUBAGENT_MODEL="your-custom-model"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="true"
llm-env set anthropic
```

### Overriding Existing Providers

```ini
# Use a cheaper OpenAI model by default
[openai]
base_url=https://api.openai.com/v1
api_key_var=LLM_OPENAI_API_KEY
default_model=gpt-4o-mini
description=OpenAI with cost optimization
enabled=true

# Use a different Groq model
[groq]
base_url=https://api.groq.com/openai/v1
api_key_var=LLM_GROQ_API_KEY
default_model=llama-3.1-70b-versatile
description=Groq with Llama model
enabled=true
```

### Disabling Providers

```ini
# Disable a provider you don't use
[anthropic]
enabled=false

# Temporarily disable a provider
[groq]
base_url=https://api.groq.com/openai/v1
api_key_var=LLM_GROQ_API_KEY
default_model=openai/gpt-oss-120b
description=Groq (temporarily disabled)
enabled=false
```

## Advanced Configuration

### Environment-Specific Configurations

You can create different configurations for different environments:

```bash
# Development configuration
~/.config/llm-env/config.conf

# Production configuration (system-wide)
/usr/local/etc/llm-env/config.conf
```

### Model Overrides at Runtime

Override the default model for any provider using environment variables:

```bash
# Override OpenAI model
export OPENAI_MODEL_OVERRIDE="gpt-4o-mini"
llm-env set openai  # Will use gpt-4o-mini instead of default

# Override Groq model
export OPENAI_MODEL_OVERRIDE="llama-3.1-8b-instant"
llm-env set groq
```

### API Key Management

Set up your API keys in your shell profile:

```bash
# Add to ~/.bashrc or ~/.zshrc
export LLM_CEREBRAS_API_KEY="your_cerebras_key_here"
export LLM_OPENAI_API_KEY="your_openai_key_here"
export LLM_GROQ_API_KEY="your_groq_key_here"
export LLM_OPENROUTER_API_KEY="your_openrouter_key_here"
export LLM_OLLAMA_API_KEY="not_required_for_local"
```

## Configuration Management Commands

### Adding Providers

```bash
# Add a provider interactively
llm-env config add my-provider
```

This will prompt you for:
- Base URL
- API key environment variable name
- Default model
- Description

### Removing Providers

```bash
# Remove a provider
llm-env config remove old-provider
```

### Validating Configuration

```bash
# Validate your configuration
llm-env config validate
```

This checks for:
- Valid INI format
- Required fields
- Duplicate provider names
- Invalid URLs

### Editing Configuration

```bash
# Open configuration in your default editor
llm-env config edit
```

### Backup and Restore

```bash
# Create a backup of your configuration
llm-env config backup

# Restore from a backup file
llm-env config restore /path/to/backup.conf

# List available backups
llm-env config restore  # Shows available backups
```

### Bulk Operations

```bash
# Enable multiple providers at once
llm-env config bulk enable cerebras openai groq

# Disable multiple providers at once
llm-env config bulk disable openrouter anthropic

# Example: Enable only production providers
llm-env config bulk disable openrouter openrouter2 openrouter3
llm-env config bulk enable cerebras openai
```

## Default Provider Configurations

The bundled configuration includes these providers:

### Cerebras
```ini
[cerebras]
base_url=https://api.cerebras.ai/v1
api_key_var=LLM_CEREBRAS_API_KEY
default_model=qwen-3-coder-480b
description=Cerebras - Fast inference with competitive pricing
enabled=true
```

### OpenAI
```ini
[openai]
base_url=https://api.openai.com/v1
api_key_var=LLM_OPENAI_API_KEY
default_model=gpt-5-2025-08-07
description=OpenAI - Industry standard GPT models
enabled=true
```

### Groq
```ini
[groq]
base_url=https://api.groq.com/openai/v1
api_key_var=LLM_GROQ_API_KEY
default_model=openai/gpt-oss-120b
description=Groq - Lightning-fast inference
enabled=true
```

### OpenRouter
```ini
[openrouter]
base_url=https://openrouter.ai/api/v1
api_key_var=LLM_OPENROUTER_API_KEY
default_model=x-ai/grok-code-fast-1
description=OpenRouter - Access to multiple models through one API
enabled=true
```

### Anthropic (Native Protocol)
```ini
[anthropic]
base_url=https://api.anthropic.com/v1
api_key_var=LLM_ANTHROPIC_API_KEY
default_model=claude-sonnet-4-20250514
protocol=anthropic
description=Anthropic Claude - Native API with ANTHROPIC_* variables
enabled=true
```

## Best Practices

### Security
- Never commit API keys to version control
- Use environment variables for all sensitive data
- Set appropriate file permissions on configuration files:
  ```bash
  chmod 600 ~/.config/llm-env/config.conf
  ```

### Organization
- Use descriptive provider names
- Group related providers (e.g., `ollama-local`, `ollama-remote`)
- Document custom configurations with clear descriptions

### Performance
- Disable unused providers to reduce startup time
- Use local providers for development when possible
- Consider model costs when setting defaults

## Troubleshooting Configuration

### Common Issues

1. **Configuration not loading**
   ```bash
   # Check file exists and has correct permissions
   ls -la ~/.config/llm-env/config.conf
   
   # Validate configuration syntax
   llm-env config validate
   ```

2. **Provider not appearing**
   ```bash
   # Check if provider is enabled
   grep -A5 "\[provider_name\]" ~/.config/llm-env/config.conf
   
   # List all providers
   llm-env list
   ```

3. **API key not found**
   ```bash
   # Check environment variable is set
   echo $LLM_PROVIDER_API_KEY
   
   # Check variable name in configuration
   grep "api_key_var" ~/.config/llm-env/config.conf
   ```

### Debug Mode

Enable debug output to troubleshoot configuration issues:

```bash
# Enable debug mode
export LLM_ENV_DEBUG=1
llm-env list
```

This will show:
- Configuration file loading order
- Provider parsing details
- Environment variable resolution

---

*For more help, see the [Troubleshooting Guide](troubleshooting.md) or [main documentation](README.md).*