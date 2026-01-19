# shfmt - Shell Script Formatter

## Documentation

- **Website:** https://github.com/mvdan/sh
- **GitHub:** https://github.com/mvdan/sh
- **Documentation:** https://github.com/mvdan/sh/blob/master/cmd/shfmt/README.md

## Overview

shfmt is a shell parser, formatter, and interpreter. It reformats shell scripts to a consistent style, improving readability and maintainability.

## Installation

### macOS
```bash
brew install shfmt
```

### Linux
```bash
go install mvdan.cc/sh/v3/cmd/shfmt@latest
```

### From GitHub Releases
```bash
wget -qO- "https://github.com/mvdan/sh/releases/latest/download/shfmt_linux_amd64" | sudo install /dev/stdin /usr/local/bin/shfmt
```

## Usage

```bash
# Format a file (in-place)
shfmt -w llm-env

# Format all shell files
shfmt -w **/*.sh

# Check if files are formatted (dry run)
shfmt -d **/*.sh

# Show diff without modifying
shfmt -d llm-env
```

## Options Used in llm-env

| Option | Purpose |
|--------|---------|
| `-w, -write` | Write result to file instead of stdout |
| `-d, -diff` | Print diff of formatting changes |
| `-s, -simplify` | Simplify the code |
| `-i, -indent` | Number of spaces (llm-env uses 2) |

## CI Integration

```yaml
- name: Check formatting
  run: shfmt -d **/*.sh
```

## Best Practices

1. **Consistent style** - All scripts should follow the same formatting
2. **Pre-commit hooks** - Run shfmt before committing
3. **2-space indentation** - Matches project coding standards
4. **No trailing whitespace** - shfmt handles this automatically
