#!/bin/bash

# Test suite for the bash action template
# This script runs basic tests to validate the action functionality

set -euo pipefail

# Source the utility functions for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/utils.sh
source "${SCRIPT_DIR}/../scripts/utils.sh"

# Test configuration
readonly TEST_OUTPUT_DIR="${SCRIPT_DIR}/output"
FAILED_TESTS=()

# Colors for test output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Setup test environment
setup_tests() {
    echo "Setting up test environment..."
    mkdir -p "${TEST_OUTPUT_DIR}"
    
    # Initialize logging
    init_logging "debug"
}

# Cleanup test environment
cleanup_tests() {
    echo "Cleaning up test environment..."
    rm -rf "${TEST_OUTPUT_DIR}"
}

# Test helper functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="${3:-assertion}"
    
    ((TESTS_RUN++))
    
    echo "Debug: Comparing '${expected}' with '${actual}' for test '${test_name}'"
    
    if [[ "${expected}" == "${actual}" ]]; then
        echo -e "${GREEN}✓${NC} ${test_name}: PASSED"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} ${test_name}: FAILED"
        echo "  Expected: ${expected}"
        echo "  Actual: ${actual}"
        FAILED_TESTS+=("${test_name}")
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local test_name="${2:-not_empty_assertion}"
    
    ((TESTS_RUN++))
    
    if [[ -n "${value}" ]]; then
        echo -e "${GREEN}✓${NC} ${test_name}: PASSED"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} ${test_name}: FAILED - Value is empty"
        FAILED_TESTS+=("${test_name}")
    fi
}

assert_file_exists() {
    local file_path="$1"
    local test_name="${2:-file_exists_assertion}"
    
    ((TESTS_RUN++))
    
    if [[ -f "${file_path}" ]]; then
        echo -e "${GREEN}✓${NC} ${test_name}: PASSED"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} ${test_name}: FAILED - File does not exist: ${file_path}"
        FAILED_TESTS+=("${test_name}")
    fi
}

# Test utility functions
test_logging_functions() {
    echo "Testing logging functions..."
    
    # Test log level initialization
    echo "Testing debug level..."
    init_logging "debug"
    echo "LOG_LEVEL is now: ${LOG_LEVEL}"
    echo "LOG_LEVEL_DEBUG is: ${LOG_LEVEL_DEBUG}"
    assert_equals "${LOG_LEVEL_DEBUG}" "${LOG_LEVEL}" "debug_log_level_init"
    
    echo "Testing info level..."
    init_logging "info"
    assert_equals "${LOG_LEVEL_INFO}" "${LOG_LEVEL}" "info_log_level_init"
    
    echo "Testing warn level..."
    init_logging "warn"
    assert_equals "${LOG_LEVEL_WARN}" "${LOG_LEVEL}" "warn_log_level_init"
    
    echo "Testing error level..."
    init_logging "error"
    assert_equals "${LOG_LEVEL_ERROR}" "${LOG_LEVEL}" "error_log_level_init"
    
    echo "Testing invalid level..."
    # Test invalid log level (should default to info)
    init_logging "invalid"
    assert_equals "${LOG_LEVEL_INFO}" "${LOG_LEVEL}" "invalid_log_level_defaults_to_info"
    
    echo "Logging function tests completed"
}

test_file_operations() {
    echo "Testing file operations..."
    
    local test_file="${TEST_OUTPUT_DIR}/test_file.txt"
    local test_content="Hello, World!"
    
    # Test safe_write_file
    safe_write_file "${test_file}" "${test_content}"
    assert_file_exists "${test_file}" "safe_write_file_creates_file"
    
    # Test safe_read_file
    local read_content
    read_content=$(safe_read_file "${test_file}")
    assert_equals "${test_content}" "${read_content}" "safe_read_file_returns_correct_content"
    
    # Test reading non-existent file
    if safe_read_file "/non/existent/file" >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} safe_read_file_handles_missing_file: FAILED - Should have failed"
        FAILED_TESTS+=("safe_read_file_handles_missing_file")
    else
        echo -e "${GREEN}✓${NC} safe_read_file_handles_missing_file: PASSED"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
}

