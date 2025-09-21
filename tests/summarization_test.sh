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

# Test script for summarization template output validation
# This script tests that template placeholders are correctly mapped to values

set -euo pipefail

# Source the summary functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/summary.sh"

# Initialize arrays that might not be properly initialized
EVENTS=()
WARNINGS=()
ERRORS=()

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_pass() {
    local test_name="$1"
    echo "✅ PASS: $test_name"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    echo "❌ FAIL: $test_name - $reason"
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    if [[ "$haystack" == *"$needle"* ]]; then
        test_pass "$test_name"
    else
        test_fail "$test_name" "Expected to contain '$needle'"
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    if [[ "$haystack" != *"$needle"* ]]; then
        test_pass "$test_name"
    else
        test_fail "$test_name" "Expected not to contain '$needle'"
    fi
}

assert_equals() {
    local actual="$1"
    local expected="$2"
    local test_name="$3"

    if [[ "$actual" == "$expected" ]]; then
        test_pass "$test_name"
    else
        test_fail "$test_name" "Expected '$expected', got '$actual'"
    fi
}

# Test: Basic template placeholder replacement
test_basic_template_replacement() {
    echo "🧪 Testing basic summary functionality..."

    # Reset summary data for clean test
    SUMMARY_DATA["start_time"]=""
    SUMMARY_DATA["end_time"]=""
    SUMMARY_DATA["execution_time"]=""
    SUMMARY_DATA["status"]="running"
    SUMMARY_DATA["inputs"]=""
    SUMMARY_DATA["outputs"]=""
    SUMMARY_DATA["events"]=""
    SUMMARY_DATA["warnings"]=""
    SUMMARY_DATA["errors"]=""
    EVENTS=()
    WARNINGS=()
    ERRORS=()

    # Initialize summary
    init_summary
    set_summary_input "test_input" "test_value"
    set_summary_output "test_output" "output_value"
    record_event "test" "Test event occurred"
    finalize_summary "success"

    # Test JSON summary generation
    local json_summary
    json_summary=$(generate_json_summary)

    if [[ "$json_summary" == *'"status":"success"'* ]]; then
        test_pass "Status should be in JSON"
    else
        test_fail "Status should be in JSON" "Status not found"
    fi

    if [[ "$json_summary" == *'"test_value"'* ]]; then
        test_pass "Input value should be in JSON"
    else
        test_fail "Input value should be in JSON" "Input not found"
    fi

    if [[ "$json_summary" == *'"output_value"'* ]]; then
        test_pass "Output value should be in JSON"
    else
        test_fail "Output value should be in JSON" "Output not found"
    fi

    if [[ "$json_summary" == *'"Test event occurred"'* ]]; then
        test_pass "Event message should be in JSON"
    else
        test_fail "Event message should be in JSON" "Event not found"
    fi
}

# Test: Template with no data
test_empty_template_replacement() {
    echo "🧪 Testing summary with no data..."

    # Reset summary data for clean test
    SUMMARY_DATA["start_time"]=""
    SUMMARY_DATA["end_time"]=""
    SUMMARY_DATA["execution_time"]=""
    SUMMARY_DATA["status"]="running"
    SUMMARY_DATA["inputs"]=""
    SUMMARY_DATA["outputs"]=""
    SUMMARY_DATA["events"]=""
    SUMMARY_DATA["warnings"]=""
    SUMMARY_DATA["errors"]=""
    EVENTS=()
    WARNINGS=()
    ERRORS=()

    init_summary
    finalize_summary "completed"

    local json_summary
    json_summary=$(generate_json_summary)

    if [[ "$json_summary" == *'"status":"completed"'* ]]; then
        test_pass "Status should be completed"
    else
        test_fail "Status should be completed" "Status not found"
    fi

    if [[ "$json_summary" == *'"inputs":null'* ]]; then
        test_pass "Inputs should be null"
    else
        test_fail "Inputs should be null" "Inputs not null"
    fi

    if [[ "$json_summary" == *'"events":[]'* ]]; then
        test_pass "Events should be empty array"
    else
        test_fail "Events should be empty array" "Events not empty"
    fi
}

# Test: Template with warnings and errors
test_warnings_errors_template() {
    echo "🧪 Testing template with warnings and errors..."

    # Reset summary data for clean test
    SUMMARY_DATA["start_time"]=""
    SUMMARY_DATA["end_time"]=""
    SUMMARY_DATA["execution_time"]=""
    SUMMARY_DATA["status"]="running"
    SUMMARY_DATA["inputs"]=""
    SUMMARY_DATA["outputs"]=""
    SUMMARY_DATA["events"]=""
    SUMMARY_DATA["warnings"]=""
    SUMMARY_DATA["errors"]=""
    EVENTS=()
    WARNINGS=()
    ERRORS=()

    init_summary
    record_warning "validation" "Invalid input detected"
    record_error "processing" "Failed to process data"
    finalize_summary "failed"

    local summary
    summary=$(generate_markdown_summary "Error Summary")

    if [[ "$summary" == *"Invalid input detected"* ]]; then
        test_pass "Warning should be present"
    else
        test_fail "Warning should be present" "Warning not found"
    fi

    if [[ "$summary" == *"Failed to process data"* ]]; then
        test_pass "Error should be present"
    else
        test_fail "Error should be present" "Error not found"
    fi

    if [[ "$summary" == *"failed"* ]]; then
        test_pass "Status should be 'failed'"
    else
        test_fail "Status should be 'failed'" "Status not found"
    fi
}

