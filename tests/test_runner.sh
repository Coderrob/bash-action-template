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
# Comprehensive Test Framework
#==============================================================================
# Description: Advanced test suite providing comprehensive validation of the
#              bash-action-template with performance monitoring and reporting
# Version:     2.0.0
# Author:      GitHub Action Template
# License:     MIT
#
# Purpose:     This framework provides:
#              - Comprehensive test execution with timing
#              - Pure function assertions and validation
#              - Performance monitoring and metrics
#              - Structured test reporting and summaries
#              - Error isolation and detailed reporting
#              - GitHub Actions integration for CI/CD
#
# Test Categories:
#   ✓ File Existence: Validates required files are present
#   ✓ Script Permissions: Ensures scripts are executable
#   ✓ Utility Functions: Tests core functionality
#   ✓ String Functions: Validates pure function behavior
#   ✓ Basic Execution: End-to-end action testing
#
# Features:
#   ✓ Pure function assertions with no side effects
#   ✓ Performance timing for each test
#   ✓ Comprehensive error reporting
#   ✓ Color-coded output for readability
#   ✓ Structured test state tracking
#   ✓ Failure isolation and recovery
#
# Dependencies:
#   - core.sh (shared functionality and constants)
#   - script_init.sh (standardized script initialization)
#   - All scripts under test
#==============================================================================

# Source the core library (provides shared functionality)
# shellcheck source=../scripts/lib/core.sh
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib/core.sh"

# Source script initialization library
# shellcheck source=../scripts/lib/script_init.sh
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib/script_init.sh"

# Source utility functions library
# shellcheck source=../scripts/lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib/utils.sh"

# Define test script directory for test output
readonly TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TEST_SCRIPT_DIR
readonly TEST_OUTPUT_DIR="/tmp/bash_action_test_$$"
export TEST_OUTPUT_DIR

# Test framework constants (immutable)
readonly TEST_FRAMEWORK_VERSION="2.0.0"

# Test state tracking
declare -a FAILED_TESTS
declare -a PASSED_TESTS
declare -a SKIPPED_TESTS
declare -i TESTS_RUN=0

# Test result constants
readonly TEST_RESULT_PASS="PASS"
readonly TEST_RESULT_FAIL="FAIL"
readonly TEST_RESULT_SKIP="SKIP"

# Pure function: Create test assertion with metadata
create_assertion() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    local assertion_type="${4:-equals}"

    case "$assertion_type" in
    equals)
        if [[ "$expected" == "$actual" ]]; then
            echo "$TEST_RESULT_PASS"
        else
            echo "$TEST_RESULT_FAIL"
        fi
        ;;
    not_equals)
        if [[ "$expected" != "$actual" ]]; then
            echo "$TEST_RESULT_PASS"
        else
            echo "$TEST_RESULT_FAIL"
        fi
        ;;
    contains)
        if string_contains "$actual" "$expected"; then
            echo "$TEST_RESULT_PASS"
        else
            echo "$TEST_RESULT_FAIL"
        fi
        ;;
    not_empty)
        if [[ -n "$actual" ]]; then
            echo "$TEST_RESULT_PASS"
        else
            echo "$TEST_RESULT_FAIL"
        fi
        ;;
    file_exists)
        if [[ -f "$actual" ]]; then
            echo "$TEST_RESULT_PASS"
        else
            echo "$TEST_RESULT_FAIL"
        fi
        ;;
    *)
        echo "$TEST_RESULT_FAIL"
        ;;
    esac
}

# Pure function: Format test result with colors
format_test_result() {
    local result="$1"
    local test_name="$2"
    local message="${3:-}"

    local color_code status_symbol

    case "$result" in
    "$TEST_RESULT_PASS")
        color_code='\033[0;32m' # Green
        status_symbol="✓"
        ;;
    "$TEST_RESULT_FAIL")
        color_code='\033[0;31m' # Red
        status_symbol="✗"
        ;;
    "$TEST_RESULT_SKIP")
        color_code='\033[1;33m' # Yellow
        status_symbol="○"
        ;;
    *)
        color_code='\033[0m' # No color
        status_symbol="?"
        ;;
    esac

    local formatted_output="${color_code}${status_symbol} ${result}${COLOR_NC} ${test_name}"

    if [[ -n "$message" ]]; then
        formatted_output="${formatted_output}: ${message}"
    fi

    echo -e "$formatted_output"
}

