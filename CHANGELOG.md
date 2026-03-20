# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.2] - 2026-03-20

### Added
- **Referral Sign-Up Links**: Three touchpoints drive users to sign up with referral codes:
  - Quickstart "Next steps" shows clickable sign-up links per API key
  - Missing API key errors show provider-specific sign-up link
  - Quickstart footer shows both Synthetic and Alibaba referral links
- **`signup_url` Config Field**: Providers can specify a sign-up URL in JSON and INI config
- **Clickable Terminal Links**: URLs render as clickable hyperlinks in supported terminals (OSC 8)
- **Demo Script**: `demo-quickstart.sh` for interactive walkthroughs

## [1.3.1] - 2026-03-19

### Fixed
- **Quickstart Parser**: Fixed JSON brace counting (`wc -c` → `wc -l`) that prevented provider parsing
- **Quickstart Parser**: Fixed `"providers": [` on same line not initializing array parsing
- **Quickstart Parser**: Fixed provider block closing at wrong brace level (only first provider was parsed per file)
- **Quickstart Output**: Deduplicated API key export lines in next-steps output

### Changed
- **Alibaba Quickstart**: Updated to correct Coding Plan endpoint (`coding-intl.dashscope.aliyuncs.com/v1`) with recommended models only: qwen3.5-plus, kimi-k2.5, glm-5, MiniMax-M2.5

## [1.3.0] - 2026-03-18

### Added
- **Provider Groups**: Define named groups of providers in config with `[group:name]` sections to set multiple providers with a single command (`source llm-env set default`)
- **Comma-Separated Set**: Set multiple providers at once without config (`source llm-env set cerebras,anthropic`)
- **Group Listing**: `llm-env list` now shows defined provider groups alongside providers

### Changed
- Refactored `cmd_set` into `set_single_provider` and `set_multiple_providers` for cleaner architecture

## [1.2.2] - 2026-03-12

### Added
- **Claude Code Support**: Added specific Anthropic variables for Claude Code outage circumvention
- **wget Connectivity Fallback**: Added `wget` support as a fallback for `llm-env test` when `curl` is not installed.

### Fixed
- **Zsh Compatibility**: Removed debug output from config parsing loop in zsh shell
- **Variable Coexistence**: Allow OpenAI and Anthropic variables to coexist in same session
- **Authentication**: Allow auth_token_var as sole credential for anthropic protocol
- **CI Configuration**: Removed llm-env tag from self-hosted runners

### Changed
- **Project Cleanup**: Removed .planning directory from git tracking

## [1.2.1] - 2026-01-20

### Added
- **Connectivity Fallback**: Added `wget` support as a fallback for `llm-env test` when `curl` is not installed.
- **Enhanced Anthropic Documentation**: Added specific troubleshooting and compatibility sections for native Anthropic protocol usage.

### Fixed
- **Locale Sensitivity**: Fixed provider name validation regex to use `LC_ALL=C` for consistent ASCII matching across different system locales.
- **Test Isolation**: Improved test reliability by ensuring isolated configurations for Bash version compatibility checks.

## [1.2.0] - 2026-01-19

