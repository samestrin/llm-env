# Configuration Files

This directory contains configuration files used by the planning workflow commands.

## Files

### `max_lines`
**Current Value:** `cat max_lines`
**Purpose:** Maximum line count for original-requirements.md before compression is triggered
**Default:** 2000 for Claude, 1500 for Gemini
**Customization:**
- Increase for LLMs with larger context windows (e.g., 2500 for Claude Opus)
- Decrease for smaller context LLMs (e.g., 1000 for basic models)

### `helper_llm`
**Current Value:** `cat helper_llm`
**Purpose:** Which LLM to use for compression tasks (should be fast and cheap)
**Default:** gemini (recommended for all users - fast and economical)
**Customization:**
- Change to "claude" if you don't have Gemini API access
- Change to "qwen" or other LLM if preferred

### `helper_llm_cmd`
**Current Value:** `cat helper_llm_cmd`
**Purpose:** Command-line flags for the helper LLM
**Default:** -p (prompt mode for Gemini)
**Customization:**
- Adjust based on your helper LLM's CLI interface
- Add additional flags as needed (e.g., model selection)

### `html2text`
**Current Value:** `cat html2text`
**Purpose:** HTML to markdown/text converter for fetching web documentation
**Default:** Detected automatically (html2text > pandoc > none)
**Options:**
- `html2text` - Simple HTML to text converter (recommended)
- `pandoc` - Universal document converter (more powerful)
- `none` - No converter available (HTML URLs will be skipped)
**Customization:**
- Install html2text: `pip install html2text` (Python) or `brew install html2text` (macOS)
- Install pandoc: `brew install pandoc` (macOS) or download from pandoc.org
- Used by `/create-documentation` when fetching HTML documentation from URLs

---

## Project Discovery Configuration

These files are auto-detected by `/init-specs` and used by commands like `/design-sprint` and `/init-plan` to skip expensive discovery processes.

### `project_type`
**Purpose:** Programming language/platform (node, python, rust, go, java)
**Auto-detected by:** /init-specs
**Used by:** /design-sprint, /init-plan
**Manual override:** `echo "python" > .planning/.config/project_type`

### `framework`
**Purpose:** Framework name (nextjs, react, django, fastapi, express, etc.)
**Auto-detected by:** /init-specs
**Used by:** /design-sprint, /init-plan
**Manual override:** `echo "nextjs" > .planning/.config/framework`

### `package_manager`
**Purpose:** Package manager (npm, yarn, pnpm, pip, poetry, cargo, go)
**Auto-detected by:** /init-specs
**Used by:** /design-sprint, test and coverage commands
**Manual override:** `echo "pnpm" > .planning/.config/package_manager`

### `source_directory`
**Purpose:** Main source code directory (src/, lib/, app/)
**Auto-detected by:** /init-specs
**Used by:** /init-plan, /design-sprint
**Manual override:** `echo "src/" > .planning/.config/source_directory`

### `test_runner`
**Purpose:** Test framework (jest, vitest, pytest, cargo test, go test)
**Auto-detected by:** /init-specs
**Used by:** /design-sprint (test environment validation)
**Manual override:** `echo "vitest" > .planning/.config/test_runner`

### `test_directory`
**Purpose:** Test location (tests/, __tests__/, test/, e2e-tests/)
**Auto-detected by:** /init-specs
**Used by:** /design-sprint (test location pattern)
**Manual override:** `echo "__tests__/" > .planning/.config/test_directory`
**Special case - Wasp:** If e2e-tests/ directory exists (Wasp project), this config is NOT created because Wasp requires co-located tests (tests next to source files). Separated test directories break Wasp's build.

### `test_cmd`
**Purpose:** Command to run tests (npm test, pytest, cargo test)
**Auto-detected by:** /init-specs
**Used by:** /design-sprint, /execute-sprint
**Manual override:** `echo "npm test" > .planning/.config/test_cmd`

### `coverage_cmd`
**Purpose:** Command to run test coverage (npm run coverage, pytest --cov)
**Auto-detected by:** /init-specs
**Used by:** /design-sprint (coverage validation)
**Manual override:** `echo "npm run coverage" > .planning/.config/coverage_cmd`

### `lint_cmd`
**Purpose:** Command to run linter (npm run lint, pylint, cargo clippy)
**Auto-detected by:** /init-specs
**Used by:** /execute-sprint, quality checks
**Manual override:** `echo "npm run lint" > .planning/.config/lint_cmd`

### `types_cmd`
**Purpose:** Command to check types (npx tsc --noEmit, mypy .)
**Auto-detected by:** /init-specs
**Used by:** /execute-sprint, quality checks
**Manual override:** `echo "npx tsc --noEmit" > .planning/.config/types_cmd`

### `build_cmd`
**Purpose:** Command to build project (npm run build, wasp build, cargo build)
**Auto-detected by:** /init-specs
**Used by:** /execute-sprint, quality checks
**Manual override:** `echo "npm run build" > .planning/.config/build_cmd`

---

## How Config is Used

When `/init-plan` or `/capture-request` creates an original-requirements.md:

1. Load `max_lines` to determine compression threshold
2. If source file exceeds `max_lines`:
   - Save uncompressed version to `original-requirements-uncompressed.md`
   - Use `helper_llm` with `helper_llm_cmd` to intelligently compress
   - Save compressed version to `original-requirements.md` (with link to uncompressed)
3. If source file is under `max_lines`:
   - Save directly to `original-requirements.md` (no compression needed)

## Editing Configuration

To change a value, simply edit the file:

```bash
# Increase max_lines to 2500
echo "2500" > .planning/.config/max_lines

# Change helper LLM to Claude
echo "claude" > .planning/.config/helper_llm

# Update helper LLM command flags
echo "-p --model claude-3-haiku" > .planning/.config/helper_llm_cmd
```

Changes take effect immediately for the next command that uses the config.
