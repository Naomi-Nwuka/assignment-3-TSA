#!/bin/bash
set -uo pipefail

APP="./app/app.sh"
passed=0
failed=0

run_test() {
    local name="$1"
    shift
    local output status

    output=$("$@" 2>&1)
    status=$?

    if test_condition "$name" "$status" "$output"; then
        echo "PASS: $name"
        ((passed+=1))
    else
        echo "FAIL: $name"
        echo "  exit code: $status"
        echo "  output: $output"
        ((failed+=1))
    fi
}

test_condition() {
    local name="$1" status="$2" output="$3"
    case "$name" in
        help)              [[ $status -eq 0 && "$output" == *"Usage:"* ]] ;;
        system-info)       [[ $status -eq 0 && "$output" == *"System Information"* ]] ;;
        invalid-command)   [[ $status -eq 2 && "$output" == *"Error:"* ]] ;;
        missing-host)      [[ $status -eq 2 && "$output" == *"host"* ]] ;;
        valid-host)        [[ $status -eq 0 && "$output" == *"Host resolution: successful"* ]] ;;
        missing-port)      [[ $status -eq 2 && "$output" == *"host and port"* ]] ;;
        non-numeric-port)  [[ $status -eq 2 && "$output" == *"port must be an integer"* ]] ;;
        out-of-range-port) [[ $status -eq 2 && "$output" == *"port must be an integer"* ]] ;;
        *)                 return 1 ;;
    esac
}

run_test help "$APP" help
run_test system-info "$APP" system-info
run_test invalid-command "$APP" does-not-exist
run_test missing-host "$APP" check-host
run_test valid-host "$APP" check-host localhost
run_test missing-port "$APP" check-port localhost
run_test non-numeric-port "$APP" check-port localhost abc
run_test out-of-range-port "$APP" check-port localhost 65536

echo
echo "Test results: $passed passed, $failed failed."
[[ "$failed" -eq 0 ]]
