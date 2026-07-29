#!/usr/bin/env bash

# BATS helper functions for llm-env testing
# Addresses associative array scoping issues in BATS environment

# Global array management helpers for BATS
# NOTE: these no longer take an array-mode parameter. Nothing has ever passed
# one -- verified across every .bats file -- so the "${1:-...}" form was dead
# code that also tripped SC2119/SC2120 once lint coverage was widened from
# three files to all of them.
declare_global_arrays() {
    local array_support="$BASH_ASSOC_ARRAY_SUPPORT"
    local declare_global_support="${BASH_DECLARE_GLOBAL_SUPPORT:-false}"
    
    if [[ "$array_support" == "true" ]]; then
        # Declare native associative arrays
        if [[ "$declare_global_support" == "true" ]]; then
            # Bash 4.2+ with declare -g support
            declare -gA PROVIDER_BASE_URLS
            declare -gA PROVIDER_API_KEY_VARS  
            declare -gA PROVIDER_DEFAULT_MODELS
            declare -gA PROVIDER_DESCRIPTIONS
            declare -gA PROVIDER_ENABLED
        else
            # Bash 4.0-4.1 with associative arrays but no declare -g
            declare -A PROVIDER_BASE_URLS
            declare -A PROVIDER_API_KEY_VARS  
            declare -A PROVIDER_DEFAULT_MODELS
            declare -A PROVIDER_DESCRIPTIONS
            declare -A PROVIDER_ENABLED
        fi
    else
        # Compatibility mode for Bash < 4.0
        if [[ "$declare_global_support" == "true" ]]; then
            # Bash 4.2+ with declare -g support
            declare -ga AVAILABLE_PROVIDERS
            declare -ga PROVIDER_BASE_URLS_KEYS PROVIDER_BASE_URLS_VALUES
            declare -ga PROVIDER_API_KEY_VARS_KEYS PROVIDER_API_KEY_VARS_VALUES
            declare -ga PROVIDER_DEFAULT_MODELS_KEYS PROVIDER_DEFAULT_MODELS_VALUES
            declare -ga PROVIDER_DESCRIPTIONS_KEYS PROVIDER_DESCRIPTIONS_VALUES
            declare -ga PROVIDER_ENABLED_KEYS PROVIDER_ENABLED_VALUES
        else
            # Older Bash versions without declare -g
            declare -a AVAILABLE_PROVIDERS
            declare -a PROVIDER_BASE_URLS_KEYS PROVIDER_BASE_URLS_VALUES
            declare -a PROVIDER_API_KEY_VARS_KEYS PROVIDER_API_KEY_VARS_VALUES
            declare -a PROVIDER_DEFAULT_MODELS_KEYS PROVIDER_DEFAULT_MODELS_VALUES
            declare -a PROVIDER_DESCRIPTIONS_KEYS PROVIDER_DESCRIPTIONS_VALUES
            declare -a PROVIDER_ENABLED_KEYS PROVIDER_ENABLED_VALUES
        fi
    fi
}

# Clear all provider arrays for test isolation
clear_provider_arrays() {
    local array_support="$BASH_ASSOC_ARRAY_SUPPORT"
    
    if [[ "$array_support" == "true" ]]; then
        # Clear native associative arrays
        unset PROVIDER_BASE_URLS PROVIDER_API_KEY_VARS PROVIDER_DEFAULT_MODELS PROVIDER_DESCRIPTIONS PROVIDER_ENABLED
    else  
        # Clear compatibility arrays
        unset AVAILABLE_PROVIDERS
        unset PROVIDER_BASE_URLS_KEYS PROVIDER_BASE_URLS_VALUES
        unset PROVIDER_API_KEY_VARS_KEYS PROVIDER_API_KEY_VARS_VALUES
        unset PROVIDER_DEFAULT_MODELS_KEYS PROVIDER_DEFAULT_MODELS_VALUES
        unset PROVIDER_DESCRIPTIONS_KEYS PROVIDER_DESCRIPTIONS_VALUES
        unset PROVIDER_ENABLED_KEYS PROVIDER_ENABLED_VALUES
    fi
}

