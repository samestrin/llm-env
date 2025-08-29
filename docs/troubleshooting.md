# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with LLM Environment Manager.

## Version Information

**Current Version:** v1.1.0

### Version Compatibility
- **v1.1.0**: Added --help, test, backup/restore, bulk operations, debug mode
- **v1.0.0**: Initial release with basic provider switching

### New in v1.1.0
- `llm-env --help`: Comprehensive help system
- `llm-env test <provider>`: API connectivity testing
- `llm-env config backup/restore`: Configuration backup and restore
- `llm-env config bulk <action>`: Bulk enable/disable operations
- `LLM_ENV_DEBUG=1`: Debug mode for troubleshooting
- Enhanced installer with multi-shell support and uninstall

## Quick Diagnostics

### Check Your Setup

```bash
# Verify all providers and keys
llm-env list

# Check current environment
llm-env show

# Test provider connectivity (new in v1.1.0)
llm-env test cerebras

# Test a simple request manually
curl -H "Authorization: Bearer $OPENAI_API_KEY" $OPENAI_BASE_URL/models

# Get comprehensive help
llm-env --help
```

### Enable Debug Mode

```bash
# Enable detailed logging
export LLM_ENV_DEBUG=1
llm-env list
```

## Common Issues

### 1. "No API key found" Error

**Symptoms:**
- Error message when setting a provider
- Empty `$OPENAI_API_KEY` variable

**Solutions:**

1. **Check if the environment variable is set:**
   ```bash
   # For OpenAI
   echo $LLM_OPENAI_API_KEY
   
   # For Cerebras
   echo $LLM_CEREBRAS_API_KEY
   ```

2. **Add API keys to your shell profile:**
   ```bash
   # Edit your shell profile
   nano ~/.bashrc  # or ~/.zshrc
   
   # Add your API keys
   export LLM_OPENAI_API_KEY="your_key_here"
   export LLM_CEREBRAS_API_KEY="your_key_here"
   
   # Reload your shell
   source ~/.bashrc
   ```

3. **Check the API key variable name in configuration:**
   ```bash
   # Check what variable name is expected
   grep -A5 "\[openai\]" ~/.config/llm-env/config.conf
   ```

### 2. "Unknown provider" Error

**Symptoms:**
- Provider not listed in `llm-env list`
- Error when trying to set a provider

**Solutions:**

1. **Check available providers:**
   ```bash
   llm-env list
   ```

2. **Verify provider is enabled in configuration:**
   ```bash
   # Check if provider exists and is enabled
   grep -A6 "\[provider_name\]" ~/.config/llm-env/config.conf
   ```

3. **Add missing provider to configuration:**
   ```bash
   # Add provider interactively
   source llm-env config add provider_name
   ```

### 3. "Command not found: llm-env"

**Symptoms:**
- Shell can't find the `llm-env` command
- Script works with full path but not as command

**Solutions:**

1. **Check if script is in PATH:**
   ```bash
   which llm-env
   ls -la /usr/local/bin/llm-env
   ```

2. **Verify script is executable:**
   ```bash
   chmod +x /usr/local/bin/llm-env
   ```

3. **Check shell function is defined:**
   ```bash
   # Check if function exists
   type llm-env
   
   # Add function to shell profile if missing
   echo 'llm-env() { source /usr/local/bin/llm-env "$@"; }' >> ~/.bashrc
   source ~/.bashrc
   ```

### 4. Configuration Not Loading

**Symptoms:**
- Changes to configuration file not taking effect
- Default providers still showing after customization

**Solutions:**

1. **Check configuration file location:**
   ```bash
   # Check which config file is being used
   export LLM_ENV_DEBUG=1
   llm-env list
   ```

2. **Verify file permissions:**
   ```bash
   ls -la ~/.config/llm-env/config.conf
   # Should be readable by your user
   ```

3. **Validate configuration syntax:**
   ```bash
   source llm-env config validate
   ```

### 5. API Requests Failing

**Symptoms:**
- 401 Unauthorized errors
- Connection timeouts
- Invalid model errors

**Solutions:**

1. **Test API key manually:**
   ```bash
   # Test OpenAI API
   curl -H "Authorization: Bearer $LLM_OPENAI_API_KEY" \
        https://api.openai.com/v1/models
   
   # Test Cerebras API
   curl -H "Authorization: Bearer $LLM_CEREBRAS_API_KEY" \
        https://api.cerebras.ai/v1/models
   ```

2. **Check model availability:**
   ```bash
   # List available models for current provider
   curl -H "Authorization: Bearer $OPENAI_API_KEY" \
        "$OPENAI_BASE_URL/models"
   ```

