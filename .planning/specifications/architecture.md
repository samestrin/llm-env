# Architecture Documentation

## Overview

llm-env is a **pure Bash** utility for managing LLM provider credentials and switching between different AI API providers. The architecture follows Unix philosophy principles with focus on simplicity, portability, and zero runtime dependencies.

## System Architecture

```
llm-env/
├── llm-env                     # Main Bash script (single-file, includes Bash 3.2 compat)
├── install.sh                  # Installation script
├── config/
│   └── llm-env.conf           # Built-in provider config
├── lib/
│   ├── Config.psm1            # PowerShell config module (Windows)
│   ├── IniParser.psm1         # PowerShell INI parser
│   └── Providers.psm1         # PowerShell provider management
├── tests/
│   ├── unit/                  # Unit tests (BATS)
│   ├── integration/           # Integration tests (BATS)
│   ├── system/                # System tests (BATS)
│   ├── bats/                  # BATS framework (bundled)
│   └── lib/                   # Test helpers
├── docs/                      # User documentation
└── examples/                  # Usage examples
```

## Core Components

### 1. Main Script (`llm-env`)

The main script is a single-file Bash program (~1500 lines) containing:

#### Initialization Phase
```bash
parse_bash_version()          # Shell detection and version checking
init_config()                  # Load provider configuration
load_config()                  # Parse INI-style config files
```

#### Data Structures
```bash
# Associative arrays for provider config (wrapped for Bash 3.2 compatibility)
PROVIDER_BASE_URLS            # provider -> base_url
PROVIDER_API_KEY_VARS          # provider -> api_key_var
PROVIDER_DEFAULT_MODELS        # provider -> default_model
PROVIDER_DESCRIPTIONS          # provider -> description
PROVIDER_ENABLED               # provider -> enabled
AVAILABLE_PROVIDERS            # Array of enabled provider names
```

#### Command Architecture
```bash
cmd_set(provider)              # Set environment variables
cmd_unset()                    # Clear environment variables
cmd_list(--all)                # List available providers
cmd_show()                     # Show current configuration
cmd_test(provider)             # Test API connectivity
cmd_config(subcommand)         # Configuration management
cmd_help()                     # Display help
```

### 2. Bash Compatibility Layer (inlined in `llm-env`)

Provides associative array functionality for Bash 3.2 (macOS default). The compatibility
functions are inlined directly in `llm-env` (lines ~157-298) for true single-file distribution:

```bash
# Storage for bash <4.0
PROVIDER_*_KEYS                # Array of keys
PROVIDER_*_VALUES              # Array of values

# Wrapper functions (defined when BASH_ASSOC_ARRAY_SUPPORT=false)
compat_assoc_set(array, key, value)
compat_assoc_get(array, key)
compat_assoc_has_key(array, key)
compat_assoc_keys(array)
compat_assoc_size(array)
```

### 3. PowerShell Modules (Windows Support)

Located in `lib/` with `.psm1` extension:

- **Config.psm1** - Configuration loading and management
- **IniParser.psm1** - INI file parsing for config
- **Providers.psm1** - Provider registry and operations

## Design Patterns

### 1. Wrapper Pattern (Bash Compatibility)

All associative array operations go through wrapper functions to maintain Bash 3.2+ compatibility:

```bash
# Native Bash 4.0+
PROVIDER_BASE_URLS["openai"]="https://api.openai.com/v1"

# Wrapped for Bash 3.2
set_provider_value "PROVIDER_BASE_URLS" "openai" "https://api.openai.com/v1"
base=$(get_provider_value "PROVIDER_BASE_URLS" "openai")
```

### 2. Configuration Precedence

Config files are loaded in order of priority:

```
User config (highest)
  ~/.config/llm-env/config.conf

System config
  /usr/local/etc/llm-env/config.conf

Built-in fallback (lowest)
  $(script_dir)/config/llm-env.conf
```

### 3. INI-Style Configuration

Provider configuration uses INI format for human readability:

```ini
[provider_name]
base_url=https://api.example.com/v1
api_key_var=LLM_EXAMPLE_API_KEY
default_model=model-name
description=Optional description
enabled=true
```

### 4. Regex-Based Parsing

Configuration parsing uses stored regex patterns for cross-shell compatibility:

```bash
local section_pattern="^\[([^]]+)\]$"
local keyval_pattern="^([^=]+)=(.*)$"
```

### 5. Sourced Entry Point

The script is designed to be **sourced**, not executed as a binary:

