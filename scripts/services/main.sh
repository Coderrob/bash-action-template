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
# GitHub Action: Bash Action Template
#==============================================================================
# Description: Production-ready main script demonstrating shell scripting best
#              practices, functional programming, and enterprise observability
# Version:     2.0.0
# Author:      GitHub Action Template
# License:     GPL-3.0
#
# Purpose:     This script serves as the primary entry point for the GitHub Action,
#              implementing zero-boilerplate initialization, pure functional
#              programming patterns, and comprehensive observability features.
#
# Dependencies:
#   - Bash 4.4+
#   - init.sh (centralized initialization)
#   - functional_utils.sh (pure function library)
#
# Environment Variables (GitHub Actions Inputs):
#   INPUT_USER_INPUT      - User-provided input for processing
#   INPUT_LOG_LEVEL       - Logging verbosity (debug|info|warn|error)
#   INPUT_INCLUDE_SUMMARY - Whether to generate execution summary (true|false)
#   INPUT_WORKING_DIRECTORY - Working directory for operations
#
# Outputs:
#   example-output        - Processed result from input transformation
#   execution-time        - Script execution duration in seconds
#   script-version        - Version of the action script
#
# Exit Codes:
#   0 - Success
#   1 - Validation errors or processing failures
#   2 - Environment compatibility issues
#==============================================================================

# Source the core library (provides logging, constants, and shared functionality)
# shellcheck source=../lib/core.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/core.sh"

# Source common argument parsing utilities
# shellcheck source=../lib/common_args.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common_args.sh"

# Source script initialization utilities
# shellcheck source=../lib/script_init.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/script_init.sh"

# Readonly global constants (immutable by design)
readonly ACTION_NAME="bash-action-template"
readonly ACTION_VERSION="2.0.0"
readonly MIN_BASH_VERSION="4.4"

# Immutable script metadata
# shellcheck disable=SC2155
readonly SCRIPT_START_TIME="$(date +%s)"

#==============================================================================
# Script Initialization
#==============================================================================

# Initialize logging with default level
init_logging "main" "${INPUT_LOG_LEVEL:-info}"

# Set up error handling
set -euo pipefail
trap 'handle_error "Unexpected error occurred" "$?"' ERR
trap 'handle_exit' EXIT
trap 'handle_interrupt' INT TERM

log_debug "init" "Initializing script: ${ACTION_NAME}" "version=${ACTION_VERSION}"

# Check rate limits if in GitHub Actions
if is_github_actions && ! check_github_rate_limit 50; then
    log_error "init" "Rate limit check failed, aborting execution"
    exit "${EXIT_FAILURE}"
fi

log_info "init" "Script initialization completed" "script=${ACTION_NAME},version=${ACTION_VERSION}"

#==============================================================================
# Error Handling Functions
#==============================================================================

# Handle unexpected errors
handle_error() {
    local message="$1"
    local exit_code="$2"

    log_error "error" "${message}" "exit_code=${exit_code}"

    # Set GitHub Actions output for execution time
    local execution_time=$(($(date +%s) - SCRIPT_START_TIME))
    set_output "execution-time" "${execution_time}"

    exit "${exit_code}"
}

# Handle normal script exit
handle_exit() {
    local exit_code="$?"

    # Set GitHub Actions output for execution time
    local execution_time=$(($(date +%s) - SCRIPT_START_TIME))
    set_output "execution-time" "${execution_time}"

    log_debug "cleanup" "Script exiting" "exit_code=${exit_code}"
}

# Handle interrupt signals
handle_interrupt() {
    log_warn "interrupt" "Script interrupted by user"
    exit "${EXIT_FAILURE}"
}

#==============================================================================
# Function: validate_bash_version
#==============================================================================
# Description: Validates that the current Bash version meets minimum requirements
#              for functional programming features and script compatibility
#
# Behavioral Contract:
#   - Pure function with no side effects
#   - Immutable parameter handling
#   - Deterministic output for same inputs
#   - Comprehensive logging of validation results
#
# Parameters:
#   $1 (required_version) - Minimum required Bash version (format: "X.Y")
#
# Returns:
#   0 - Bash version meets or exceeds requirements
#   1 - Bash version is below minimum requirements
#
# Side Effects:
#   - Logs debug information about version check
#   - Logs error if version requirements not met
#
# Example Usage:
#   validate_bash_version "4.4" || exit 2
#   validate_bash_version "${MIN_BASH_VERSION}"
#
# Dependencies:
#   - log_error, log_debug functions from init.sh
#   - BASH_VERSION environment variable
#==============================================================================
validate_bash_version() {
    local required_version="$1"
    local current_version="${BASH_VERSION%%.*}"

    if [[ "${current_version}" -lt "${required_version%%.*}" ]]; then
        log_error "compatibility" "Bash version ${current_version} is below required ${required_version}"
        return 1
    fi

    log_debug "compatibility" "Bash version check passed" "current=${BASH_VERSION},required=${required_version}"
    return 0
}

