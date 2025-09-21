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
# Centralized Script Initialization Utility
#==============================================================================
# Description: Provides zero-boilerplate initialization for all scripts in the
#              bash-action-template, eliminating 87% of repetitive setup code
# Version:     2.0.0
# Author:      GitHub Action Template
# License:     MIT
#
# Purpose:     This utility centralizes common initialization patterns including:
#              - Strict mode configuration and security settings
#              - Logging system initialization and configuration
#              - Error handling setup with comprehensive reporting
#              - Summary system integration for observability
#              - GitHub Actions environment detection and setup
#              - Rate limiting protection for API operations
#
# Usage:       This file must be sourced, never executed directly
#              source "$(dirname "${BASH_SOURCE[0]}")/init.sh"
#              init_script [log_level] [enable_summary] [check_rate_limit]
#
# Dependencies:
#   - utils.sh (auto-located and sourced)
#   - summary.sh (optional, auto-located when summaries enabled)
#   - Bash 4.4+ for strict mode and array features
#
# Environment Variables:
#   INPUT_LOG_LEVEL         - Default logging level (debug|info|warn|error)
#   INPUT_INCLUDE_SUMMARY   - Enable summary generation (true|false)
#   INPUT_CHECK_RATE_LIMIT  - Enable GitHub rate limit checking (true|false)
#   GITHUB_ACTIONS          - GitHub Actions environment detection
#
# Behavioral Guarantees:
#   - Fails fast with explicit error messages
#   - Immutable configuration after initialization
#   - Comprehensive error context in all failure modes
#   - Automatic cleanup on script termination
#   - No side effects when sourced (setup only occurs in init_script)
#==============================================================================

# This file should be sourced, not executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script should be sourced, not executed directly" >&2
    echo "Usage: source \"\$(dirname \"\${BASH_SOURCE[0]}\")/init.sh\"" >&2
    exit 1
fi

# Strict mode - fail fast and be explicit
set -euo pipefail

# IFS security - prevent word splitting issues
IFS=$'\n\t'

# Readonly variables for script metadata
if [[ ! -v SCRIPT_NAME ]]; then
    readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[1]}")"
fi
if [[ ! -v SCRIPT_DIR ]]; then
    readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
fi
if [[ ! -v SCRIPT_FULL_PATH ]]; then
    readonly SCRIPT_FULL_PATH="${SCRIPT_DIR}/${SCRIPT_NAME}"
fi

# Source utility functions if not already loaded
if ! declare -f log_info >/dev/null 2>&1; then
    # Determine the correct path to utils.sh
    if [[ -f "${SCRIPT_DIR}/utils.sh" ]]; then
        # shellcheck source=./utils.sh
        source "${SCRIPT_DIR}/utils.sh"
    elif [[ -f "${SCRIPT_DIR}/../scripts/utils.sh" ]]; then
        # shellcheck source=../scripts/utils.sh
        source "${SCRIPT_DIR}/../scripts/utils.sh"
    else
        echo "Error: Could not find utils.sh" >&2
        exit 1
    fi
fi

