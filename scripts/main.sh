#!/bin/bash

# Main script for the GitHub Action
# This script demonstrates best practices for bash scripting in GitHub Actions

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Source utility functions
# shellcheck source=./utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Initialize logging
init_logging "${INPUT_LOG_LEVEL:-info}"

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly ACTION_NAME="bash-action-template"
START_TIME=$(date +%s)
readonly START_TIME

# Main function
main() {
    log_info "Starting ${ACTION_NAME}"
    log_debug "Script directory: ${SCRIPT_DIR}"
    log_debug "Working directory: $(pwd)"
    log_debug "Action path: ${ACTION_PATH:-not set}"
    
    # Validate environment
    validate_environment
    
    # Process inputs
    local example_input="${INPUT_EXAMPLE_INPUT:-}"
    local working_directory="${INPUT_WORKING_DIRECTORY:-.}"
    
    log_info "Processing input: ${example_input}"
    
    # Example processing logic
    local result
    result=$(process_example_input "${example_input}")
    
    # Calculate execution time
    local end_time
    end_time=$(date +%s)
    local execution_time=$((end_time - START_TIME))
    
    # Set outputs
    set_output "example-output" "${result}"
    set_output "execution-time" "${execution_time}"
    
    log_info "Action completed successfully in ${execution_time} seconds"
}

# Validate the runtime environment
validate_environment() {
    log_debug "Validating environment"
    
    # Check required commands
    local required_commands=("bash" "date" "grep" "sed" "awk")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "${cmd}" >/dev/null 2>&1; then
            log_error "Required command not found: ${cmd}"
            exit 1
        fi
    done
    
    # Check GitHub Actions environment
    if [[ -z "${GITHUB_ACTIONS:-}" ]]; then
        log_warn "Not running in GitHub Actions environment"
    fi
    
    log_debug "Environment validation completed"
}

# Process the example input
process_example_input() {
    local input="$1"
    
    log_debug "Processing example input: ${input}"
    
    # Example processing - transform input to uppercase
    local result
    result=$(echo "${input}" | tr '[:lower:]' '[:upper:]')
    
    log_info "Processed result: ${result}"
    echo "${result}"
}

# Set up error handling
setup_error_handling() {
    trap 'handle_error ${LINENO} ${BASH_COMMAND}' ERR
    trap 'cleanup' EXIT
}

# Error handler
handle_error() {
    local line_number="$1"
    local command="$2"
    local exit_code="$?"
    
    log_error "Error on line ${line_number}: Command '${command}' failed with exit code ${exit_code}"
    cleanup
    exit "${exit_code}"
}

# Cleanup function
cleanup() {
    log_debug "Performing cleanup"
    # Add any cleanup logic here
}

# Initialize error handling
setup_error_handling

# Run main function
main "$@"