```bash
# Shell wrappers in ~/.bashrc or ~/.zshrc
llm-env() {
  source /usr/local/bin/llm-env "$@"
}

# Direct execution for certain commands
./llm-env --help
./llm-env --version
```

## Data Flow

### Setting a Provider

```
User: llm-env set cerebras
    |
    v
cmd_set(cerebras)
    |
    +-> validate_provider_name()
    +-> validate_provider(cerebras)
    |       |
    |       v
    |   check PROVIDER_BASE_URLS[cerebras]
    |   check PROVIDER_ENABLED[cerebras]
    |
    v
get_provider_value(api_key_var)
get_var_value(api_key_var)              # Reads from shell environment
    |
    v
export OPENAI_API_KEY=$key
export OPENAI_BASE_URL=$base
export OPENAI_MODEL=$model
export LLM_PROVIDER=cerebras
```

### Testing Connectivity

```
User: llm-env test cerebras
    |
    v
cmd_test(cerebras)
    |
    +-> Validate provider
    +-> Get API key from environment
    |
    v
curl -s -w "%{http_code}" -o /dev/null \
    -H "Authorization: Bearer $api_key" \
    $base_url/models
    |
    v
Parse HTTP status code -> Display result
```

## Environment Variables

### Exported by llm-env

| Variable | Purpose | Example |
|----------|---------|---------|
| `OPENAI_API_KEY` | API key for current provider | `sk-...` |
| `OPENAI_BASE_URL` | Base URL for API endpoints | `https://api.cerebras.ai/v1` |
| `OPENAI_MODEL` | Default model to use | `qwen-3-coder-480b` |
| `LLM_PROVIDER` | Current provider name | `cerebras` |

### Configuration Variables

| Variable | Purpose | Location |
|----------|---------|----------|
| `LLM_*_API_KEY` | Provider-specific keys stored in shell profile | `~/.bashrc` |
| `LLM_ENV_DEBUG` | Enable debug output | Optional |
| `OPENAI_MODEL_OVERRIDE` | Override default model | Optional |

## Shell Compatibility Matrix

| Shell Version | Support | Notes |
|--------------|---------|-------|
| Bash 3.2 (macOS default) | ✅ Full | Uses compatibility layer |
| Bash 4.0+ | ✅ Full | Native associative arrays |
| Bash 5.x | ✅ Full | All features available |
| Zsh 5.0+ | ✅ Full | With BASH_REMATCH option |

## Testing Architecture

### Test Structure

```
tests/
├── unit/              # Test individual functions
│   ├── test_validation.bats
│   ├── test_bash_compatibility.bats
│   └── test_bash_versions.bats
├── integration/       # Test command execution
│   └── test_providers.bats
└── system/            # Cross-platform tests
    └── test_cross_platform.bats
```

### BATS Framework Features Used

- `setup()` / `teardown()` for test lifecycle
- `run` command for executing shell commands
- `$status`, `$output`, `$lines` for assertions
- `@test` decorators for test functions
- File-scoped setup/teardown files

## Security Considerations

### Variable Masking

The `mask()` function hides sensitive values in output:

```bash
mask("sk-12345abcde67890")  # Returns: ••••7890
```

### Validation

- `validate_provider_name()` - Prevents injection via provider names
- `sanitize_config_value()` - Removes dangerous patterns from config
- API keys are never written to config files

## Extension Points

### Adding a New Provider

1. Add entry to `config/llm-env.conf`:
```ini
[new-provider]
base_url=https://api.example.com/v1
api_key_var=LLM_NEW_PROVIDER_API_KEY
default_model=default-model
description=Description here
enabled=true
```

2. Set API key in shell profile:
```bash
export LLM_NEW_PROVIDER_API_KEY="your-key"
```

3. Use: `llm-env set new-provider`

### Adding a New Command

1. Define function `cmd_<command>()`
2. Add case to command dispatcher at end of script
3. Update `cmd_help()` with documentation
4. Add tests in appropriate test suite

## Performance Characteristics

- **Startup:** ~10-20ms (config parsing)
- **Switching:** <5ms (env var export)
- **Listing:** ~5-10ms (array iteration)
- **Testing:** Depends on network latency (API call)

## Known Limitations

1. **Single Provider Active:** Only one provider can be active at a time
2. **INI Parsing:** Limited to flat INI format (no nested sections)
3. **Environment Only:** Configuration is shell-session scoped
4. **No Proxy Support:** No built-in proxy configuration
5. **No Rate Limiting:** API rate limiting is provider responsibility
