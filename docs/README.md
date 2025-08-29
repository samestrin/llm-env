# LLM Environment Manager Documentation

Welcome to the comprehensive documentation for LLM Environment Manager. This directory contains detailed guides and references to help you get the most out of the tool.

## Quick Navigation

### Getting Started
- [Main README](../README.md) - Quick start guide and basic usage
- [Installation Guide](../README.md#installation) - Step-by-step installation instructions

### Configuration
- [Configuration Guide](configuration.md) - Detailed configuration examples and advanced setup
- [Default Configuration](../config/llm-env.conf) - Bundled provider configurations

### Usage & Examples
- [Usage Scenarios](../examples/usage-scenarios.md) - Real-world usage examples
- [Shell Configuration](../examples/shell-config.sh) - Shell setup examples

### Reference
- [Compatible Tools](comprehensive.md) - Applications and frameworks that work with llm-env
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

### Development
- [Contributing Guidelines](development.md) - How to contribute to the project

## Documentation Structure

```
docs/
├── README.md              # This file - documentation index
├── comprehensive.md       # Compatible tools and applications
├── configuration.md       # Detailed configuration guide
├── troubleshooting.md     # Extended troubleshooting guide
└── development.md         # Contributing and development guide
```

## Quick Reference

### Basic Commands
```bash
# List providers
llm_manager list

# Set provider
llm_manager set cerebras

# Show current config
llm_manager show

# Configuration management
source llm-env config init
source llm-env config edit
```

### Environment Variables
- `OPENAI_API_KEY` - Current provider's API key
- `OPENAI_BASE_URL` - Current provider's base URL
- `OPENAI_MODEL` - Current provider's default model

## Need Help?

1. Check the [Troubleshooting Guide](troubleshooting.md)
2. Review [Usage Scenarios](../examples/usage-scenarios.md)
3. Open an issue on GitHub

---

*For the latest updates and community discussions, visit the [GitHub repository](https://github.com/yourusername/llm-env).*