### Added
- **Native Anthropic Protocol Support**: New `protocol` configuration field enabling direct Anthropic API integration
  - Set `protocol=anthropic` in provider config to export native `ANTHROPIC_*` environment variables
  - Exports `ANTHROPIC_API_KEY`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_MODEL`, and `ANTHROPIC_AUTH_TOKEN`
  - Uses proper Anthropic authentication headers (`x-api-key`, `anthropic-version: 2023-06-01`)
  - Protocol-aware API testing with `llm-env test` command
- **Zero Dependencies**: Inlined bash compatibility layer for true single-file distribution
  - Removed external `lib/bash_compat.sh` dependency
  - All compatibility functions now embedded directly in `llm-env`
- **Anthropic Provider Configuration**: Added pre-configured Anthropic provider in default config (disabled by default)

### Changed
- Updated documentation with protocol configuration examples
- Enhanced provider display to show current protocol type

## [1.1.4] - 2026-01-13

### Fixed
- **Test Reliability**: Fixed `init_config` returning non-zero exit code when no providers are configured
  - Added explicit `return 0` at end of function to prevent empty array iteration from causing failure
- **Bash 3.2 Compatibility**: Fixed `compat_assoc_get` returning exit code 1 for missing keys
  - Changed to return 0 with empty output, allowing callers to check for empty string instead
  - Prevents failures when running with `set -e` in Bash 3.2 compatibility mode

## [1.1.3] - 2026-01-13

### Fixed
- **Zsh Shell Compatibility**: Complete rewrite of shell detection and compatibility layer to properly support zsh
  - Added `detect_shell()` function to identify bash vs zsh at runtime
  - Enabled `BASH_REMATCH` option in zsh for regex capture group compatibility
  - Added `get_match()` helper to handle regex capture indexing differences between shells
  - Added `get_var_value()` helper for cross-shell indirect variable expansion (`${!var}` in bash, `${(P)var}` in zsh)
  - Store regex patterns in variables to work around zsh quoting requirements
  - Updated all wrapper functions (`get_provider_keys`, `get_provider_value`, `set_provider_value`, `has_provider_key`) with zsh-compatible array syntax
  - Moved `local` variable declarations outside loops to prevent zsh `typeset` output leakage
- **Installer Compatibility**: Script now works correctly when sourced from any directory in zsh

### Changed
- Replaced direct `BASH_REMATCH` usage with `get_match()` helper throughout codebase
- Replaced `${!var}` indirect expansion with `get_var_value()` helper
- Replaced inline regex patterns with variable-stored patterns for cross-shell compatibility

## [1.1.0] - 2025-09-02

### Added
- **Complete Integration Test Suite**: Comprehensive test coverage with 13 passing integration tests in `test_providers.bats`
- **Advanced Configuration Loading**: Robust configuration system with proper timing and initialization sequence
- **Test Environment Management**: Complete test setup with proper configuration isolation and cleanup
- **BATS Framework Integration**: Full compatibility with BATS testing framework including associative array support
- **Debug Infrastructure**: Debug output capabilities for troubleshooting configuration loading
- **Test Documentation**: Comprehensive comments in test setup explaining timing requirements
- **Environment Isolation**: Advanced test environment cleanup and isolation

### Changed
- **Test Setup Order**: Config file creation now happens before sourcing `llm-env` script
- **Test Configuration**: Enhanced temporary config directory structure for better test isolation

## [1.0.0] - 2025-08-29

### Added
- **Core LLM Environment Management**: Complete shell script for managing multiple LLM provider configurations
- **Provider Support**: Built-in support for OpenAI, Anthropic, Google AI, Groq, and Ollama providers
- **Configuration System**: Flexible configuration file system with user-specific overrides
- **Command Interface**: Full command-line interface with `list`, `set`, `show`, `unset`, and `config` commands
- **Environment Variables**: Automatic setting of provider-specific API keys and base URLs
- **Validation System**: Input validation for provider names and configuration values
- **Backup & Restore**: Configuration backup and restore functionality
- **Cross-Platform Support**: Compatible with Bash, Zsh, and Fish shells on macOS, Linux, and Windows (WSL)
- **Installation Script**: Automated installation with shell integration
- **Documentation**: Comprehensive documentation including usage examples and troubleshooting guides
- **Test Suite**: Complete test coverage with unit tests, integration tests, and system tests using BATS framework

### Security
- **API Key Protection**: Secure handling of API keys through environment variables
- **Configuration Validation**: Input sanitization and validation to prevent injection attacks
- **File Permissions**: Proper file permissions for configuration files

[1.2.2]: https://github.com/samestrin/llm-env/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/samestrin/llm-env/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/samestrin/llm-env/compare/v1.1.4...v1.2.0
[1.1.3]: https://github.com/samestrin/llm-env/compare/v1.1.2...v1.1.3
[1.1.0]: https://github.com/samestrin/llm-env/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/samestrin/llm-env/releases/tag/v1.0.0