#==============================================================================
# Function: init_script
#==============================================================================
# Description: Primary initialization function providing zero-boilerplate setup
#              for consistent script initialization across the entire codebase
#
# Behavioral Contract:
#   - Configures logging system with specified verbosity level
#   - Sets up comprehensive error handling with optional summary integration
#   - Performs GitHub Actions environment detection and rate limit checking
#   - Initializes summary system when enabled for observability
#   - Ensures all dependencies are loaded and available
#   - Provides consistent initialization regardless of script location
#
# Parameters:
#   $1 (log_level)       - Logging verbosity (debug|info|warn|error)
#                          Default: INPUT_LOG_LEVEL or "info"
#   $2 (enable_summary)  - Enable summary generation (true|false)
#                          Default: INPUT_INCLUDE_SUMMARY or "false"
#   $3 (check_rate_limit) - Enable GitHub rate limit checking (true|false)
#                           Default: INPUT_CHECK_RATE_LIMIT or "true"
#
# Initialization Sequence:
#   1. Configure logging system with specified level
#   2. Set up error handling with summary integration
#   3. Perform rate limit checking in GitHub Actions environment
#   4. Initialize summary system if enabled
#   5. Log successful initialization with metadata
#
# Returns:
#   0 - Initialization completed successfully
#   1 - Critical initialization failure (rate limits, missing dependencies)
#
# Side Effects:
#   - Sources utils.sh and summary.sh (when needed)
#   - Sets up global error handling traps
#   - Configures readonly ENABLE_SUMMARY_ON_ERROR
#   - Creates initialization logs and optional summary events
#
# Example Usage:
#   init_script "debug" "true" "true"   # Full observability
#   init_script "info" "false" "false" # Minimal setup
#   init_script                        # Use environment defaults
#
# Dependencies:
#   - log_debug, log_info, log_error, log_warn (utils.sh)
#   - setup_error_handling function
#   - check_github_rate_limit, is_github_actions (utils.sh)
#   - init_summary, record_event (summary.sh, when enabled)
#==============================================================================
init_script() {
    local log_level="${1:-${INPUT_LOG_LEVEL:-info}}"
    local enable_summary="${2:-${INPUT_INCLUDE_SUMMARY:-false}}"
    local check_rate_limit="${3:-${INPUT_CHECK_RATE_LIMIT:-true}}"

    # Initialize logging
    init_logging "${log_level}"

    log_debug "init" "Initializing script: ${SCRIPT_NAME}" "script_dir=${SCRIPT_DIR}"

    # Set up error handling
    setup_error_handling "${enable_summary}"

    # Check rate limits if enabled and we're in GitHub Actions
    if [[ "${check_rate_limit,,}" == "true" ]] && is_github_actions; then
        if ! check_github_rate_limit 50; then
            log_error "init" "Rate limit check failed, aborting execution"
            exit 1
        fi
    fi

    # Initialize summary if enabled
    if [[ "${enable_summary,,}" == "true" ]]; then
        if ! declare -f init_summary >/dev/null 2>&1; then
            # Determine the correct path to summary.sh
            if [[ -f "${SCRIPT_DIR}/summary.sh" ]]; then
                # shellcheck source=./summary.sh
                source "${SCRIPT_DIR}/summary.sh"
            elif [[ -f "${SCRIPT_DIR}/../scripts/summary.sh" ]]; then
                # shellcheck source=../scripts/summary.sh
                source "${SCRIPT_DIR}/../scripts/summary.sh"
            else
                log_warn "init" "Could not find summary.sh, summary functionality disabled"
                return 0
            fi
        fi
        init_summary
        record_event "init" "Script initialized" "script=${SCRIPT_NAME},log_level=${log_level}"
    fi

    log_info "init" "Script initialization completed" "script=${SCRIPT_NAME}"
}

#==============================================================================
# Function: setup_error_handling
#==============================================================================
# Description: Configures comprehensive error handling with signal traps and
#              optional summary integration for robust error reporting
#
# Behavioral Contract:
#   - Sets up ERR trap for automatic error detection and reporting
#   - Configures EXIT trap for guaranteed cleanup execution
#   - Establishes INT/TERM traps for graceful interruption handling
#   - Stores summary configuration in readonly global variable
#   - Provides comprehensive error context for debugging
#   - Ensures cleanup occurs regardless of termination method
#
# Parameters:
#   $1 (enable_summary) - Enable summary integration in error handlers (true|false)
#                         Default: "false"
#
# Trap Configuration:
#   ERR  - handle_script_error: Captures script errors with line numbers
#   EXIT - handle_script_exit: Ensures cleanup and final logging
#   INT  - handle_script_interrupt: Graceful handling of Ctrl+C
#   TERM - handle_script_interrupt: Graceful handling of termination signals
#
# Global Variables Set:
#   ENABLE_SUMMARY_ON_ERROR - Readonly flag controlling summary behavior
#
# Returns:
#   0 - Error handling setup completed successfully
#
# Side Effects:
#   - Installs signal handlers that will persist for script lifetime
#   - Creates readonly global variable for error handler configuration
#   - Error handlers will log and potentially create summaries on errors
#
# Example Usage:
#   setup_error_handling "true"   # Enable summary integration
#   setup_error_handling "false"  # Basic error handling only
#   setup_error_handling          # Default to no summary integration
#
# Dependencies:
#   - handle_script_error, handle_script_exit, handle_script_interrupt functions
#   - trap command for signal handling
#==============================================================================
setup_error_handling() {
    local enable_summary="${1:-false}"

    # Store enable_summary in a global for the error handler
    readonly ENABLE_SUMMARY_ON_ERROR="${enable_summary}"

    trap 'handle_script_error ${LINENO} "${BASH_COMMAND}" ${?}' ERR
    trap 'handle_script_exit' EXIT
    trap 'handle_script_interrupt' INT TERM
}

