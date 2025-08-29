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
source llm-env config init

# Edit your configuration
source llm-env config edit
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
enabled=true
```

### Configuration Fields

- **base_url**: The API endpoint URL
- **api_key_var**: Environment variable name for the API key
- **default_model**: Default model to use with this provider
- **description**: Human-readable description
- **enabled**: Whether this provider is available (true/false)

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
source llm-env config add my-provider
```

This will prompt you for:
- Base URL
- API key environment variable name
- Default model
- Description

### Removing Providers

```bash
# Remove a provider
source llm-env config remove old-provider
```

### Validating Configuration

```bash
# Validate your configuration
source llm-env config validate
```

This checks for:
- Valid INI format
- Required fields
- Duplicate provider names
- Invalid URLs

### Editing Configuration

```bash
# Open configuration in your default editor
source llm-env config edit
```

### Backup and Restore

```bash
# Create a backup of your configuration
source llm-env config backup

# Restore from a backup file
source llm-env config restore /path/to/backup.conf

# List available backups
source llm-env config restore  # Shows available backups
```

### Bulk Operations

```bash
# Enable multiple providers at once
source llm-env config bulk enable cerebras openai groq

# Disable multiple providers at once
source llm-env config bulk disable openrouter anthropic

# Example: Enable only production providers
source llm-env config bulk disable openrouter openrouter2 openrouter3
source llm-env config bulk enable cerebras openai
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
   source llm-env config validate
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