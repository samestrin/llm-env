# Technical debt

Findings from the 1.7.0 review that were deliberately **not** fixed in that
release. The 1.7.0 scope was every High and Medium severity finding plus the
security-relevant Low ones; what follows is the cosmetic and low-risk
remainder, recorded so it is tracked rather than forgotten.

Each entry names the location and says what actually goes wrong, so it can be
picked up without re-deriving the analysis.

---

## Variable and function pollution of the sourced shell

`llm-env` is sourced, so everything it defines persists in the user's
interactive shell. 1.7.0 fixed the cases that caused observable harm
(`$REPLY` colliding with the `read` builtin, `$VERSION` clobbering a common
name, `LC_ALL` leaking, `$line` escaping `load_config`). The rest remains.

**Still leaked after `source llm-env list`:** `__LLM_ENV_RC`, `_qs_added_names`,
`config_file`, `provider`, `failure`, `base_url`, `api_key_var`,
`default_model`, `description`, `CONFIG_SOURCE`, `CONFIG_LOADED`,
`AVAILABLE_PROVIDERS`, `AVAILABLE_GROUPS`, plus every `__LLM_V_*` /
`__LLM_K_*` store variable.

**Still exported into every child process** (`llm-env:38`, `63-66`, `98-101`):
`CURRENT_SHELL`, `SHELL_VERSION`, `BASH_MAJOR_VERSION`, `BASH_MINOR_VERSION`,
`BASH_ASSOC_ARRAY_SUPPORT`, `BASH_DECLARE_GLOBAL_SUPPORT`. Nothing
re-executes the script, so none of these need exporting. `CURRENT_SHELL` in
particular is a name other tools use.

**~55 functions with generic names** stay defined in the caller's shell:
`debug`, `trim`, `mask`, `link` (shadows `/bin/link`), `get_match`,
`host_from_url`, `init_config`, `load_config`, and so on.

*Why deferred:* the fix is a prefix-everything rename touching nearly every
line, and several test suites currently call these functions by their bare
names. High churn, low user-visible benefit, and it would have obscured the
security fixes in review.

---

## `cmd_config_validate` gaps

`llm-env` `cmd_config_validate` reports `✅ Configuration is valid` for configs
that will fail at use time. It does not:

- validate `protocol` against the accepted whitelist, so `protocol=antropic`
  passes and then silently falls back to openai;
- check that `[group:*]` members reference providers that exist and are
  enabled, so a group pointing at a deleted provider validates cleanly and
  fails on `llm-env set <group>`;
- flag duplicate `[section]` headers, where the later silently wins;
- distinguish an explicitly empty `enabled=` from an absent one (treated as
  `true`).

---

## INI parser: no inline comment support

`load_config`'s `keyval_pattern` is `^([^=]+)=(.*)$`, so

```ini
base_url=https://api.example.com/v1  # my note
```

yields a `base_url` of `https://api.example.com/v1  # my note`, which is
exported verbatim. `config validate`'s `^https?://` check passes it. Supporting
`#` comments after a value needs a decision about escaping for values that
legitimately contain `#` (some URLs do).

---

## Output and display

- **No ASCII fallback for emoji.** 131 lines contain emoji, plus `∅` and the
  `•` masking character. mintty and Windows Terminal render these; legacy
  `conhost` at a non-UTF-8 codepage does not. There is no `LLM_ENV_NO_EMOJI`
  switch. (The related OSC 8 hyperlink problem *was* fixed in 1.7.0.)
- **`install.sh:402-404`** uses box-drawing characters (`╔ ║ ╚ ═`) that render
  as mojibake under the same conditions.

---

## Minor correctness

- **`cmd_set "$1"` discards extra arguments** (`llm-env` entry point):
  `llm-env set a b` silently ignores `b` instead of erroring.
- **A group silently shadows a same-named provider.** `cmd_set` looks up
  `PROVIDER_GROUPS` before validating the name as a provider, so a group named
  `openai` would take precedence over a provider named `openai` with no warning.
- **`local TMOUT=30` in `cmd_config_add`.** `TMOUT` is special in both shells:
  in bash it becomes the default `read` timeout for anything called from that
  dynamic scope; in zsh a non-zero `TMOUT` arms `SIGALRM` for the interactive
  shell.
- **`cmd_list` re-runs `init_config`** although the entry point already did, so
  every `list` re-reads and re-parses the config. When no config file exists,
  the "using built-in defaults" banner prints twice.
- **`load_config` slurps the file via `$(cat ...)`** instead of redirecting it
  into the `while` loop, costing a fork per load. `normalize_protocol` and
  `validate_protocol` are each called in a command substitution per `protocol=`
  line.

---

## Test suite

- **`tests/system/test_cross_platform.bats`** still contains no actual OS
  detection despite its name; it is really an environment-isolation suite. The
  genuine platform tests live in `tests/unit/test_platform.bats`. Its
  `chmod 600` assertion is meaningless on NTFS, and its hardcoded
  `PATH=/bin:/usr/bin` is MSYS-root-relative under Git Bash. Both are skipped
  rather than adapted.
- **No bash 4.0/4.1 runner exists anywhere.** The `declare -g` scoping bug that
  1.7.0 fixed was reproducible on bash 5 by forcing the capability flag off,
  but genuine 4.0/4.1 *syntax* acceptance is unverified. A Docker matrix
  (`bash:3.2`, `bash:4.1`, `bash:4.4`, `bash:5.2`) driven by the existing
  `LLM_ENV_DOCKER_IMAGE` hook would close this; it belongs on a nightly
  schedule rather than per-PR.
- **`tests/system/test_docker_e2e.bats` always skips in CI** — it is gated on
  `LLM_ENV_RUN_DOCKER_TESTS=1`, which no workflow sets. It runs locally.

---

## Backup naming

`cmd_config_backup` uses `date +%Y%m%d_%H%M%S` with no disambiguator, so two
backups taken within the same second collide. The newer
`_config_backup_file` helper used by `config remove` already appends `$$`;
`cmd_config_backup` should adopt the same scheme.