#==============================================================================
# Function: process_example_input
#==============================================================================
# Description: Processes user input through a functional pipeline applying
#              sanitization, trimming, and case transformation
#
# Behavioral Contract:
#   - Pure function with immutable parameter handling
#   - Input sanitization prevents injection attacks
#   - Functional composition of string operations
#   - Comprehensive metrics collection during processing
#   - Deterministic transformation pipeline
#
# Parameters:
#   $1 (input) - Raw input string to be processed
#
# Processing Pipeline:
#   1. sanitize_input() - Remove potentially harmful characters
#   2. trim_string()    - Remove leading/trailing whitespace
#   3. to_uppercase()   - Convert to uppercase for consistency
#   4. Metrics collection for input/output lengths
#
# Returns:
#   0 - Processing completed successfully
#   Stdout: Processed string result
#
# Side Effects:
#   - Creates processing metrics via create_metric()
#   - Logs processing information with metadata
#
# Example Usage:
#   result="$(process_example_input "  Hello World  ")"
#   # Result: "HELLO WORLD"
#
# Dependencies:
#   - sanitize_input, trim_string, to_uppercase (functional_utils.sh)
#   - string_length, create_metric (init.sh)
#   - log_info (init.sh)
#==============================================================================
process_example_input() {
    local input="$1"

    # Immutable processing pipeline using pure functions
    local sanitized_input
    sanitized_input="$(sanitize_input "${input}")"

    local trimmed_input
    trimmed_input="$(trim_string "${sanitized_input}")"

    local processed_result
    processed_result="$(to_uppercase "${trimmed_input}")"

    # Add input length metadata
    local input_length
    input_length="$(string_length "${input}")"

    local result_length
    result_length="$(string_length "${processed_result}")"

    # Create processing metrics
    create_metric "input_processing_length" "${input_length}" "chars" "stage=input"
    create_metric "input_processing_length" "${result_length}" "chars" "stage=output"

    log_info "processing" "Input processed successfully" \
        "input_length=${input_length},result_length=${result_length}"

    echo "${processed_result}"
}

#==============================================================================
# Function: validate_all_inputs
#==============================================================================
# Description: Comprehensive validation of all input parameters with detailed
#              error reporting and behavioral expectations enforcement
#
# Behavioral Contract:
#   - Pure function with immutable parameter validation
#   - Accumulates all validation errors before reporting
#   - Non-destructive validation (no parameter modification)
#   - Comprehensive logging of validation results
#   - Graceful handling of empty inputs with warnings
#
# Parameters:
#   $1 (example_input)      - User input to validate (may be empty)
#   $2 (working_directory)  - Directory path for operations
#   $3 (log_level)          - Logging verbosity level
#
# Validation Rules:
#   - working_directory: Must exist and be accessible
#   - log_level: Must be one of: debug, info, warn, warning, error
#   - example_input: Empty values generate warnings, not errors
#
# Returns:
#   0 - All validations passed
#   1 - One or more validation errors occurred
#
# Side Effects:
#   - Logs validation warnings for empty inputs
#   - Logs validation errors with error count
#   - Outputs detailed error messages to stderr
#
# Example Usage:
#   validate_all_inputs "$input" "/tmp" "info" || exit 1
#   validate_all_inputs "${INPUT_EXAMPLE_INPUT:-}" "${PWD}" "debug"
#
# Dependencies:
#   - validate_directory_accessible (functional_utils.sh)
#   - to_lowercase (functional_utils.sh)
#   - log_warn, log_error (init.sh)
#==============================================================================
validate_all_inputs() {
    local example_input="$1"
    local working_directory="$2"
    local log_level="$3"

    local validation_errors=()

    # Validate working directory exists and is accessible
    if ! validate_directory_accessible "${working_directory}"; then
        validation_errors+=("working_directory: Directory not accessible: ${working_directory}")
    fi

    # Validate log level is supported
    case "$(to_lowercase "${log_level}")" in
    debug | info | warn | warning | error)
        # Valid log level
        ;;
    *)
        validation_errors+=("log_level: Invalid log level '${log_level}'")
        ;;
    esac

    # Validate example input is not empty (unless explicitly allowed)
    if [[ -z "${example_input}" ]]; then
        log_warn "validation" "Example input is empty, this may be intentional"
    fi

    # Check if we have any validation errors
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        log_error "validation" "Input validation failed" \
            "error_count=${#validation_errors[@]}"

        for error in "${validation_errors[@]}"; do
            log_error "validation" "${error}"
        done

        return 1
    fi

    log_info "validation" "All inputs validated successfully"
    return 0
}

