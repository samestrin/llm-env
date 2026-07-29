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
   llm-env config add provider_name
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
   llm-env config validate
   ```

### 5. API Requests Failing

**Symptoms:**
- 401 Unauthorized errors
- Connection timeouts
- Invalid model errors

**Solutions:**

1. **Test API key manually:**
   ```bash
   # Test OpenAI API (using curl)
   curl -H "Authorization: Bearer $LLM_OPENAI_API_KEY" \
        https://api.openai.com/v1/models

   # Or using wget
   wget -q -S -O - --header="Authorization: Bearer $LLM_OPENAI_API_KEY" \
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

### 6. Anthropic (Claude) Specific Issues

**Symptoms:**
- `llm-env test anthropic` shows "Method not allowed (HTTP 405)" but says "connected successfully"
- Tools expecting `OPENAI_` variables don't work when Anthropic is set

**Solutions:**

1. **HTTP 405 is normal for testing:**
   Anthropic's `/v1/messages` endpoint only accepts POST requests. The test command sends a GET request to check connectivity. A 405 error confirms the endpoint exists and is reachable, so `llm-env` considers this a success.

2. **Variable Swapping:**
   When you `llm-env set anthropic` (if configured with `protocol=anthropic`), it exports `ANTHROPIC_API_KEY` and *unsets* `OPENAI_API_KEY`.
   - Tools that *only* support OpenAI will fail.
   - Use this mode only for tools that natively support Anthropic.
   - If you need to use Anthropic with an OpenAI-only tool, consider using a proxy or checking if the tool supports a custom compatible endpoint (some "Anthropic" providers might offer an OpenAI-compatible endpoint, in which case use `protocol=openai`).

### 7. Environment Variables Not Persisting

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

### Windows

`llm-env` supports two Windows environments: **Git Bash** (MSYS2, bundled with
Git for Windows) and **WSL2**. Both are exercised by the test suite; Git Bash
runs in CI on every pull request.

There is deliberately **no PowerShell or CMD support**. `llm-env` works by
setting environment variables in the shell that sources it, and there is no way
for a Bash process to modify its parent PowerShell session's environment. An
earlier version of this document suggested a wrapper like

```powershell
function llm-env { bash -c "source /usr/local/bin/llm-env '$args'" }
```

That advice was wrong and has been removed: `bash -c` starts a child process,
sets the variables there, and exits — the PowerShell session is unchanged. If
you need `llm-env` from PowerShell, run your LLM tooling inside Git Bash or WSL2
instead.

#### Git Bash

1. **Line endings.** Git for Windows defaults to `core.autocrlf=true`, which
   checks out CRLF. A CRLF `llm-env` fails on its very first line, and a CRLF
   config silently loads zero providers.

   The repository pins `eol=lf` in `.gitattributes`, so a fresh clone is
   correct. If you cloned before that, fix it with:

   ```bash
   git config --global core.autocrlf false
   git rm --cached -r . && git reset --hard
   ```

   `llm-env` also strips carriage returns when reading a config, so editing
   `config.conf` in Notepad is safe.

2. **Your shell profile.** mintty starts Bash as a *login* shell
   (`bash --login -i`), which reads `~/.bash_profile`, `~/.bash_login` or
   `~/.profile` — **not** `~/.bashrc`. `llm-env` and its installer write to a
   login file on Git Bash for exactly this reason, and add a `~/.bashrc`
   chain-loader if one exists.

   If `llm-env` is not defined in a new terminal:

   ```bash
   grep -n 'llm-env' ~/.bash_profile ~/.bash_login ~/.profile ~/.bashrc 2>/dev/null
   ```

3. **`sudo` does not exist.** Ignore any instruction to install system-wide.
   The installer picks `~/.local/bin` automatically.

4. **File permissions.** `chmod` is largely a no-op on NTFS with default mount
   options, so `llm-env` cannot make your config or rc file owner-only. If you
   store API keys on a shared Windows machine, use Windows ACLs or BitLocker.

5. **`bc` is not shipped.** Nothing requires it; response timing uses shell
   arithmetic.

6. **Hyperlinks and emoji.** mintty and Windows Terminal render both. Legacy
   `conhost` may not — `llm-env` detects a non-capable terminal and falls back
   to plain text. Force either behaviour with `LLM_ENV_HYPERLINKS=0` or `=1`.

#### WSL2

WSL2 is ordinary Linux and needs no special handling. Two things to know:

1. **Environment variables do not cross the boundary.** Variables set inside
   WSL2 are invisible to Windows-native programs, and vice versa. Run the tool
   that consumes them inside WSL2 too.

2. **Clone inside the Linux filesystem.** Cloning to `/mnt/c/...` is slow and
   reintroduces the Windows line-ending behaviour. Prefer `~/` inside the
   distribution.

   ```bash
   # Check you are on WSL and which distro
   echo "$WSL_DISTRO_NAME"
   cat /proc/sys/kernel/osrelease   # contains "microsoft" on WSL

   # If API calls hang, restart WSL networking from PowerShell:
   #   wsl --shutdown
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