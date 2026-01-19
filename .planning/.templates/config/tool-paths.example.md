# Tool Path Configuration

These files configure paths to CLI tools used by sprint execution commands.
Copy to `.planning/.config/` and customize paths as needed.

## Files

### helper_script
Path to `llm-support` binary for utilities (count, multiexists, etc.)

```
/usr/local/bin/llm-support
```

### clarification_script
Path to `llm-clarification` binary for cross-sprint learning (optional).

```
/usr/local/bin/llm-clarification
```

## Installation

```bash
# Create config directory
mkdir -p .planning/.config

# Set helper script path
echo '/usr/local/bin/llm-support' > .planning/.config/helper_script

# Set clarification script path (optional)
echo '/usr/local/bin/llm-clarification' > .planning/.config/clarification_script
```

## Verification

```bash
# Verify tools are accessible
cat .planning/.config/helper_script | xargs -I{} {} --version
cat .planning/.config/clarification_script | xargs -I{} {} --version
```
