#!/bin/bash
set -euo pipefail

source /etc/os-release

TESTS_PATH=/usr/libexec/tests/osbuild-composer/
mkdir --parents /tmp/logs
LOGS_DIRECTORY=$(mktemp --directory --tmpdir=/tmp/logs)

PASSED_TESTS=()
FAILED_TESTS=()

TEST_CASES=(
    "regression-excluded-dependency.sh"
    "regression-include-excluded-packages.sh"
    "regression-composer-works-behind-satellite.sh"
)

# Print out a nice test divider so we know when tests stop and start.
test_divider () {
    printf "%0.s-" {1..78} && echo
}

# Run a test case and store the result as passed or failed.
run_test_case () {
    TEST_NAME=$(basename "$1")
    echo
    test_divider
    echo "🏃🏻 Running test: ${TEST_NAME}"
    test_divider

    if sudo "${1}" -test.v | tee "${LOGS_DIRECTORY}"/"${TEST_NAME}".log; then
        PASSED_TESTS+=("$TEST_NAME")
    else
        FAILED_TESTS+=("$TEST_NAME")
    fi

    test_divider
    echo
}


# Provision the software under test.
/usr/libexec/osbuild-composer-test/provision.sh

# Run test cases common for all distros.
for TEST_CASE in "${TEST_CASES[@]}"; do
    run_test_case ${TESTS_PATH}/"$TEST_CASE"
done

# Print a report of the test results.
test_divider
echo "😃 Passed tests:" "${PASSED_TESTS[@]}"
echo "☹ Failed tests:" "${FAILED_TESTS[@]}"
test_divider

# Exit with a failure if tests were executed and any of them failed.
if [ ${#PASSED_TESTS[@]} -gt 0 ] && [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    echo "🎉 All tests passed."
    exit 0
else
    echo "🔥 One or more tests failed."
    exit 1
fi
