# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.1] - 2026-05-04

### Fixed
- **`curl … | bash` install now works without sudo.** When `/usr/local/bin` isn't writable AND the user isn't root AND `--install-dir` was not passed, the installer falls back to `$HOME/.local/bin` instead of hard-failing with "please run with sudo". Explicit `--install-dir` choices are still respected (and still hard-fail on unwritable targets). When fallback is used and the directory isn't on `PATH`, the installer prints the exact `export PATH="$HOME/.local/bin:$PATH"` line to add to your shell rc file.
- **`--uninstall` now finds fallback installs.** Previously `uninstall_llm_env` only looked in the default `INSTALL_DIR`, so users who installed via the new `~/.local/bin` fallback couldn't uninstall. The uninstaller now auto-detects.
- **`--uninstall --install-dir <dir>` flag order works.** The arg parser used to handle `--uninstall` inline and exit before reading later flags; flags after `--uninstall` are now respected.
- **`--install-dir <new-dir>` auto-creates the directory.** Previously hard-failed with a misleading sudo error if the parent was writable but the dir didn't exist yet. Common case: passing `--install-dir ~/.local/bin` on a fresh macOS account.

### Changed
- **Installer no longer prompts for synthetic providers.** The interactive `Add synthetic providers? (y/N)` prompt and the `add_synthetic_providers` helper are removed from `install.sh`. Install just installs. To add Synthetic / Alibaba Coding Plan models, run `llm-env quickstart` after install — the post-install next-steps output points at it. Non-interactive installs (CI, piped bash) are unaffected; the prompt only ever fired on a TTY.
- **README install docs** updated to reflect the new behavior. The `curl … | bash` one-liner now works for non-root users on the first try; a `sudo bash` form is documented for users who want a system-wide install.

### Added
- **`tests/integration/test_install.bats`**: 14 new BATS tests covering the synthetic-prompt removal, the fallback path, the explicit-dir hard-fail behavior, the PATH warning, the shell-function rc snippet, and the uninstall fallback discovery.

## [1.6.0] - 2026-05-01