3. **Verify base URL is correct:**
   ```bash
   echo $OPENAI_BASE_URL
   # Should end with /v1 for most providers
   ```

### 6. Environment Variables Not Persisting

**Symptoms:**
- Variables work in current session but disappear after restart
- Need to run `llm-env set` every time

**Solutions:**

1. **Check shell profile is being loaded:**
   ```bash
   # For bash
   echo $BASH_VERSION
   cat ~/.bashrc | grep LLM_
   
   # For zsh
   echo $ZSH_VERSION
   cat ~/.zshrc | grep LLM_
   ```

2. **Add API keys to correct profile:**
   ```bash
   # Determine your shell
   echo $SHELL
   
   # Edit the appropriate file
   # For bash: ~/.bashrc
   # For zsh: ~/.zshrc
   ```

3. **Source the profile after changes:**
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

## Advanced Troubleshooting

### Debug Configuration Loading

```bash
# Enable debug mode
export LLM_ENV_DEBUG=1

# Check configuration loading
llm-env list

# This will show:
# - Which config files are checked
# - Which file is actually loaded
# - How providers are parsed
```

### Check Environment Variable Resolution

```bash
# Show all LLM-related environment variables
env | grep LLM_

# Show current OpenAI variables
env | grep OPENAI_

# Check specific provider variables
echo "Cerebras: $LLM_CEREBRAS_API_KEY"
echo "OpenAI: $LLM_OPENAI_API_KEY"
echo "Groq: $LLM_GROQ_API_KEY"
```

### Validate API Connectivity

```bash
# Test each provider's endpoint
for provider in cerebras openai groq openrouter; do
  echo "Testing $provider..."
  llm-env set $provider
  curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    "$OPENAI_BASE_URL/models"
  echo
done
```

### Check Script Integrity

```bash
# Verify script hasn't been corrupted
head -1 /usr/local/bin/llm-env
# Should show: #!/bin/bash

# Check script permissions
ls -la /usr/local/bin/llm-env
# Should be executable (-rwxr-xr-x)

# Test script directly
/usr/local/bin/llm-env list
```

## Platform-Specific Issues

### macOS

1. **Gatekeeper blocking script:**
   ```bash
   # Remove quarantine attribute
   xattr -d com.apple.quarantine /usr/local/bin/llm-env
   ```

2. **PATH issues with different shells:**
   ```bash
   # Check default shell
   echo $SHELL
   
   # macOS might use different profile files
   # Try ~/.bash_profile instead of ~/.bashrc
   ```

### Linux

1. **Permission issues:**
   ```bash
   # Ensure user can write to config directory
   mkdir -p ~/.config/llm-env
   chmod 755 ~/.config/llm-env
   ```

2. **Different shell configurations:**
   ```bash
   # Some distributions use different profile files
   # Check: ~/.profile, ~/.bash_profile, ~/.bashrc
   ```

### Windows (WSL/Git Bash)

1. **Line ending issues:**
   ```bash
   # Convert line endings if needed
   dos2unix /usr/local/bin/llm-env
   ```

2. **PATH differences:**
   ```bash
   # Windows paths might need adjustment
   # Use /c/Users/username/ instead of ~
   ```

3. **WSL-specific issues:**
   ```bash
   # Check WSL version
   wsl --version
   
   # Ensure proper shell configuration
   echo $SHELL
   
   # WSL2 networking issues
   # May need to restart WSL if API calls fail
   wsl --shutdown
   ```

4. **PowerShell integration:**
   ```powershell
   # If using PowerShell, you can create a wrapper function
   function llm-env { 
       bash -c "source /usr/local/bin/llm-env '$args'"
   }
   ```

## Getting Help

### Collect Debug Information

Before reporting issues, collect this information:

```bash
# System information
echo "OS: $(uname -a)"
echo "Shell: $SHELL"
echo "Script location: $(which llm-env)"

# Configuration information
echo "Config file:"
find ~/.config /usr/local/etc . -name "*llm-env*" 2>/dev/null

# Environment variables
echo "LLM variables:"
env | grep LLM_ | sed 's/=.*/=***HIDDEN***/'

# Current state
echo "Current provider:"
llm-env show
```

### Report Issues

When reporting issues, include:

1. **Error message** (exact text)
2. **Steps to reproduce** the issue
3. **System information** (OS, shell)
4. **Configuration** (sanitized, no API keys)
5. **Debug output** (with `LLM_ENV_DEBUG=1`)

### Community Resources

- **GitHub Issues**: Report bugs and feature requests
- **Discussions**: Ask questions and share tips
- **Wiki**: Community-maintained documentation

---

*For configuration help, see the [Configuration Guide](configuration.md). For general usage, see the [main documentation](README.md).*