# Initialize test environment with proper array setup
init_test_environment() {
    local compatibility_mode="${1:-false}"
    
    # Source the main script to get parse_bash_version function and initialize compatibility variables
    source "$BATS_TEST_DIRNAME/../../llm-env" > /dev/null 2>&1 || {
        # Fallback: define parse_bash_version locally if sourcing fails
        parse_bash_version() {
            local version="${BASH_VERSION:-4.0.0}"
            local major minor
            
            if [[ "${version}" =~ ^([0-9]+)\.([0-9]+) ]]; then
                major="${BASH_REMATCH[1]}"
                minor="${BASH_REMATCH[2]}"
            else
                major=3
                minor=2
            fi
            
            if [[ ${major} -gt 4 || (${major} -eq 4 && ${minor} -ge 0) ]]; then
                BASH_ASSOC_ARRAY_SUPPORT=true
            else
                BASH_ASSOC_ARRAY_SUPPORT=false
            fi
            
            if [[ ${major} -gt 4 || (${major} -eq 4 && ${minor} -ge 2) ]]; then
                BASH_DECLARE_GLOBAL_SUPPORT=true
            else
                BASH_DECLARE_GLOBAL_SUPPORT=false
            fi
            
            export BASH_MAJOR_VERSION=${major}
            export BASH_MINOR_VERSION=${minor}
            export BASH_ASSOC_ARRAY_SUPPORT
            export BASH_DECLARE_GLOBAL_SUPPORT
        }
        
        # Call the fallback function
        parse_bash_version
    }
    
    # Override with compatibility mode if requested
    if [[ "$compatibility_mode" == "true" ]]; then
        export BASH_ASSOC_ARRAY_SUPPORT="false"
    fi
    
    # Clear any existing arrays
    clear_provider_arrays
    
    # Declare global arrays for this test session
    declare_global_arrays
}

# Validate array state for debugging
validate_array_state() {
    local array_support="${1:-$BASH_ASSOC_ARRAY_SUPPORT}"
    
    echo "Array Support Mode: $array_support" >&2
    
    if [[ "$array_support" == "true" ]]; then
        echo "Native Arrays Status:" >&2
        echo "  PROVIDER_BASE_URLS: ${#PROVIDER_BASE_URLS[@]} entries" >&2
        echo "  PROVIDER_API_KEY_VARS: ${#PROVIDER_API_KEY_VARS[@]} entries" >&2
        echo "  PROVIDER_DEFAULT_MODELS: ${#PROVIDER_DEFAULT_MODELS[@]} entries" >&2
    else
        echo "Compatibility Arrays Status:" >&2
        echo "  AVAILABLE_PROVIDERS: ${#AVAILABLE_PROVIDERS[@]} entries" >&2  
        echo "  BASE_URLS: ${#PROVIDER_BASE_URLS_KEYS[@]} keys, ${#PROVIDER_BASE_URLS_VALUES[@]} values" >&2
        echo "  API_KEY_VARS: ${#PROVIDER_API_KEY_VARS_KEYS[@]} keys, ${#PROVIDER_API_KEY_VARS_VALUES[@]} values" >&2
    fi
}

# Helper to safely set provider data in tests
set_test_provider() {
    local provider_name="$1"
    local base_url="$2" 
    local api_key_var="$3"
    local model="$4"
    local description="$5"
    local enabled="${6:-true}"
    local array_support="${7:-$BASH_ASSOC_ARRAY_SUPPORT}"
    
    if [[ "$array_support" == "true" ]]; then
        # Use native associative arrays
        PROVIDER_BASE_URLS["$provider_name"]="$base_url"
        PROVIDER_API_KEY_VARS["$provider_name"]="$api_key_var"
        PROVIDER_DEFAULT_MODELS["$provider_name"]="$model"  
        PROVIDER_DESCRIPTIONS["$provider_name"]="$description"
        PROVIDER_ENABLED["$provider_name"]="$enabled"
    else
        # Use compatibility arrays
        AVAILABLE_PROVIDERS+=("$provider_name")
        
        PROVIDER_BASE_URLS_KEYS+=("$provider_name")
        PROVIDER_BASE_URLS_VALUES+=("$base_url")
        
        PROVIDER_API_KEY_VARS_KEYS+=("$provider_name")
        PROVIDER_API_KEY_VARS_VALUES+=("$api_key_var")
        
        PROVIDER_DEFAULT_MODELS_KEYS+=("$provider_name")
        PROVIDER_DEFAULT_MODELS_VALUES+=("$model")
        
        PROVIDER_DESCRIPTIONS_KEYS+=("$provider_name")
        PROVIDER_DESCRIPTIONS_VALUES+=("$description")
        
        PROVIDER_ENABLED_KEYS+=("$provider_name")
        PROVIDER_ENABLED_VALUES+=("$enabled")
    fi
}

