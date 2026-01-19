# Architecture & Bash Compatibility [CRITICAL]

## Overview

llm-env is a Bash-based CLI tool that enables users to switch between LLM providers through a unified interface. The system architecture is designed around provider abstraction, where the base URL, API key environment variable names, and default model settings for each provider are stored in associative arrays. This abstraction allows new providers to be added with minimal code changes by updating these storage structures and configuration files.

> Source: architecture.md:43-52

The system includes a Bash 3.2+ compatibility layer that works around limitations in older Bash versions that lack proper associative array support. This layer uses wrapper functions to encapsulate direct access to these data structures, allowing the core logic to work consistently across Bash 3.2+, Bash 4.0+, and Bash 5.0+. Configuration is managed through INI-style files with provider-specific sections, and the tool dynamically loads and prioritizes configuration from multiple sources including environment variables, profile files, and runtime settings.

> Source: architecture.md:65-80, architecture.md:105-118

## Bash 3.2+ Compatibility Layer

The compatibility layer (inlined in `llm-env` lines ~157-298) provides wrapper functions that abstract away differences between Bash versions regarding associative arrays. Bash 3.2 lacks native associative array support, so the layer implements fallback mechanisms using indexed arrays and pattern matching. The functions are only defined when `BASH_ASSOC_ARRAY_SUPPORT=false`.

Key wrapper functions include:
- `set_provider_value(provider, key, value)` - Sets a key-value pair for a provider
- `get_provider_value(provider, key)` - Retrieves a value for a provider key

> Source: architecture.md:65-80, codebase-discovery.json:EXISTING_PATTERNS/Bash 3.2 Compatibility Layer

The shell compatibility matrix documents which Bash versions are tested and which features are supported across versions. This ensures the tool works consistently whether users are on macOS (Bash 3.2) or Linux (Bash 4.0+).

> Source: architecture.md:Shell Compatibility Matrix

## INI-Style Configuration Parsing

Configuration files use INI-style format with provider-specific sections. The `load_config()` function parses these files using regex pattern matching to extract key-value pairs.

```ini
[openai]
base_url = https://api.openai.com/v1
api_key_var = OPENAI_API_KEY
default_model = gpt-4

[anthropic]
base_url = https://api.anthropic.com/v1
api_key_var = ANTHROPIC_API_KEY
default_model = claude-3-opus-20240229
```

> Source: architecture.md:120-140

The parser is implemented in Bash using regex to match lines like `key = value` within each INI section, populating the provider storage structures accordingly.

## Data Structures Pattern

The system uses an Associative Array Pattern for Provider Storage. Three main arrays define each provider:

- `PROVIDER_BASE_URLS` - Maps provider name to API base URL
- `PROVIDER_API_KEY_VARS` - Maps provider name to environment variable name for API key
- `PROVIDER_DEFAULT_MODELS` - Maps provider name to default model identifier

> Source: architecture.md:43-52, codebase-discovery.json:EXISTING_PATTERNS/Associative Array Pattern

These arrays serve as the single source of truth for provider configuration. Direct access is discouraged in favor of wrapper functions for version compatibility.

## Configuration Precedence

Configuration values are loaded from multiple sources in priority order:

1. **Environment Variables** - Highest priority
2. **User Profile** (`~/.llmenv/profile`) - Runtime overrides
3. **System Config** (`/etc/llmenv/config`) - Machine-wide settings
4. **Package Config** (`/usr/local/etc/llmenv/config`) - Installation defaults

Earlier sources override later ones if the same key is defined. This precedence allows flexible configuration at different scopes while maintaining clear override behavior.

> Source: architecture.md:105-118

## Wrapper Functions

The codebase uses several wrapper function patterns to encapsulate implementation details:

| Pattern | Purpose |
|---------|---------|
| `set_provider_value()` / `get_provider_value()` | Compatible associative array access across Bash versions |
| `load_config()` | Parse INI configuration files with regex |
| `mask()` | Secure variable masking for sensitive values |

> Source: codebase-discovery.json:EXISTING_PATTERNS

These functions provide the integration points for commands:
- `cmd_set()` - Runtime configuration
- `cmd_unset()` - Remove configuration values
- `cmd_test()` - Validate provider connectivity
- `cmd_list()` - Enumerate available providers
- `cmd_show()` - Display current configuration

> Source: codebase-discovery.json:INTEGRATION_POINTS

## Extension Points

Adding a new provider involves three steps:

1. **Update Provider Storage Arrays** - Add entries to `PROVIDER_BASE_URLS`, `PROVIDER_API_KEY_VARS`, and `PROVIDER_DEFAULT_MODELS`

2. **Add Configuration Section** - Add provider section to default config file INI format

3. **No Code Changes Required** - The existing `load_config()`, `cmd_set()`, and wrapper functions handle the new provider automatically

> Source: architecture.md:Extension Points / Adding a New Provider

Similarly, adding new commands follows the existing pattern: implement a `cmd_<name>()` function, register it in the command dispatcher, and ensure it uses the wrapper functions for configuration access.

## Quick Reference

| Component | Location | Purpose |
|-----------|----------|---------|
| Bash compat functions | `llm-env:157-298` | Bash 3.2+ compatibility layer (inlined) |
| `load_config()` | architecture.md:120-140 | INI file parser with regex |
| Provider Arrays | architecture.md:43-52 | `PROVIDER_BASE_URLS`, `PROVIDER_API_KEY_VARS`, `PROVIDER_DEFAULT_MODELS` |
| Config Paths | architecture.md:105-118 | Environment → Profile → System → Package precedence |
| `mask()` | codebase-discovery.json | Secure variable masking |
