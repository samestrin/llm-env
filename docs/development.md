# Development Guide

This guide is for developers who want to contribute to LLM Environment Manager.

## Contributing

We welcome contributions! Whether you're fixing bugs, adding features, improving documentation, or adding new providers, your help is appreciated.

### Ways to Contribute

- **Add new providers** - Support for additional LLM services
- **Improve error handling** - Better user experience
- **Add new features** - Enhanced functionality
- **Fix bugs** - Stability improvements
- **Improve documentation** - Help other users
- **Write tests** - Ensure reliability

## Development Setup

### Prerequisites

- Bash 4.0+ (most systems have this)
- Git for version control
- Text editor of your choice
- Access to LLM APIs for testing

### Getting Started

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/yourusername/llm-env.git
   cd llm-env
   ```

2. **Create a development branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Set up development environment**
   ```bash
   # Make the script executable
   chmod +x llm-env
   
   # Test locally
   ./llm-env list
   ```

## Project Structure

```
llm-env/
├── llm-env                 # Main script
├── config/
│   └── llm-env.conf       # Default configuration
├── docs/
│   ├── README.md          # Documentation hub
│   ├── configuration.md   # Configuration guide
│   ├── troubleshooting.md # Troubleshooting guide
│   ├── development.md     # This file
│   └── comprehensive.md   # Compatible tools
├── examples/
│   ├── usage-scenarios.md # Usage examples
│   └── shell-config.sh    # Shell setup examples
├── install.sh             # Installation script
├── README.md              # Main documentation
└── LICENSE                # MIT license
```

## Code Style Guidelines

### Bash Scripting Standards

1. **Use strict mode**
   ```bash
   set -euo pipefail
   ```

2. **Quote variables**
   ```bash
   # Good
   echo "$variable"
   
   # Bad
   echo $variable
   ```

3. **Use meaningful function names**
   ```bash
   # Good
   load_configuration_file()
   validate_provider_config()
   
   # Bad
   load_config()
   validate()
   ```

4. **Add comments for complex logic**
   ```bash
   # Parse INI file sections
   while IFS='=' read -r key value; do
       # Skip comments and empty lines
       [[ $key =~ ^[[:space:]]*# ]] && continue
       [[ -z $key ]] && continue
   done
   ```

5. **Use consistent indentation (2 spaces)**

6. **Handle errors gracefully**
   ```bash
   if ! command -v curl >/dev/null 2>&1; then
     echo "Error: curl is required but not installed" >&2
     return 1
   fi
   ```

### Configuration Standards

1. **Use descriptive provider names**
   ```ini
   # Good
   [cerebras]
   [openai-gpt4]
   [local-ollama]
   
   # Bad
   [c]
   [ai1]
   [local]
   ```

2. **Include helpful descriptions**
   ```ini
   description=Cerebras - Fast inference with competitive pricing
   ```

3. **Use consistent API key variable naming**
   ```ini
   api_key_var=LLM_PROVIDER_API_KEY
   ```

## Adding New Providers

### 1. Research the Provider

- **API Compatibility**: Ensure it's OpenAI-compatible
- **Authentication**: How API keys are handled
- **Base URL**: The correct endpoint
- **Available Models**: What models are supported
- **Documentation**: Official API docs

### 2. Add to Default Configuration

Edit `config/llm-env.conf`:

```ini
[new-provider]
base_url=https://api.newprovider.com/v1
api_key_var=LLM_NEWPROVIDER_API_KEY
default_model=their-best-model
description=New Provider - Brief description of their service
enabled=true
```

### 3. Test the Provider

```bash
# Set up API key
export LLM_NEWPROVIDER_API_KEY="your_test_key"

# Test with llm-env
./llm-env set new-provider
./llm-env show

# Test API call
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"'$OPENAI_MODEL'","messages":[{"role":"user","content":"Hello!"}]}' \
     "$OPENAI_BASE_URL/chat/completions"
```

### 4. Update Documentation

- Add to provider list in `README.md`
- Add example usage in `examples/usage-scenarios.md`
- Update `docs/comprehensive.md` if it's a notable service

### 5. Create Pull Request

Include:
- Provider configuration
- Test results
- Documentation updates
- Any special setup instructions

## Testing

### Manual Testing

1. **Basic functionality**
   ```bash
   # Test all core commands
   ./llm-env list
   ./llm-env set cerebras
   ./llm-env show
   ./llm-env unset
   ```

2. **Configuration management**
   ```bash
   # Test config commands
   source ./llm-env config init
   source ./llm-env config validate
   source ./llm-env config add test-provider
   source ./llm-env config remove test-provider
   ```

3. **Error handling**
   ```bash
   # Test error conditions
   ./llm-env set nonexistent-provider
   ./llm-env set provider-without-key
   ```

### API Testing

Test with real API calls:

```bash
# Test each provider
for provider in cerebras openai groq openrouter; do
  echo "Testing $provider..."
  ./llm-env set $provider
  
  # Test models endpoint
  curl -s -H "Authorization: Bearer $OPENAI_API_KEY" \
       "$OPENAI_BASE_URL/models" | jq '.data[0].id' || echo "Failed"
done
```

### Automated Testing

Create test scripts:

```bash
#!/bin/bash
# tests/basic_functionality.sh

set -euo pipefail

# Test script exists and is executable
[[ -x ./llm-env ]] || { echo "Script not executable"; exit 1; }

# Test list command
./llm-env list >/dev/null || { echo "List command failed"; exit 1; }

# Test invalid provider
if ./llm-env set invalid-provider 2>/dev/null; then
  echo "Should have failed with invalid provider"
  exit 1
fi

echo "Basic tests passed"
```

## Release Process

### Version Management

1. **Update version in script**
   ```bash
   # In llm-env script
   VERSION="1.1.0"
   ```

2. **Update README badges**
   ```markdown
   ![Version 1.1.0](https://img.shields.io/badge/Version-1.1.0-blue)
   ```

3. **Create changelog entry**
   Document new features, bug fixes, and breaking changes

### Pre-release Checklist

- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Version numbers are consistent
- [ ] New providers are tested
- [ ] Breaking changes are documented
- [ ] Installation script works

### Release Steps

1. **Create release branch**
   ```bash
   git checkout -b release/v1.1.0
   ```

2. **Final testing**
   ```bash
   # Test installation
   ./install.sh
   
   # Test all providers
   llm-env list
   ```

3. **Create GitHub release**
   - Tag the release
   - Upload assets if needed
   - Write release notes

## Common Development Tasks

### Adding a New Command

1. **Add to main case statement**
   ```bash
   case "$1" in
     "new-command")
       handle_new_command "${@:2}"
       ;;
   esac
   ```

2. **Implement the function**
   ```bash
   handle_new_command() {
     local args=("$@")
     # Implementation here
   }
   ```

3. **Add to help text**
   ```bash
   show_help() {
     cat << EOF
   Commands:
     new-command    Description of new command
   EOF
   }
   ```

### Improving Error Messages

```bash
# Good error messages
echo "Error: Provider '$provider' not found. Available providers:" >&2
list_providers >&2
return 1

# Include helpful context
echo "Error: API key not found for $provider" >&2
echo "Please set: export $api_key_var='your-api-key'" >&2
```

### Adding Configuration Validation

```bash
validate_provider_config() {
  local provider="$1"
  local config_file="$2"
  
  # Check required fields
  local base_url api_key_var default_model
  base_url=$(get_config_value "$provider" "base_url" "$config_file")
  api_key_var=$(get_config_value "$provider" "api_key_var" "$config_file")
  default_model=$(get_config_value "$provider" "default_model" "$config_file")
  
  [[ -z $base_url ]] && { echo "Missing base_url for $provider"; return 1; }
  [[ -z $api_key_var ]] && { echo "Missing api_key_var for $provider"; return 1; }
  [[ -z $default_model ]] && { echo "Missing default_model for $provider"; return 1; }
}
```

## Debugging

### Enable Debug Mode

```bash
# Add debug output to functions
if [[ ${LLM_ENV_DEBUG:-} == "1" ]]; then
  echo "[DEBUG] Loading config from: $config_file" >&2
fi
```

### Common Debug Techniques

```bash
# Trace script execution
set -x

# Check variable values
echo "DEBUG: provider=$provider, base_url=$base_url" >&2

# Validate assumptions
[[ -f "$config_file" ]] || { echo "Config file not found: $config_file" >&2; return 1; }
```

## Security Considerations

### API Key Handling

- Never log API keys
- Don't include keys in error messages
- Use environment variables, not files
- Sanitize debug output

```bash
# Good: Hide sensitive data
echo "API key: ${api_key:0:8}..." >&2

# Bad: Expose full key
echo "API key: $api_key" >&2
```

### Input Validation

```bash
# Validate provider names
if [[ ! $provider =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "Error: Invalid provider name" >&2
  return 1
fi

# Validate URLs
if [[ ! $base_url =~ ^https?:// ]]; then
  echo "Error: Invalid base URL" >&2
  return 1
fi
```

## Getting Help

### Development Questions

- **GitHub Discussions**: Ask questions about development
- **Issues**: Report bugs or request features
- **Code Review**: Get feedback on pull requests

### Resources

- **Bash Manual**: Advanced scripting techniques
- **OpenAI API Docs**: Understanding the standard
- **Provider Documentation**: Specific API details

---

*Thank you for contributing to LLM Environment Manager! Your efforts help make AI tools more accessible to everyone.*