# Helper to get provider data in tests
get_test_provider() {
    local array_name="$1"
    local provider_name="$2"
    local array_support="${3:-$BASH_ASSOC_ARRAY_SUPPORT}"
    
    if [[ "$array_support" == "true" ]]; then
        # Use native array access
        case "$array_name" in
            "PROVIDER_BASE_URLS") echo "${PROVIDER_BASE_URLS[$provider_name]:-}" ;;
            "PROVIDER_API_KEY_VARS") echo "${PROVIDER_API_KEY_VARS[$provider_name]:-}" ;;
            "PROVIDER_DEFAULT_MODELS") echo "${PROVIDER_DEFAULT_MODELS[$provider_name]:-}" ;;
            "PROVIDER_DESCRIPTIONS") echo "${PROVIDER_DESCRIPTIONS[$provider_name]:-}" ;;
            "PROVIDER_ENABLED") echo "${PROVIDER_ENABLED[$provider_name]:-}" ;;
            *) return 1 ;;
        esac
    else
        # Use compatibility array search
        case "$array_name" in
            "PROVIDER_BASE_URLS") 
                get_compat_value PROVIDER_BASE_URLS_KEYS PROVIDER_BASE_URLS_VALUES "$provider_name" ;;
            "PROVIDER_API_KEY_VARS")
                get_compat_value PROVIDER_API_KEY_VARS_KEYS PROVIDER_API_KEY_VARS_VALUES "$provider_name" ;;
            "PROVIDER_DEFAULT_MODELS")
                get_compat_value PROVIDER_DEFAULT_MODELS_KEYS PROVIDER_DEFAULT_MODELS_VALUES "$provider_name" ;;
            "PROVIDER_DESCRIPTIONS")
                get_compat_value PROVIDER_DESCRIPTIONS_KEYS PROVIDER_DESCRIPTIONS_VALUES "$provider_name" ;;
            "PROVIDER_ENABLED")
                get_compat_value PROVIDER_ENABLED_KEYS PROVIDER_ENABLED_VALUES "$provider_name" ;;
            *) return 1 ;;
        esac
    fi
}