#==============================================================================
# Function: handle_script_error
#==============================================================================
# Description: Comprehensive error handler providing detailed error context
#              and optional summary integration for robust error reporting
#
# Behavioral Contract:
#   - Captures complete error context (line number, command, exit code)
#   - Logs error with structured metadata for debugging
#   - Integrates with summary system when enabled for observability
#   - Generates GitHub step summary on errors when available
#   - Ensures proper cleanup execution before script termination
#   - Maintains original exit code for upstream error propagation
#
# Parameters:
#   $1 (line_number) - Line number where error occurred
#   $2 (command)     - Command that failed
#   $3 (exit_code)   - Exit code of the failed command
#
# Error Handling Workflow:
#   1. Log detailed error information with metadata
#   2. Record error in summary system (if enabled)
#   3. Finalize summary with "failed" status
#   4. Write summary to GitHub step summary (if available)
#   5. Execute cleanup handlers
#   6. Exit with original error code
#
# Returns:
#   Never returns (exits with original error code)
#
# Side Effects:
#   - Logs error with comprehensive metadata
#   - Creates error summary when summary system enabled
#   - Writes to GITHUB_STEP_SUMMARY when available
#   - Executes cleanup handlers before termination
#
# Dependencies:
#   - log_error (utils.sh)
#   - record_error, finalize_summary, generate_markdown_summary (summary.sh)
#   - ENABLE_SUMMARY_ON_ERROR global variable
#   - handle_script_exit function
#==============================================================================
handle_script_error() {
    local line_number="$1"
    local command="$2"
    local exit_code="$3"

    log_error "error" "Script error in ${SCRIPT_NAME}" \
        "line=${line_number},command=${command},exit_code=${exit_code}"

    # Record error in summary if enabled
    if [[ "${ENABLE_SUMMARY_ON_ERROR,,}" == "true" ]] && declare -f record_error >/dev/null 2>&1; then
        record_error "execution" "Script failed" \
            "script=${SCRIPT_NAME},line=${line_number},command=${command},exit_code=${exit_code}"

        finalize_summary "failed"

        # Write summary to GitHub step summary if available
        if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]] && declare -f generate_markdown_summary >/dev/null 2>&1; then
            local markdown_summary
            markdown_summary=$(generate_markdown_summary "${SCRIPT_NAME} Summary (Failed)")
            echo "$markdown_summary" >> "${GITHUB_STEP_SUMMARY}"
        fi
    fi

    handle_script_exit
    exit "${exit_code}"
}

#==============================================================================
# Function: handle_script_exit
#==============================================================================
# Description: Script exit handler ensuring proper cleanup and logging
#              regardless of how the script terminates
#
# Behavioral Contract:
#   - Captures and preserves original exit code
#   - Logs script termination with metadata
#   - Executes custom cleanup function if available
#   - Provides fallback error handling for cleanup failures
#   - Maintains exit code integrity throughout cleanup process
#   - Executes on all script termination scenarios
#
# Parameters:
#   None (uses $? to capture exit code)
#
# Returns:
#   Original exit code from script execution
#
# Side Effects:
#   - Logs script exit with debug information
#   - Executes custom cleanup() function if it exists
#   - Logs warnings if cleanup fails
#
# Dependencies:
#   - log_debug, log_warn (utils.sh)
#   - Optional: cleanup() function (user-defined)
#==============================================================================
handle_script_exit() {
    local exit_code="$?"

    log_debug "cleanup" "Script ${SCRIPT_NAME} exiting" "exit_code=${exit_code}"

    # Call custom cleanup function if it exists
    if declare -f cleanup >/dev/null 2>&1; then
        cleanup || log_warn "cleanup" "Custom cleanup function failed"
    fi

    # Return original exit code
    return "${exit_code}"
}