# Test: JSON summary format validation
test_json_summary_format() {
    echo "🧪 Testing JSON summary format..."

    # Reset summary data for clean test
    SUMMARY_DATA["start_time"]=""
    SUMMARY_DATA["end_time"]=""
    SUMMARY_DATA["execution_time"]=""
    SUMMARY_DATA["status"]="running"
    SUMMARY_DATA["inputs"]=""
    SUMMARY_DATA["outputs"]=""
    SUMMARY_DATA["events"]=""
    SUMMARY_DATA["warnings"]=""
    SUMMARY_DATA["errors"]=""
    EVENTS=()
    WARNINGS=()
    ERRORS=()

    init_summary
    set_summary_input "key1" "value1"
    set_summary_output "out1" "result1"
    record_event "test" "event message"
    finalize_summary "success"

    local json_summary
    json_summary=$(generate_json_summary)

    if [[ "$json_summary" == *'{"start_time":'* ]]; then
        test_pass "JSON should start with start_time"
    else
        test_fail "JSON should start with start_time" "Invalid JSON format"
    fi

    if [[ "$json_summary" == *'"status":"success"'* ]]; then
        test_pass "Status should be in JSON"
    else
        test_fail "Status should be in JSON" "Status not found"
    fi

    if [[ "$json_summary" == *'"inputs":{"key1":"value1"}'* ]]; then
        test_pass "Inputs should be in JSON"
    else
        test_fail "Inputs should be in JSON" "Inputs not found"
    fi

    if [[ "$json_summary" == *'"outputs":{"out1":"result1"}'* ]]; then
        test_pass "Outputs should be in JSON"
    else
        test_fail "Outputs should be in JSON" "Outputs not found"
    fi
}

# Test: Multiple inputs/outputs handling
test_multiple_inputs_outputs() {
    echo "🧪 Testing multiple inputs and outputs..."

    # Reset summary data for clean test
    SUMMARY_DATA["start_time"]=""
    SUMMARY_DATA["end_time"]=""
    SUMMARY_DATA["execution_time"]=""
    SUMMARY_DATA["status"]="running"
    SUMMARY_DATA["inputs"]=""
    SUMMARY_DATA["outputs"]=""
    SUMMARY_DATA["events"]=""
    SUMMARY_DATA["warnings"]=""
    SUMMARY_DATA["errors"]=""
    EVENTS=()
    WARNINGS=()
    ERRORS=()

    init_summary
    set_summary_input "input1" "value1"
    set_summary_input "input2" "value2"
    set_summary_output "output1" "result1"
    set_summary_output "output2" "result2"
    finalize_summary "success"

    local summary
    summary=$(generate_markdown_summary "Multi IO Summary")

    if [[ "$summary" == *"input1: value1"* ]]; then
        test_pass "First input should be present"
    else
        test_fail "First input should be present" "Input not found"
    fi

    if [[ "$summary" == *"input2: value2"* ]]; then
        test_pass "Second input should be present"
    else
        test_fail "Second input should be present" "Input not found"
    fi

    if [[ "$summary" == *"output1: result1"* ]]; then
        test_pass "First output should be present"
    else
        test_fail "First output should be present" "Output not found"
    fi

    if [[ "$summary" == *"output2: result2"* ]]; then
        test_pass "Second output should be present"
    else
        test_fail "Second output should be present" "Output not found"
    fi
}

# Test: Special characters in values
test_special_characters() {
    echo "🧪 Testing special characters in values..."

    init_summary
    set_summary_input "special" 'value with "quotes" & <tags>'
    record_event "test" 'Message with "quotes" and \backslashes'
    finalize_summary "success"

    local json_summary
    json_summary=$(generate_json_summary)

    if [[ "$json_summary" == *'value with '* && "$json_summary" == *'quotes'* && "$json_summary" == *'<tags>'* ]]; then
        test_pass "Special characters should be preserved in inputs"
    else
        test_fail "Special characters should be preserved in inputs" "Special chars not found in input"
    fi

    if [[ "$json_summary" == *'Message with '* && "$json_summary" == *'quotes'* && "$json_summary" == *'backslashes'* ]]; then
        test_pass "Event message should be present"
    else
        test_fail "Event message should be present" "Event message not found"
    fi
}

# Run all tests
run_tests() {
    echo "🚀 Running summarization template validation tests..."
    echo

    test_basic_template_replacement
    echo "Completed basic test"
    test_empty_template_replacement
    echo "Completed empty test"
    test_warnings_errors_template
    echo "Completed warnings test"
    test_json_summary_format
    echo "Completed JSON test"
    test_multiple_inputs_outputs
    echo "Completed multi IO test"
    test_special_characters
    echo "Completed special chars test"

    echo
    echo "📊 Test Results:"
    echo "   Total: $TESTS_RUN"
    echo "   Passed: $TESTS_PASSED"
    echo "   Failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "🎉 All tests passed!"
        return 0
    else
        echo "💥 Some tests failed!"
        return 1
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