# Helper function for compatibility array value lookup.
#
# Deliberately avoids `local -n` namerefs: those are bash 4.3+, so the helper
# meant to exercise the bash-3.2 code path could not itself run on bash 3.2
# (it aborted with "local: -n: invalid option"). This mirrors the indirection
# style the product's own compat_assoc_get uses, which works everywhere.
get_compat_value() {
    local keys_array_name="$1"
    local values_array_name="$2"
    local search_key="$3"

    local -a keys values
    eval "keys=(\${${keys_array_name}[@]+\"\${${keys_array_name}[@]}\"})"     2>/dev/null || keys=()
    eval "values=(\${${values_array_name}[@]+\"\${${values_array_name}[@]}\"})" 2>/dev/null || values=()

    local i
    for ((i = 0; i < ${#keys[@]}; i++)); do
        if [[ "${keys[i]}" == "$search_key" ]]; then
            echo "${values[i]:-}"
            return 0
        fi
    done

    return 1
}

# Test setup helper that ensures proper environment
setup_test_env() {
    local compatibility_mode="${1:-false}"
    
    # Initialize test environment
    init_test_environment "$compatibility_mode"
    
    # Create temporary test directory
    export BATS_TEST_TMPDIR="$BATS_TMPDIR/llm-env-bats-$$"
    mkdir -p "$BATS_TEST_TMPDIR"
    
    # Set up isolated config environment
    export ORIG_XDG_CONFIG_HOME="$XDG_CONFIG_HOME"
    export ORIG_HOME="$HOME"
    export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/.config"
    export HOME="$BATS_TEST_TMPDIR"
}

# Test teardown helper that cleans up environment
teardown_test_env() {
    # Restore original environment
    export XDG_CONFIG_HOME="$ORIG_XDG_CONFIG_HOME"
    export HOME="$ORIG_HOME"
    
    # Clear arrays
    clear_provider_arrays
    
    # Clean up temp directory
    [[ -n "$BATS_TEST_TMPDIR" ]] && rm -rf "$BATS_TEST_TMPDIR"
    unset BATS_TEST_TMPDIR
    
    # Clear test environment variables
    unset LLM_PROVIDER OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
}

# Helper to create test configuration files
create_test_config() {
    local config_content="$1"
    local config_dir="${2:-$XDG_CONFIG_HOME/llm-env}"
    
    mkdir -p "$config_dir"
    echo "$config_content" > "$config_dir/config.conf"
    echo "$config_dir/config.conf"
}

# Helper to verify provider exists in current configuration
assert_provider_exists() {
    local provider_name="$1"
    local array_support="${2:-$BASH_ASSOC_ARRAY_SUPPORT}"
    
    if [[ "$array_support" == "true" ]]; then
        [[ -n "${PROVIDER_BASE_URLS[$provider_name]:-}" ]]
    else
        for provider in "${AVAILABLE_PROVIDERS[@]}"; do
            [[ "$provider" == "$provider_name" ]] && return 0
        done
        return 1
    fi
}

# Helper to verify provider count
assert_provider_count() {
    local expected_count="$1"
    local array_support="${2:-$BASH_ASSOC_ARRAY_SUPPORT}"
    local actual_count
    
    if [[ "$array_support" == "true" ]]; then
        actual_count="${#PROVIDER_BASE_URLS[@]}"
    else
        actual_count="${#AVAILABLE_PROVIDERS[@]}"
    fi
    
    [[ "$actual_count" -eq "$expected_count" ]]
}

# Load assessment and dynamic timeout helpers
#
# Assess system load to determine if timeouts should be extended.
#
# Uses awk rather than bc for the float->int conversion, and gates the memory
# probe on the tool actually existing rather than assuming Linux. Git Bash
# ships neither bc nor free and macOS ships no free, so the previous version
# silently produced a wrong (or empty) factor on two of the three supported
# platforms -- which made perf-test failures unreproducible.
#
# Set LLM_ENV_TEST_LOAD_FACTOR to pin the factor explicitly in CI.
# When a probe could not run, LLM_ENV_LOAD_FACTOR_DEGRADED is set to 1 so the
# degradation is observable instead of silent.
get_system_load_factor() {
    local load_factor=100  # Base factor as integer (1.0 * 100)
    LLM_ENV_LOAD_FACTOR_DEGRADED=0

    if [[ -n "${LLM_ENV_TEST_LOAD_FACTOR:-}" ]]; then
        echo "$LLM_ENV_TEST_LOAD_FACTOR"
        return 0
    fi

    # Check if we're in CI environment
    if [[ -n "${CI:-}" || -n "${GITHUB_ACTIONS:-}" || -n "${TRAVIS:-}" || -n "${JENKINS_URL:-}" ]]; then
        # Base CI multiplier
        load_factor=150  # 1.5 * 100

        # Check system load average (1-minute)
        if command -v uptime >/dev/null 2>&1 && command -v awk >/dev/null 2>&1; then
            local load_int
            # One awk does the extraction, comma stripping, and float->int, so
            # the probe needs no bc and no tr.
            load_int=$(uptime 2>/dev/null | awk '
                { v = $(NF-2); gsub(/,/, "", v); v = v + 0; if (v <= 0) v = 1; printf "%d", v * 100 }
            ' 2>/dev/null)
            [[ "$load_int" =~ ^[0-9]+$ ]] || { load_int=100; LLM_ENV_LOAD_FACTOR_DEGRADED=1; }

            if [[ $load_int -gt 300 ]]; then
                load_factor=300
            elif [[ $load_int -gt 200 ]]; then
                load_factor=250
            elif [[ $load_int -gt 150 ]]; then
                load_factor=200
            fi
        else
            LLM_ENV_LOAD_FACTOR_DEGRADED=1
        fi

        # Memory pressure probe. Linux only -- there is no portable equivalent,
        # so on macOS/Git Bash this is skipped rather than silently mis-read.
        if command -v free >/dev/null 2>&1 && command -v awk >/dev/null 2>&1; then
            local mem_usage
            mem_usage=$(free 2>/dev/null | awk 'NR==2 && $2 > 0 { printf "%d", $3*100/$2 }')
            if [[ "$mem_usage" =~ ^[0-9]+$ ]] && [[ $mem_usage -gt 80 ]]; then
                load_factor=$((load_factor * 130 / 100))
            fi
        fi
    fi

    echo "$load_factor"
}

# Portable millisecond clock.
#
# `date +%s%N` is a GNU extension: BSD date (macOS <= 13) emits a literal "N",
# which silently poisons any arithmetic done on it. Prefer bash 5's
# EPOCHREALTIME, fall back to date +%s%N only after verifying it produced
# digits, and finally to whole seconds.
now_ms() {
    local t frac

    if [[ -n "${EPOCHREALTIME:-}" ]]; then
        # EPOCHREALTIME uses the locale decimal separator, hence the [.,] class.
        t="${EPOCHREALTIME%%[.,]*}"
        frac="${EPOCHREALTIME#*[.,]}"
        frac="${frac}000"
        printf '%s%s\n' "$t" "${frac:0:3}"
        return 0
    fi

    t="$(date +%s%N 2>/dev/null)"
    if [[ "$t" =~ ^[0-9]+$ ]] && [[ ${#t} -gt 10 ]]; then
        # Nanoseconds -> milliseconds by truncation, never arithmetic, so there
        # is no 64-bit overflow question on any bash.
        printf '%s\n' "${t%??????}"
        return 0
    fi

    t="$(date +%s 2>/dev/null)"
    [[ "$t" =~ ^[0-9]+$ ]] || t=0
    printf '%s000\n' "$t"
}

# Skip a perf test when only whole-second resolution is available.
skip_if_no_hires_clock() {
    if [[ -z "${EPOCHREALTIME:-}" ]]; then
        local probe
        probe="$(date +%s%N 2>/dev/null)"
        [[ "$probe" =~ ^[0-9]+$ ]] || skip "no high-resolution clock available"
    fi
}

# ---- Cross-shell execution harness -------------------------------------------
#
# bats is #!/usr/bin/env bash and never consults $SHELL, so CI's
# `shell: [bash, zsh]` matrix runs a byte-identical bash suite twice. Genuine
# zsh and bash-3.2 coverage requires spawning those interpreters explicitly.

# run_in_shell <shell> <sut-path> [args...]
# Sources the SUT under the named interpreter and populates bats' $status and
# $output. Args are single-quoted; they are CLI subcommands and flags, so an
# embedded apostrophe is out of contract.
run_in_shell() {
    local shell_bin="$1"; shift
    local sut="$1"; shift

    local cmd="source '$sut'" a
    for a in "$@"; do
        cmd="$cmd '$a'"
    done

    local -a pre=()
    case "$shell_bin" in
        # -f / --no-rcs: ignore the developer's own rc files so the run is
        # reproducible and cannot be perturbed by local zsh plugins.
        *zsh) pre=(-f) ;;
    esac

    run env HOME="$HOME" XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-}" \
        LLM_ENV_DEBUG="${LLM_ENV_DEBUG:-0}" \
        "$shell_bin" ${pre[@]+"${pre[@]}"} -c "$cmd"
}

skip_unless_command() {
    command -v "$1" >/dev/null 2>&1 || skip "${2:-$1 is not installed}"
}

# skip_unless_real_bash <major.minor>   e.g. skip_unless_real_bash 3.2
skip_unless_real_bash() {
    local want="$1"
    [[ -x /bin/bash ]] || skip "no /bin/bash"
    /bin/bash --version 2>/dev/null | head -1 | grep -q "version ${want//./\\.}" \
        || skip "/bin/bash is not $want"
}

# Skip when the filesystem does not honour POSIX permission bits.
#
# chmod is largely a no-op on NTFS with Git Bash's default mount options, so a
# test that chmods a file and then asserts the mode is testing the filesystem,
# not llm-env. Probe rather than branch on platform: a Linux CI runner using an
# exotic mount would hit the same thing.
skip_unless_posix_perms() {
    local probe="${BATS_TEST_TMPDIR:-${BATS_TMPDIR:-/tmp}}/permprobe.$$"
    : > "$probe" 2>/dev/null || skip "cannot create a probe file"
    chmod 600 "$probe" 2>/dev/null || { rm -f "$probe"; skip "chmod unavailable"; }
    local mode
    # shellcheck disable=SC2012
    mode="$(ls -l "$probe" 2>/dev/null | cut -c1-10)"
    rm -f "$probe"
    [[ "$mode" == "-rw-------" ]] || skip "filesystem does not honour POSIX permission bits (got $mode)"
}

# Several tests establish a precondition by making a path unwritable. Root
# ignores permission bits, so those tests pass vacuously when the suite runs as
# root -- a real possibility on a self-hosted runner.
skip_if_root() {
    local uid
    uid="$(id -u 2>/dev/null || echo 1000)"
    [ "$uid" != "0" ] || skip "running as root; permission preconditions cannot be established"
}

skip_unless_platform() {
    local want="$1" have
    have="$(uname -s 2>/dev/null)"
    case "$want:$have" in
        msys:MINGW*|msys:MSYS*) return 0 ;;
        macos:Darwin)           return 0 ;;
        linux:Linux)            return 0 ;;
    esac
    skip "test requires platform $want (running on $have)"
}

# ---- Injection sentinels -----------------------------------------------------
#
# A filesystem sentinel proves a payload did NOT execute. Output-grepping
# cannot: the vulnerable evals sit inside command substitutions and redirected
# blocks where stdout capture is unreliable, and a successful in-process
# payload can corrupt the bats runner into reporting a pass.

new_sentinel() {
    local name="${1:-sentinel}"
    local dir="${BATS_TEST_TMPDIR:-${BATS_TMPDIR:-/tmp}}"
    mkdir -p "$dir"
    local path="$dir/pwned-$name.$$"
    rm -f "$path"
    printf '%s' "$path"
}

assert_sentinel_absent() {
    local path="$1"
    if [[ -e "$path" ]]; then
        echo "SECURITY: payload executed -- sentinel $path exists" >&2
        echo "contents: $(cat "$path" 2>/dev/null)" >&2
        return 1
    fi
    return 0
}

assert_sentinel_present() {
    local path="$1"
    if [[ ! -e "$path" ]]; then
        echo "CANARY FAILED: payload did not execute even against a" >&2
        echo "deliberately vulnerable eval. The fixture pipeline is over-" >&2
        echo "escaping, so every injection regression test is vacuous." >&2
        return 1
    fi
    return 0
}

# ---- Config fixture builders -------------------------------------------------
#
# CRLF and hostile fixtures are generated at run time rather than committed, so
# no .gitattributes exception exists for a later edit to silently neutralise.

# write_config_with_eol <lf|crlf|cr|mixed|bom-crlf> <content> [config_dir]
write_config_with_eol() {
    local eol="$1" content="$2"
    local config_dir="${3:-${XDG_CONFIG_HOME:-${BATS_TEST_TMPDIR:-$BATS_TMPDIR}}/llm-env}"
    mkdir -p "$config_dir" || { echo "cannot create $config_dir" >&2; return 1; }
    local out="$config_dir/config.conf"

    : > "$out"
    [[ "$eol" == "bom-crlf" ]] && printf '\xEF\xBB\xBF' >> "$out"

    local line n=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        n=$((n + 1))
        case "$eol" in
            lf)            printf '%s\n'   "$line" >> "$out" ;;
            crlf|bom-crlf) printf '%s\r\n' "$line" >> "$out" ;;
            cr)            printf '%s\r'   "$line" >> "$out" ;;
            mixed)         if [[ $((n % 2)) -eq 0 ]]
                           then printf '%s\r\n' "$line" >> "$out"
                           else printf '%s\n'   "$line" >> "$out"; fi ;;
            *) echo "write_config_with_eol: unknown eol '$eol'" >&2; return 1 ;;
        esac
    done <<< "$content"

    printf '%s' "$out"
}