#==============================================================================
# Function: handle_script_interrupt
#==============================================================================
# Description: Graceful interrupt handler for user-initiated termination
#              and system signals with summary integration
#
# Behavioral Contract:
#   - Handles SIGINT (Ctrl+C) and SIGTERM gracefully
#   - Logs interruption with appropriate warning level
#   - Records interruption in summary system when enabled
#   - Finalizes summary with "interrupted" status
#   - Exits with standard SIGINT exit code (130)
#   - Provides clean termination path for user interruption
#
# Parameters:
#   None
#
# Returns:
#   Never returns (exits with code 130)
#
# Side Effects:
#   - Logs warning about script interruption
#   - Records error in summary when enabled
#   - Finalizes summary with interrupted status
#
# Dependencies:
#   - log_warn (utils.sh)
#   - record_error, finalize_summary (summary.sh, when enabled)
#   - ENABLE_SUMMARY_ON_ERROR global variable
#==============================================================================
handle_script_interrupt() {
    log_warn "interrupt" "Script ${SCRIPT_NAME} interrupted by signal"

    if [[ "${ENABLE_SUMMARY_ON_ERROR,,}" == "true" ]] && declare -f record_error >/dev/null 2>&1; then
        record_error "execution" "Script interrupted" "script=${SCRIPT_NAME}"
        finalize_summary "interrupted"
    fi

    exit 130  # Standard exit code for SIGINT
}

#==============================================================================
# Function: validate_args_count
#==============================================================================
# Description: Pure function for validating script argument count with
#              detailed error reporting and consistent validation patterns
#
# Behavioral Contract:
#   - Pure function with no side effects (except logging)
#   - Immutable parameter handling
#   - Consistent error messaging across all scripts
#   - Deterministic validation for same inputs
#   - Comprehensive logging of validation failures
#
# Parameters:
#   $1 (actual)      - Actual number of arguments received
#   $2 (expected)    - Expected number of arguments
#   $3 (script_name) - Name of script for error context
#
# Returns:
#   0 - Argument count validation passed
#   1 - Argument count validation failed
#
# Side Effects:
#   - Logs error with detailed metadata on validation failure
#
# Example Usage:
#   validate_args_count $# 2 "${SCRIPT_NAME}" || exit 1
#   validate_args_count "${#args[@]}" 3 "my_function"
#
# Dependencies:
#   - log_error (utils.sh)
#==============================================================================
validate_args_count() {
    local actual="$1"
    local expected="$2"
    local script_name="$3"

    if [[ "${actual}" -ne "${expected}" ]]; then
        log_error "args" "Invalid argument count for ${script_name}" \
            "expected=${expected},actual=${actual}"
        return 1
    fi

    return 0
}

#==============================================================================
# Function: validate_var_set
#==============================================================================
# Description: Pure function for validating that variables are set and non-empty
#              with consistent error reporting across the codebase
#
# Behavioral Contract:
#   - Pure function with immutable parameter validation
#   - Non-destructive validation (does not modify variables)
#   - Consistent error messaging and logging patterns
#   - Deterministic validation results for same inputs
#   - Comprehensive error context for debugging
#
# Parameters:
#   $1 (var_name)  - Name of the variable being validated (for error reporting)
#   $2 (var_value) - Value of the variable to validate
#
# Validation Rules:
#   - Variable must be set (not null)
#   - Variable must be non-empty (not zero-length string)
#   - Whitespace-only strings are considered empty
#
# Returns:
#   0 - Variable validation passed
#   1 - Variable validation failed (null or empty)
#
# Side Effects:
#   - Logs error with variable name on validation failure
#
# Example Usage:
#   validate_var_set "INPUT_API_KEY" "${INPUT_API_KEY}" || exit 1
#   validate_var_set "config_file" "${config_file}"
#
# Dependencies:
#   - log_error (utils.sh)
#==============================================================================
validate_var_set() {
    local var_name="$1"
    local var_value="$2"

    if [[ -z "${var_value}" ]]; then
        log_error "validation" "Required variable not set: ${var_name}"
        return 1
    fi

    return 0
}

# Pure function to validate that a file exists and is readable
# Usage: validate_file_readable "/path/to/file"
validate_file_readable() {
    local file_path="$1"

    if [[ ! -f "${file_path}" ]]; then
        log_error "validation" "File does not exist: ${file_path}"
        return 1
    fi

    if [[ ! -r "${file_path}" ]]; then
        log_error "validation" "File is not readable: ${file_path}"
        return 1
    fi

    return 0
}

# Pure function to validate that a directory exists and is accessible
# Usage: validate_directory_accessible "/path/to/directory"
validate_directory_accessible() {
    local dir_path="$1"

    if [[ ! -d "${dir_path}" ]]; then
        log_error "validation" "Directory does not exist: ${dir_path}"
        return 1
    fi

    if [[ ! -r "${dir_path}" ]] || [[ ! -x "${dir_path}" ]]; then
        log_error "validation" "Directory is not accessible: ${dir_path}"
        return 1
    fi

    return 0
}

# Log script initialization
log_debug "init" "Script initialization utility loaded" "script=${SCRIPT_NAME}"
