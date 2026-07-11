#!/usr/bin/env bash
#
# coverage.sh - Measure line coverage of the llm-env script with kcov.
#
# Runs the BATS suite under kcov, restricting instrumentation to the llm-env
# script, then enforces a minimum line-coverage threshold.
#
# Usage:
#   tests/coverage.sh                 # run all unit + integration suites
#   tests/coverage.sh unit            # run only tests/unit
#   COVERAGE_MIN=85 tests/coverage.sh # override the 80% default gate
#
# Exit codes:
#   0  coverage >= COVERAGE_MIN
#   1  coverage <  COVERAGE_MIN
#   2  kcov not installed (kcov is reliable on Linux; flaky on macOS)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BATS="$SCRIPT_DIR/bats/bin/bats"
TARGET="$PROJECT_ROOT/llm-env"
OUTDIR="${COVERAGE_OUTDIR:-$SCRIPT_DIR/coverage}"
COVERAGE_MIN="${COVERAGE_MIN:-80}"

if ! command -v kcov >/dev/null 2>&1; then
    echo "ERROR: kcov is not installed." >&2
    echo "  Linux:  apt-get install -y kcov   (or build from source)" >&2
    echo "  macOS:  brew install kcov          (note: kcov is flaky on macOS)" >&2
    exit 2
fi

if [[ ! -x "$BATS" ]]; then
    echo "ERROR: BATS not found at $BATS" >&2
    echo "  Run: git submodule update --init --recursive" >&2
    exit 2
fi

# Which suites to cover (default: unit + integration).
suites=()
case "${1:-all}" in
    unit)        suites=("$SCRIPT_DIR/unit") ;;
    integration) suites=("$SCRIPT_DIR/integration") ;;
    all)         suites=("$SCRIPT_DIR/unit" "$SCRIPT_DIR/integration") ;;
    *) echo "Unknown suite: $1 (use: unit | integration | all)" >&2; exit 2 ;;
esac

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

# Run kcov once per .bats file; kcov merges runs that share $OUTDIR.
for suite in "${suites[@]}"; do
    [[ -d "$suite" ]] || continue
    for test_file in "$suite"/*.bats; do
        [[ -f "$test_file" ]] || continue
        echo "kcov: $(basename "$test_file")"
        kcov --include-path="$TARGET" "$OUTDIR" "$BATS" "$test_file" || true
    done
done

# kcov writes a merged summary to $OUTDIR/kcov-merged/coverage.json
merged="$OUTDIR/kcov-merged/coverage.json"
if [[ ! -f "$merged" ]]; then
    # Fall back to any per-run summary if the merge dir name differs.
    merged="$(find "$OUTDIR" -name coverage.json -print -quit 2>/dev/null || true)"
fi
if [[ -z "$merged" || ! -f "$merged" ]]; then
    echo "ERROR: could not locate kcov coverage.json under $OUTDIR" >&2
    exit 2
fi

# Extract "percent_covered" without requiring jq.
percent="$(grep -o '"percent_covered"[^,]*' "$merged" | head -1 | grep -oE '[0-9]+(\.[0-9]+)?')"
if [[ -z "$percent" ]]; then
    echo "ERROR: could not parse percent_covered from $merged" >&2
    exit 2
fi

echo "----------------------------------------"
echo "llm-env line coverage: ${percent}%  (gate: ${COVERAGE_MIN}%)"
echo "HTML report: $OUTDIR/kcov-merged/index.html"
echo "----------------------------------------"

# Integer-safe comparison (drop any fractional part for the gate).
if awk -v p="$percent" -v m="$COVERAGE_MIN" 'BEGIN { exit !(p+0 >= m+0) }'; then
    echo "PASS: coverage meets the ${COVERAGE_MIN}% gate."
    exit 0
else
    echo "FAIL: coverage ${percent}% is below the ${COVERAGE_MIN}% gate." >&2
    exit 1
fi