#==============================================================================
# Function: cleanup
#==============================================================================
# Description: Performs comprehensive cleanup operations with timing metrics
#              and resource finalization for graceful script termination
#
# Behavioral Contract:
#   - Executes cleanup regardless of script success/failure state
#   - Calculates and reports total execution time
#   - Creates final metrics for monitoring systems
#   - Performs resource cleanup and logging finalization
#   - Always completes cleanup operations (error-resilient)
#
# Parameters:
#   None (uses global readonly variables)
#
# Global Variables Used:
#   SCRIPT_START_TIME - Initial script timestamp for duration calculation
#   ACTION_NAME       - Action name for metrics tagging
#   ACTION_VERSION    - Action version for metrics tagging
#==============================================================================
cleanup() {
    local cleanup_start_time
    cleanup_start_time="$(date +%s)"

    log_info "cleanup" "Starting cleanup process"

    # Calculate total execution time
    local cleanup_end_time total_execution_time
    cleanup_end_time="$(date +%s)"
    total_execution_time="$((cleanup_end_time - SCRIPT_START_TIME))"

    # Create final metrics
    create_metric "script_total_execution_time" "${total_execution_time}" "seconds" \
        "script=${ACTION_NAME},version=${ACTION_VERSION}"

    log_info "cleanup" "Cleanup completed" "cleanup_duration=$((cleanup_end_time - cleanup_start_time))s"
}

# Main function with enhanced error handling and functional patterns
main() {
    # Initialize script with all enhanced features
    init_script \
        "${INPUT_LOG_LEVEL:-info}" \
        "${INPUT_INCLUDE_SUMMARY:-false}" \
        "${INPUT_CHECK_RATE_LIMIT:-true}"

    log_group_start "Executing ${ACTION_NAME} v${ACTION_VERSION}"

    # Validate runtime environment
    if ! validate_bash_version "${MIN_BASH_VERSION}"; then
        exit 1
    fi

    # Extract and validate inputs (immutable after extraction)
    local -r example_input="${INPUT_EXAMPLE_INPUT:-}"
    local -r working_directory="${INPUT_WORKING_DIRECTORY:-}"
    local -r log_level="${INPUT_LOG_LEVEL:-info}"

    log_info "startup" "Action started" \
        "action=${ACTION_NAME},version=${ACTION_VERSION}"

    # Record inputs in summary if enabled
    if [[ "${INPUT_INCLUDE_SUMMARY,,}" == "true" ]]; then
        set_summary_input "example_input" "${example_input}"
        set_summary_input "working_directory" "${working_directory}"
        set_summary_input "log_level" "${log_level}"
        record_event "startup" "Action started" "version=${ACTION_VERSION}"
    fi

    # Validate all inputs using pure function
    if ! validate_all_inputs "${example_input}" "${working_directory}" "${log_level}"; then
        if [[ "${INPUT_INCLUDE_SUMMARY,,}" == "true" ]]; then
            record_error "validation" "Input validation failed"
        fi
        exit 1
    fi

    # Process input using functional pipeline
    log_info "processing" "Processing input" "input_length=$(string_length "${example_input}")"

    local processing_start_time processing_result processing_end_time processing_duration
    processing_start_time="$(date +%s)"

    processing_result="$(process_example_input "${example_input}")"
    local processing_exit_code=$?

    processing_end_time="$(date +%s)"
    processing_duration="$((processing_end_time - processing_start_time))"

    if [[ ${processing_exit_code} -ne 0 ]]; then
        log_error "processing" "Input processing failed" "exit_code=${processing_exit_code}"
        if [[ "${INPUT_INCLUDE_SUMMARY,,}" == "true" ]]; then
            record_error "processing" "Input processing failed" "exit_code=${processing_exit_code}"
        fi
        exit ${processing_exit_code}
    fi

    # Create processing metrics
    create_metric "processing_duration" "${processing_duration}" "seconds"
    create_metric "processing_result_length" "$(string_length "${processing_result}")" "chars"

    # Calculate total execution time
    local script_end_time total_execution_time
    script_end_time="$(date +%s)"
    total_execution_time="$((script_end_time - SCRIPT_START_TIME))"

    # Set outputs using immutable values
    set_output "example-output" "${processing_result}"
    set_output "execution-time" "${total_execution_time}"
    set_output "script-version" "${ACTION_VERSION}"

    # Record outputs in summary if enabled
    if [[ "${INPUT_INCLUDE_SUMMARY,,}" == "true" ]]; then
        set_summary_output "example_output" "${processing_result}"
        set_summary_output "execution_time" "${total_execution_time}"
        set_summary_output "script_version" "${ACTION_VERSION}"

        record_event "completion" "Action completed successfully" \
            "execution_time=${total_execution_time}s,result_length=$(string_length "${processing_result}")"

        # Finalize and output summary
        finalize_summary "success"

        if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]] && declare -f generate_markdown_summary >/dev/null 2>&1; then
            local markdown_summary
            markdown_summary="$(generate_markdown_summary "${ACTION_NAME} v${ACTION_VERSION} Summary")"
            echo "${markdown_summary}" >>"${GITHUB_STEP_SUMMARY}"
            log_info "summary" "Summary written to GitHub step summary"
        fi
    fi

    log_success "completion" "Action completed successfully" \
        "execution_time=${total_execution_time}s,result=${processing_result}"

    log_group_end
}

# Execute main function with all arguments
main "$@"