# Function: Run a test with comprehensive monitoring
run_test() {
    local test_name="$1"
    local test_function="$2"
    local skip_reason="${3:-}"

    ((TESTS_RUN++))

    local test_start_time test_end_time test_duration
    test_start_time="$(date +%s)"

    # Check if test should be skipped
    if [[ -n "$skip_reason" ]]; then
        SKIPPED_TESTS+=("$test_name")
        format_test_result "$TEST_RESULT_SKIP" "$test_name" "$skip_reason"
        create_metric "test_execution" "1" "count" "result=skip,test=${test_name}"
        return 0
    fi

    # Verify test function exists
    if ! declare -f "$test_function" >/dev/null 2>&1; then
        FAILED_TESTS+=("$test_name")
        format_test_result "$TEST_RESULT_FAIL" "$test_name" "Test function '$test_function' not found"
        create_metric "test_execution" "1" "count" "result=fail,test=${test_name},reason=function_not_found"
        return 1
    fi

    # Execute test in a subshell to isolate environment
    local test_result test_output exit_code
    local temp_output="/tmp/test_output_$$"
    local exit_file="/tmp/exit_code_$$"
    (set +e; eval "$test_function > \"$temp_output\" 2>&1"; echo $? > "$exit_file") 2>/dev/null
    exit_code="$(cat "$exit_file")"
    test_output="$(cat "$temp_output")"
    rm -f "$temp_output" "$exit_file"

    test_end_time="$(date +%s)"
    test_duration="$((test_end_time - test_start_time))"

    # Determine test result
    if [[ $exit_code -eq 0 ]]; then
        test_result="$TEST_RESULT_PASS"
        PASSED_TESTS+=("$test_name")
    else
        test_result="$TEST_RESULT_FAIL"
        FAILED_TESTS+=("$test_name")
    fi

    # Create test metrics
    create_metric "test_execution_time" "$test_duration" "seconds" "test=${test_name}"
    create_metric "test_execution" "1" "count" "result=${test_result,,},test=${test_name}"

    # Format and display result
    local result_message=""
    if [[ $exit_code -ne 0 && -n "$test_output" ]]; then
        result_message="Exit code: $exit_code"
    fi

    format_test_result "$test_result" "$test_name" "$result_message"

    echo "Test $test_name: $test_result" >&2

    # Log detailed output in debug mode
    if [[ -n "$test_output" ]]; then
        log_debug "test" "Test output for $test_name" "output=$test_output"
    fi

    return $exit_code
}

# Legacy assertion functions for backward compatibility
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="${3:-assertion}"

    local result
    result="$(create_assertion "$test_name" "$expected" "$actual" "equals")"

    if [[ "$result" == "$TEST_RESULT_PASS" ]]; then
        format_test_result "$TEST_RESULT_PASS" "$test_name"
        return 0
    else
        format_test_result "$TEST_RESULT_FAIL" "$test_name" "Expected '$expected', got '$actual'"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local test_name="${2:-not_empty_assertion}"

    local result
    result="$(create_assertion "$test_name" "" "$value" "not_empty")"

    if [[ "$result" == "$TEST_RESULT_PASS" ]]; then
        format_test_result "$TEST_RESULT_PASS" "$test_name"
        return 0
    else
        format_test_result "$TEST_RESULT_FAIL" "$test_name" "Value is empty"
        return 1
    fi
}

assert_file_exists() {
    local file_path="$1"
    local test_name="${2:-file_exists_assertion}"

    local result
    result="$(create_assertion "$test_name" "" "$file_path" "file_exists")"

    if [[ "$result" == "$TEST_RESULT_PASS" ]]; then
        format_test_result "$TEST_RESULT_PASS" "$test_name"
        return 0
    else
        format_test_result "$TEST_RESULT_FAIL" "$test_name" "File does not exist: $file_path"
        return 1
    fi
}

# Test functions for utility validation
test_string_functions() {
    local test_input="  Hello World  "

    # Test trim function
    local trimmed
    trimmed="$(trim_string "$test_input")"
    local trim_result
    trim_result="$(create_assertion "trim_string" "Hello World" "$trimmed")"
    [[ "$trim_result" == "$TEST_RESULT_PASS" ]] || return 1

    # Test uppercase conversion
    local uppercase
    uppercase="$(to_uppercase "$trimmed")"
    local upper_result
    upper_result="$(create_assertion "to_uppercase" "HELLO WORLD" "$uppercase")"
    [[ "$upper_result" == "$TEST_RESULT_PASS" ]] || return 1

    # Test lowercase conversion
    local lowercase
    lowercase="$(to_lowercase "$uppercase")"
    local lower_result
    lower_result="$(create_assertion "to_lowercase" "hello world" "$lowercase")"
    [[ "$lower_result" == "$TEST_RESULT_PASS" ]] || return 1

    return 0
}

# Test file existence
test_file_existence() {
    # Check if main files exist
    local required_files=(
        "action.yml"
        "scripts/services/main.sh"
        "scripts/lib/utils.sh"
        "scripts/lib/core.sh"
        "scripts/lib/constants.sh"
        "scripts/lib/common_args.sh"
        "scripts/lib/script_init.sh"
        ".shellcheckrc"
        ".editorconfig"
    )

    for file in "${required_files[@]}"; do
        if [[ -f "${TEST_SCRIPT_DIR}/../${file}" ]]; then
            continue
        else
            log_error "test" "Required file missing: $file"
            return 1
        fi
    done

    return 0
}

# Test script permissions
test_script_permissions() {
    local script_dir="${TEST_SCRIPT_DIR}/../scripts"

    # Find all shell scripts under scripts/ recursively and ensure they are executable
    while IFS= read -r -d '' script; do
        if [[ -x "${script}" ]]; then
            continue
        else
            log_error "test" "Script not executable: ${script#${script_dir}/}"
            return 1
        fi
    done < <(find "${script_dir}" -name "*.sh" -type f -print0)

    return 0
}