### Added
- **Interactive Quickstart**: `llm-env quickstart` now walks you through provider setup interactively — pick which catalog(s) to add (Synthetic, Alibaba, or both), get the signup URL with our referral code, paste your API key (input hidden), and the key gets appended to your shell rc file (`~/.bashrc` or `~/.zshrc`) and verified with a tiny test call. Skips the prompt automatically if a key is already configured.
- **Positional Source Selection**: `llm-env quickstart synthetic`, `llm-env quickstart alibaba`, `llm-env quickstart synthetic,alibaba`, and `llm-env quickstart all` for scripted use.
- **Shell-rc Auto-Append**: New helpers (`_qs_detect_shell_rc`, `_qs_append_export_to_rc`) detect bash/zsh and append `export LLM_<vendor>_API_KEY='...'` lines safely (single-quote escaping for keys with `$`, `'`, `\`, `` ` ``, etc.; idempotent — won't duplicate). Fish/csh/tcsh users get a "add this manually" message instead.
- **Auto-Verification**: After key entry, runs `cmd_test` against `anth_<vendor>_kimi-k2.5` to confirm the key works. Failures print a warning but never abort quickstart.

### Changed
- **README + docs**: Quickstart section reframed around the new interactive flow. `docs/claude-code-quickstart.md` walkthrough shortened from 8 steps to 6 since the previous "sign up + paste key + test" steps now happen inside `quickstart` itself.

### Preserved
- Non-TTY behavior is unchanged: when stdin isn't a terminal (CI, scripts, piped install), `quickstart` falls back to the original "provision every available catalog, no prompts" behavior. The existing 21 BATS tests continue to pass unmodified.

## [1.5.2] - 2026-04-30

### Changed
- **Anthropic Provider Enabled by Default**: The bundled `[anthropic]` provider in `config/llm-env.conf` now ships with `enabled=true`. Anyone running Claude Code already has an Anthropic account, and disabling it by default forced an extra hand-edit to use the most-asked-for endpoint. Set `LLM_ANTHROPIC_API_KEY` and run `llm-env set anthropic` — no further setup needed.

## [1.5.1] - 2026-04-30

### Fixed
- **Alibaba Scraper**: Routes `coding-plan` docs fetch through the Jina reader proxy (`https://r.jina.ai/`) so the daily refresh sees current "Recommended models" content. Direct fetches were hitting Tengine's US-West edge cache which served days-old content (e.g. `qwen3.5-plus` while the page actually showed `qwen3.6-plus`). Tested cache-bust headers, query params, UAs, DNS resolvers, and direct IPs — none defeat the edge cache, so we egress through a different region. Direct HTML fetch is retained as a fallback.
- **Markdown Parser**: New parser path for the proxy-returned markdown alongside the existing HTML parser. Both tolerate the new "Recommended models:" phrasing and the legacy "Recommended:" form.

## [1.5.0] - 2026-04-30

### Added
- **Daily Quickstart Scraper** (`scripts/update_quickstart.py`): Python scraper that fetches synthetic's `/openai/v1/models` and the Alibaba Cloud Coding Plan docs page, classifies each model, and writes refreshed `quickstart-{synthetic,alibaba}.json` files. Suppresses quantization variants, applies a chat-only filter, and uses an AI-disambiguation fallback (synthetic GLM-4.7-Flash → GLM-4.7) for low-confidence classifications.
- **Anthropic Protocol Probe**: For each synthetic model, the scraper sends a 1-token probe to the anthropic endpoint to determine availability rather than assuming it.
- **GitHub Actions Workflow** (`.github/workflows/update-quickstart.yml`): Daily cron at 06:00 UTC (plus `workflow_dispatch`) runs the scraper and opens a PR via `peter-evans/create-pull-request` if anything changed. Validation gate refuses to write malformed payloads, preserving last-known-good on partial failure.
- **API Key Gate**: Scraper refuses to run without `LLM_SYNTHETIC_API_KEY` (without it the anthropic probe silently degrades to openai-only). Override available via `LLM_ENV_SCRAPER_ALLOW_NO_KEY=1` for tests.
- **Docker End-to-End Test** (`tests/system/test_docker_e2e.bats` + `docker_e2e_runner.sh`): Spins up a fresh `ubuntu:22.04` container, runs `install.sh --offline`, exercises `quickstart`/`list`/`set`, and verifies provider/group counts computed dynamically from the source JSONs. Optional live-API sub-test gated on `LLM_ENV_RUN_DOCKER_LIVE_TESTS=1`.

## [1.4.0] - 2026-04-30

### Added
- **Quickstart Schema v2**: New `quickstart-{synthetic,alibaba}.json` schema with top-level `endpoints.openai` and `endpoints.anthropic`, per-model `protocols[]` array, and `family_latest{}` map
- **Anthropic Protocol Quickstart**: Synthetic and Alibaba quickstart files now provision both `openai_*` and `anth_*` providers, automatically configuring `protocol=anthropic` for the latter
- **Per-Model Groups**: Each model with both protocols available gets a `[group:<vendor>_<id>]` binding, so `llm-env set synth_kimi-k2.5` activates both `OPENAI_*` and `ANTHROPIC_*` env vars in one shot
- **Family-Latest Aliases**: `[group:synth_kimi]`, `[group:synth_glm]`, `[group:alibaba_qwen]`, etc., resolve to whichever model is currently latest in that effective family (subtype-aware: `qwen-coder` and `qwen-thinking` track separately from `qwen`)
- **`LLM_ENV_QUICKSTART_DIR` env var**: Override the directory where `cmd_quickstart` looks for JSON files (used by integration tests and advanced setups)

### Changed
- **Naming Scheme**: Quickstart-emitted providers are now `<protocol>_<vendor-short>_<model>` (e.g. `openai_synth_kimi-k2.5`, `anth_alibaba_qwen3.5-plus`). Previous `<vendor>-<model>` names are no longer emitted.
- **Quickstart Parser**: Rewritten with pure-bash JSON helpers. Quantization variants (`-NVFP4`, `-FP8`, etc.) are no longer carried in the curated JSON files. Schema version is enforced — the parser rejects any file without `schema_version: "2"`.

### Removed
- `backend/synthetic-model-discovery.sh`: stale prototype superseded by the upcoming Python scraper (PR2)
- `test-quickstart.sh`: ad-hoc shell test, replaced by `tests/integration/test_quickstart.bats`

### Migration
Existing user configs are not modified. Provider sections written by older quickstart runs (e.g. `[synthetic-kimi-k2-5]`) continue to work — they just stop getting refreshed. To pick up the new naming and groups, re-run `llm-env quickstart` after updating to v1.4.0.

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