test_utility_helpers() {
    echo "Testing utility helper functions..."
    
    # Test command_exists
    if command_exists "bash"; then
        echo -e "${GREEN}✓${NC} command_exists_bash: PASSED"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} command_exists_bash: FAILED"
        FAILED_TESTS+=("command_exists_bash")
    fi
    ((TESTS_RUN++))
    
    if command_exists "non_existent_command_12345"; then
        echo -e "${RED}✗${NC} command_exists_negative: FAILED - Should not exist"
        FAILED_TESTS+=("command_exists_negative")
    else
        echo -e "${GREEN}✓${NC} command_exists_negative: PASSED"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
    
    # Test generate_random_string
    local random_string
    random_string=$(generate_random_string 16)
    if [[ ${#random_string} -eq 16 ]]; then
        echo -e "${GREEN}✓${NC} generate_random_string_length: PASSED"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} generate_random_string_length: FAILED - Expected 16, got ${#random_string}"
        FAILED_TESTS+=("generate_random_string_length")
    fi
    ((TESTS_RUN++))
    
    # Test URL encoding
    local test_url="hello world & test"
    local encoded_url
    encoded_url=$(url_encode "${test_url}")
    assert_not_empty "${encoded_url}" "url_encode_not_empty"
    
    # Test JSON escaping
    local test_json='{"key": "value with "quotes""}'
    local escaped_json
    escaped_json=$(json_escape "${test_json}")
    assert_not_empty "${escaped_json}" "json_escape_not_empty"
}

test_github_actions_functions() {
    echo "Testing GitHub Actions specific functions..."
    
    # Mock GitHub environment
    local temp_output_file="${TEST_OUTPUT_DIR}/github_output"
    local temp_env_file="${TEST_OUTPUT_DIR}/github_env"
    
    export GITHUB_OUTPUT="${temp_output_file}"
    export GITHUB_ENV="${temp_env_file}"
    
    # Test set_output
    set_output "test_key" "test_value"
    
    if [[ -f "${temp_output_file}" ]]; then
        local output_content
        output_content=$(cat "${temp_output_file}")
        assert_equals "test_key=test_value" "${output_content}" "set_output_writes_correctly"
    else
        echo -e "${RED}✗${NC} set_output_creates_file: FAILED"
        FAILED_TESTS+=("set_output_creates_file")
        ((TESTS_RUN++))
    fi
    
    # Test set_env
    set_env "TEST_ENV_VAR" "test_env_value"
    
    if [[ -f "${temp_env_file}" ]]; then
        local env_content
        env_content=$(cat "${temp_env_file}")
        assert_equals "TEST_ENV_VAR=test_env_value" "${env_content}" "set_env_writes_correctly"
    else
        echo -e "${RED}✗${NC} set_env_creates_file: FAILED"
        FAILED_TESTS+=("set_env_creates_file")
        ((TESTS_RUN++))
    fi
    
    # Clean up
    unset GITHUB_OUTPUT GITHUB_ENV
}

test_input_validation() {
    echo "Testing input validation..."
    
    # Test validate_inputs with valid data
    if validate_inputs "test_input" "." "info" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} validate_inputs_valid_data: PASSED"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} validate_inputs_valid_data: FAILED"
        FAILED_TESTS+=("validate_inputs_valid_data")
    fi
    ((TESTS_RUN++))
    
    # Test validate_inputs with invalid directory
    if validate_inputs "test_input" "/non/existent/directory" "info" >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} validate_inputs_invalid_directory: FAILED - Should have failed"
        FAILED_TESTS+=("validate_inputs_invalid_directory")
    else
        echo -e "${GREEN}✓${NC} validate_inputs_invalid_directory: PASSED"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
}

# Main test runner
run_tests() {
    echo "Running bash action template tests..."
    echo "=================================================="
    
    setup_tests
    
    test_logging_functions
    test_file_operations
    test_utility_helpers
    test_github_actions_functions
    test_input_validation
    
    cleanup_tests
    
    # Print test results
    echo "=================================================="
    echo "Test Results:"
    echo "  Tests run: ${TESTS_RUN}"
    echo "  Tests passed: ${TESTS_PASSED}"
    echo "  Tests failed: $((TESTS_RUN - TESTS_PASSED))"
    
    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Failed tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - ${test}"
        done
        echo ""
        exit 1
    else
        echo ""
        echo -e "${GREEN}All tests passed! 🎉${NC}"
        echo ""
        exit 0
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests "$@"
fi