# make_hostile_config <vector> [config_dir]
# Writes a config carrying one injection payload and sets two globals:
#   LLM_ENV_TEST_CONFIG    -- path to the config file
#   LLM_ENV_TEST_SENTINEL  -- path the payload creates if it executes
# Returns via globals rather than stdout: a command substitution would run the
# function in a subshell and discard the sentinel path along with it.
make_hostile_config() {
    local vector="$1"
    local config_dir="${2:-${XDG_CONFIG_HOME:-${BATS_TEST_TMPDIR:-$BATS_TMPDIR}}/llm-env}"
    mkdir -p "$config_dir" || { echo "cannot create $config_dir" >&2; return 1; }
    local out="$config_dir/config.conf"

    LLM_ENV_TEST_SENTINEL="$(new_sentinel "$vector")"
    export LLM_ENV_TEST_SENTINEL
    local pay="\$(printf pwned > '$LLM_ENV_TEST_SENTINEL')"

    case "$vector" in
        value-squote|value-cmdsub)
            # Breaks out of the single quotes the accessor eval wraps values in.
            cat > "$out" <<EOF
[acme]
base_url=https://a.test/v1
api_key_var=LLM_ACME_KEY
default_model=m'${pay}'x
enabled=true
EOF
            ;;
        value-backtick)
            cat > "$out" <<EOF
