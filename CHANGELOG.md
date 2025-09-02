# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-01-29

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

## [1.0.0] - 2025-01-29

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

[1.1.0]: https://github.com/samestrin/llm-env/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/samestrin/llm-env/releases/tag/v1.0.0