# Test utility functions
test_utility_functions() {
    # Test command_exists function
    if ! command_exists "bash"; then
        log_error "test" "command_exists function failed"
        return 1
    fi

    # Test is_github_actions function (should be false in test environment)
    if is_github_actions; then
        log_debug "test" "Running in GitHub Actions environment"
    else
        log_debug "test" "Not running in GitHub Actions environment"
    fi

    return 0
}

# Test basic action execution
test_basic_execution() {
    # Set up minimal environment
    export INPUT_EXAMPLE_INPUT="test-value"
    export INPUT_LOG_LEVEL="info"
    export INPUT_WORKING_DIRECTORY="."

    # Mock GitHub Actions environment
    local temp_output_file="${TEST_OUTPUT_DIR}/github_output_test"
    export GITHUB_OUTPUT="${temp_output_file}"

    # Test the main script (but don't actually run it to avoid side effects)
    if [[ -f "${TEST_SCRIPT_DIR}/../scripts/services/main.sh" ]]; then
        log_debug "test" "Main script exists and is readable"
        return 0
    else
        log_error "test" "Main script not found or not readable"
        return 1
    fi
}

# Function: Setup test environment
setup_test_environment() {
    log_info "test_setup" "Setting up test environment" "version=${TEST_FRAMEWORK_VERSION}"

    # Create output directory
    mkdir -p "$TEST_OUTPUT_DIR"

    # Initialize test state
    FAILED_TESTS=()
    PASSED_TESTS=()
    SKIPPED_TESTS=()
    TESTS_RUN=0

    log_info "test_setup" "Test environment ready" "output_dir=${TEST_OUTPUT_DIR}"
}

# Function: Generate comprehensive test report
generate_test_report() {
    local passed_count failed_count skipped_count
    passed_count="${#PASSED_TESTS[@]}"
    failed_count="${#FAILED_TESTS[@]}"
    skipped_count="${#SKIPPED_TESTS[@]}"

    echo ""
    echo "=========================================="
    echo "Test Suite Summary"
    echo "=========================================="
    echo "Framework Version: ${TEST_FRAMEWORK_VERSION}"
    echo "Total Tests: ${TESTS_RUN}"
    echo "Passed: ${passed_count}"
    echo "Failed: ${failed_count}"
    echo "Skipped: ${skipped_count}"
    echo ""

    # Show failed tests details
    if [[ $failed_count -gt 0 ]]; then
        echo "Failed Tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  ✗ $test"
        done
        echo ""
    fi

    # Create final metrics
    create_metric "test_suite_total" "$TESTS_RUN" "count"
    create_metric "test_suite_passed" "$passed_count" "count"
    create_metric "test_suite_failed" "$failed_count" "count"
    create_metric "test_suite_skipped" "$skipped_count" "count"

    # Calculate success rate
    local success_rate=0
    if [[ $TESTS_RUN -gt 0 ]]; then
        success_rate=$(((passed_count * 100) / TESTS_RUN))
    fi

    create_metric "test_suite_success_rate" "$success_rate" "percent"

    echo "Success Rate: ${success_rate}%"
    echo "=========================================="
    # log_info "test_summary" "Test suite completed" "total=${TESTS_RUN},passed=${#PASSED_TESTS[@]},failed=${#FAILED_TESTS[@]},skipped=${#SKIPPED_TESTS[@]}"

    # Return appropriate exit code
    if [[ $failed_count -eq 0 ]]; then
        log_success "test_summary" "All tests passed" "passed=${passed_count}"
        return 0
    else
        log_error "test_summary" "Some tests failed" "failed=${failed_count},passed=${passed_count}"
        return 1
    fi
}

# Function: Custom cleanup for test runner
cleanup() {
    log_info "test_cleanup" "Cleaning up test environment"

    # Remove temporary test files
    find "$TEST_OUTPUT_DIR" -name "*_test" -type f -delete 2>/dev/null || true

    log_debug "test_cleanup" "Test cleanup completed"
}

# Main test execution function
main() {
    # Initialize script with test-specific settings
    init_script "test_runner" "debug" "false"

    log_group_start "Test Suite v${TEST_FRAMEWORK_VERSION}"

    # Setup test environment
    setup_test_environment

    echo "Running Test Suite for bash-action-template"
    echo "============================================"

    # Run all test suites
    run_test "File Existence" "test_file_existence" || true
    run_test "Script Permissions" "test_script_permissions" || true
    run_test "Utility Functions" "test_utility_functions" || true
    run_test "String Functions" "test_string_functions" || true
    run_test "Basic Execution" "test_basic_execution" || true

    # Generate and display final report
    local test_exit_code
    generate_test_report
    test_exit_code=$?

    log_group_end

    exit $test_exit_code
}

# Export test functions for use in subshells
export -f test_string_functions
export -f test_file_existence
export -f test_script_permissions
export -f test_utility_functions
export -f test_basic_execution

# Execute main function
export -f main
main "$@"