[acme]
base_url=https://a.test/v1
api_key_var=LLM_ACME_KEY
default_model=m'\`printf pwned > '$LLM_ENV_TEST_SENTINEL'\`'x
enabled=true
EOF
            ;;
        section-cmdsub)
            # The key is interpolated into the accessor eval too.
            cat > "$out" <<EOF
[acme${pay}]
base_url=https://a.test/v1
api_key_var=LLM_ACME_KEY
default_model=m
enabled=true
EOF
            ;;
        section-backtick)
            cat > "$out" <<EOF
[acme\`printf pwned > '$LLM_ENV_TEST_SENTINEL'\`]
base_url=https://a.test/v1
api_key_var=LLM_ACME_KEY
default_model=m
enabled=true
EOF
            ;;
        section-brace)
            cat > "$out" <<EOF
[acme\${IFS}x]
base_url=https://a.test/v1
api_key_var=LLM_ACME_KEY
default_model=m
enabled=true
EOF
            ;;
        group-cmdsub)
            cat > "$out" <<EOF
[acme]
base_url=https://a.test/v1
api_key_var=LLM_ACME_KEY
default_model=m
enabled=true

[group:g${pay}]
providers=acme
EOF
            ;;
        *) echo "make_hostile_config: unknown vector '$vector'" >&2; return 1 ;;
    esac

    LLM_ENV_TEST_CONFIG="$out"
    export LLM_ENV_TEST_CONFIG
    return 0
}

# make_hostile_quickstart <field> [dir]
# Writes a schema-v2 quickstart catalog whose <field> carries an injection
# payload, mimicking a compromised or buggy scrape. Sets the same globals as
# make_hostile_config: LLM_ENV_TEST_CONFIG (the JSON path) and
# LLM_ENV_TEST_SENTINEL (the path the payload creates if it executes).
#
# Fields correspond to the values _qs_emit_provider writes into the user's
# config without validation.
make_hostile_quickstart() {
    local field="$1"
    local dir="${2:-${BATS_TEST_TMPDIR:-$BATS_TMPDIR}}"
    mkdir -p "$dir" || return 1
    local out="$dir/quickstart-synthetic.json"

    LLM_ENV_TEST_SENTINEL="$(new_sentinel "qs-$field")"
    export LLM_ENV_TEST_SENTINEL
    local pay="\$(printf pwned > '$LLM_ENV_TEST_SENTINEL')"

    local upstream="hf:vendor/Model" desc="A normal model"
    local endpoint="https://api.synthetic.test/openai/v1"
    local signup="https://synthetic.test/signup"

    case "$field" in
        upstream_id) upstream="m'${pay}'x" ;;
        description) desc="d'${pay}'x" ;;
        endpoints)   endpoint="https://api.synthetic.test/'${pay}'/v1" ;;
        signup_url)  signup="https://synthetic.test/'${pay}'" ;;
        *) echo "make_hostile_quickstart: unknown field '$field'" >&2; return 1 ;;
    esac

    cat > "$out" <<EOF
{
  "schema_version": "2",
  "vendor_short": "synth",
  "api_key_var": "LLM_SYNTHETIC_API_KEY",
  "signup_url": "$signup",
  "endpoints": { "openai": "$endpoint" },
  "models": [
    { "id": "m1", "upstream_id": "$upstream", "description": "$desc",
      "protocols": ["openai"] }
  ]
}
EOF

    LLM_ENV_TEST_CONFIG="$out"
    export LLM_ENV_TEST_CONFIG
    return 0
}

# ---- Environment capture -----------------------------------------------------
#
# bats' `run` collapses an unset variable and an empty one into the same empty
# $output. Leak tests need to tell those apart.

# dump_env_after <snippet> <VAR>...
# Runs <snippet> in a fresh bash, then prints one "VAR=value" or "VAR=<unset>"
# line per named variable. Populates $status/$output like `run`.
dump_env_after() {
    local snippet="$1"; shift
    local varlist="$*"
    run bash -c "
$snippet
for __v in $varlist; do
    if [ -z \"\${!__v+x}\" ]; then
        printf '%s=<unset>\n' \"\$__v\"
    else
        printf '%s=%s\n' \"\$__v\" \"\${!__v}\"
    fi
done
"
}

# $output is set by bats' `run` (and by dump_env_after, which wraps it), so the
# linter cannot see the assignment.
# shellcheck disable=SC2154
assert_env_unset() {
    local v
    for v in "$@"; do
        if [[ "$output" != *"$v=<unset>"* ]]; then
            echo "expected $v to be unset; dump was:" >&2
            printf '%s\n' "$output" >&2
            return 1
        fi
    done
    return 0
}

assert_env_is() {
    local name="$1" want="$2"
    if [[ "$output" != *"$name=$want"* ]]; then
        echo "expected $name=$want; dump was:" >&2
        printf '%s\n' "$output" >&2
        return 1
    fi
    return 0
}

# ---- Real-HOME protection ----------------------------------------------------
#
# setup_test_env overrides HOME and XDG_CONFIG_HOME, but a bug that resolves ~
# before the override (or a helper that reads $SHELL) can still write to the
# developer's actual rc files. Snapshot them in setup and assert in teardown;
# all suites that call setup_test_env inherit the protection for free.

snapshot_real_home() {
    local home="${LLM_ENV_REAL_HOME_OVERRIDE:-${ORIG_HOME:-$HOME}}"
    local f out=""
    for f in .bashrc .bash_profile .bash_login .profile .zshrc; do
        if [[ -f "$home/$f" ]]; then
            # size + mtime is enough to catch an append, and needs no hashing.
            out+="$f:$(wc -c < "$home/$f" 2>/dev/null | tr -d ' '):"
            # ls is fine here: the paths are a fixed list of dotfiles we built
            # ourselves, so the non-alphanumeric-filename concern does not apply.
            # shellcheck disable=SC2012
            out+="$(ls -l "$home/$f" 2>/dev/null | awk '{print $6, $7, $8}')"$'\n'
        else
            out+="$f:absent"$'\n'
        fi
    done
    LLM_ENV_REAL_HOME_SNAPSHOT="$out"
    export LLM_ENV_REAL_HOME_SNAPSHOT
}

assert_no_real_home_writes() {
    [[ -n "${LLM_ENV_REAL_HOME_SNAPSHOT:-}" ]] || return 0
    local expected="$LLM_ENV_REAL_HOME_SNAPSHOT"
    snapshot_real_home
    if [[ "$LLM_ENV_REAL_HOME_SNAPSHOT" != "$expected" ]]; then
        echo "FATAL: a test modified the real HOME's shell rc files" >&2
        echo "--- before ---" >&2; printf '%s' "$expected" >&2
        echo "--- after  ---" >&2; printf '%s' "$LLM_ENV_REAL_HOME_SNAPSHOT" >&2
        LLM_ENV_REAL_HOME_SNAPSHOT="$expected"
        return 1
    fi
    return 0
}

# Calculate dynamic timeout based on base timeout and system load
calculate_dynamic_timeout() {
    local base_timeout="$1"
    local load_factor
    load_factor=$(get_system_load_factor)
    
    # Calculate new timeout using integer arithmetic (load_factor is * 100)
    local dynamic_timeout
    dynamic_timeout=$((base_timeout * load_factor / 100))
    
    # Ensure minimum timeout
    if [[ $dynamic_timeout -lt $base_timeout ]]; then
        dynamic_timeout=$base_timeout
    fi
    
    echo "$dynamic_timeout"
}