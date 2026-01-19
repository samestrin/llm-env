# shellcheck - Static Analysis for Shell Scripts

## Documentation

- **Website:** https://www.shellcheck.net/
- **GitHub:** https://github.com/koalaman/shellcheck
- **Documentation:** https://github.com/koalaman/shellcheck/wiki

## Overview

ShellCheck is a static analysis tool for shell scripts. It gives warnings and suggestions for bash/sh shell scripts, including:
- Syntax errors and bugs
- Code style and conventions
- Portability issues
- Typographical mistakes
- Security best practices

## Installation

### macOS
```bash
brew install shellcheck
```

### Linux
```bash
sudo apt-get install shellcheck    # Debian/Ubuntu
sudo dnf install shellcheck        # Fedora
```

### From GitHub Releases
```bash
wget -qO- "https://github.com/koalaman/shellcheck/releases/download/latest/shellcheck-latest.linux.x86_64.tar.xz" | tar -xJv
sudo mv shellcheck-latest.linux.x86_64/shellcheck /usr/bin/
```

## CI Integration

In `.github/workflows/test.yml`:
```yaml
- name: Lint with shellcheck
  run: |
    shellcheck **/*.sh
```

## Common Rules Used in llm-env

### SC2296 - Parameter Expansion in Zsh
Used in bash/zsh compatibility layer for variable expansion.

### SC2155 - Declare and Assign Separately
Used when variables need to be declared before assignment.

### SC2034 - Variable Appears Unused
Used for compatibility arrays that are referenced by wrapper functions.

## Usage

```bash
# Check a single file
shellcheck llm-env

# Check all shell files
shellcheck **/*.sh

# Generate format for CI
shellcheck -f gcc llm-env

# Auto-fix some issues
shellcheck -f diff llm-env | git apply
```

## Best Practices

1. **Zero warnings** - All shell scripts should pass without warnings
2. **Fix or ignore** - Use `# shellcheck disable=SCXXXX` only when necessary
3. **CI gating** - Fail builds on new shellcheck warnings
