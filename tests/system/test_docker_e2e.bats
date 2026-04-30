#!/usr/bin/env bash
#
# End-to-end install + quickstart test inside a fresh Ubuntu container.
#
# Skip conditions:
#   - docker not installed or daemon unreachable
#   - running on CI without LLM_ENV_RUN_DOCKER_TESTS=1 opt-in
#
# Live-API sub-test gated on LLM_ENV_RUN_DOCKER_LIVE_TESTS=1 plus a
# real LLM_SYNTHETIC_API_KEY in the env.

setup() {
    RUNNER="$BATS_TEST_DIRNAME/docker_e2e_runner.sh"
}

_should_skip_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        return 0
    fi
    if ! docker info >/dev/null 2>&1; then
        return 0
    fi
    if [[ -n "${CI:-}" && "${LLM_ENV_RUN_DOCKER_TESTS:-}" != "1" ]]; then
        return 0
    fi
    return 1
}

@test "docker e2e: install + quickstart + set inside fresh ubuntu:22.04" {
    if _should_skip_docker; then
        skip "docker not available or CI without LLM_ENV_RUN_DOCKER_TESTS=1"
    fi

    run "$RUNNER"
    if [ "$status" -ne 0 ]; then
        echo "--- runner output ---"
        echo "$output"
        echo "--- end runner output ---"
    fi
    [ "$status" -eq 0 ]
    [[ "$output" == *"ALL CHECKS PASSED"* ]]
}

@test "docker e2e: live API test against synthetic" {
    if _should_skip_docker; then
        skip "docker not available or CI without LLM_ENV_RUN_DOCKER_TESTS=1"
    fi
    if [[ "${LLM_ENV_RUN_DOCKER_LIVE_TESTS:-}" != "1" ]]; then
        skip "set LLM_ENV_RUN_DOCKER_LIVE_TESTS=1 to opt in to live API call"
    fi
    if [[ -z "${LLM_SYNTHETIC_API_KEY:-}" ]]; then
        skip "LLM_SYNTHETIC_API_KEY not set"
    fi

    run "$RUNNER" --with-live-api
    if [ "$status" -ne 0 ]; then
        echo "--- runner output ---"
        echo "$output"
        echo "--- end runner output ---"
    fi
    [ "$status" -eq 0 ]
    [[ "$output" == *"ALL CHECKS PASSED"* ]]
}
