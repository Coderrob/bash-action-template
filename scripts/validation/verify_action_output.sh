#!/bin/bash

#==============================================================================
#
#    Copyright (C) 2025 Robert Lindley
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#==============================================================================

#==============================================================================
# Action Test Verification Script
#==============================================================================
# Description: Verifies GitHub Action outputs against expected values
# Version:     1.0.0
# Author:      GitHub Action Template
# License:     GPL-3.0
#
# Purpose:     This script verifies that GitHub Action outputs match
#              expected values, providing clear pass/fail feedback.
#
# Usage:       ./verify_action_output.sh [OPTIONS] ACTUAL_OUTPUT EXPECTED_OUTPUT
#
# Examples:    ./verify_action_output.sh "TEST-VALUE" "TEST-VALUE"
#              ./verify_action_output.sh --test-name "default" "OUTPUT" "EXPECTED"
#==============================================================================

set -euo pipefail

# Source utility functions
# shellcheck source=../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

# Source script initialization library
# shellcheck source=../lib/script_init.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/script_init.sh"

# Initialize script
init_script "verify_action_output" "info" "true"

# Configuration
TEST_NAME=""
ACTUAL_OUTPUT=""
EXPECTED_OUTPUT=""

# Display usage information
show_usage() {
    cat <<EOF
Usage: ${0} [OPTIONS] ACTUAL_OUTPUT EXPECTED_OUTPUT

Verifies GitHub Action outputs against expected values.

OPTIONS:
    --test-name NAME    Name of the test for logging (optional)
    --input INPUT       Input value that produced the output (optional)
    -h, --help          Show this help message

ARGUMENTS:
    ACTUAL_OUTPUT       The actual output from the action
    EXPECTED_OUTPUT     The expected output value

EXIT CODES:
    0 - Test passed (output matches expected)
    1 - Test failed (output doesn't match expected)
    2 - Invalid arguments or usage

EXAMPLES:
    ${0} "TEST-VALUE" "TEST-VALUE"
    ${0} --test-name "default" "OUTPUT" "EXPECTED"
    ${0} --test-name "custom" --input "test" "TEST" "TEST"
EOF
}

# Parse command line arguments
parse_arguments() {
    local test_name=""
    local input_value=""

    while [[ $# -gt 0 ]]; do
        case $1 in
        --test-name)
            test_name="$2"
            shift 2
            ;;
        --input)
            input_value="$2"
            shift 2
            ;;
        -h | --help)
            show_usage
            exit 0
            ;;
        -*)
            log_error "verify" "Unknown option: $1"
            show_usage >&2
            exit 2
            ;;
        *)
            if [[ -z "${ACTUAL_OUTPUT}" ]]; then
                ACTUAL_OUTPUT="$1"
            elif [[ -z "${EXPECTED_OUTPUT}" ]]; then
                EXPECTED_OUTPUT="$1"
            else
                log_error "verify" "Too many arguments provided"
                show_usage >&2
                exit 2
            fi
            shift
            ;;
        esac
    done

    # Set defaults and validate
    TEST_NAME="${test_name:-action-test}"
    INPUT_VALUE="${input_value}"

    validate_required "ACTUAL_OUTPUT" "Actual output is required" || {
        show_usage >&2
        exit "${EXIT_INVALID_ARGS}"
    }

    validate_required "EXPECTED_OUTPUT" "Expected output is required" || {
        show_usage >&2
        exit "${EXIT_INVALID_ARGS}"
    }

    # Export for use in other functions
    export TEST_NAME ACTUAL_OUTPUT EXPECTED_OUTPUT INPUT_VALUE
}

# Verify action output
verify_action_output() {
    local test_context="${TEST_NAME}"

    # Add input context if provided
    if [[ -n "${INPUT_VALUE}" ]]; then
        test_context="${test_context} (input: '${INPUT_VALUE}')"
    fi

    log_info "verify" "Testing ${test_context}"
    log_info "verify" "Actual output: '${ACTUAL_OUTPUT}'"
    log_info "verify" "Expected output: '${EXPECTED_OUTPUT}'"

    if [[ "${ACTUAL_OUTPUT}" == "${EXPECTED_OUTPUT}" ]]; then
        log_info "verify" "✅ ${TEST_NAME} test passed"

        # Record success event if summary is enabled
        if [[ "${INCLUDE_SUMMARY:-false}" == "true" ]]; then
            record_event "test" "${TEST_NAME} test passed" "actual=${ACTUAL_OUTPUT},expected=${EXPECTED_OUTPUT}"
        fi

        return 0
    else
        log_error "verify" "❌ ${TEST_NAME} test failed"
        log_error "verify" "Expected '${EXPECTED_OUTPUT}' but got '${ACTUAL_OUTPUT}'"

        # Record error event if summary is enabled
        if [[ "${INCLUDE_SUMMARY:-false}" == "true" ]]; then
            record_error "test" "${TEST_NAME} test failed" "actual=${ACTUAL_OUTPUT},expected=${EXPECTED_OUTPUT}"
        fi

        return 1
    fi
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Verify the action output
    if verify_action_output; then
        exit 0
    else
        exit 1
    fi
}

# Run main function if script is executed directly
if is_main_execution; then
    main "$@"
fi
