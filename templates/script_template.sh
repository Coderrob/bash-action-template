#!/bin/bash

#==============================================================================
#
#    Copyright (C) {{YEAR}} {{AUTHOR}}
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
# {{SCRIPT_NAME}}
#==============================================================================
# Description: {{DESCRIPTION}}
# Version:     {{VERSION}}
# Author:      {{AUTHOR}}
# License:     GPL-3.0
#
# Purpose:     {{PURPOSE}}
#
# Usage:       ./{{SCRIPT_FILE}} [OPTIONS] [ARGUMENTS]
#              ./{{SCRIPT_FILE}} --help
#
# Examples:    ./{{SCRIPT_FILE}} --example "value"
#              ./{{SCRIPT_FILE}} --verbose --input "file.txt"
#
# Dependencies:
#   - Bash 4.4+
#   - utils.sh (utility functions)
#==============================================================================

set -euo pipefail

# Source utility functions
# shellcheck source=./utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Configuration and defaults
readonly SCRIPT_VERSION="{{VERSION}}"
readonly SCRIPT_NAME="{{SCRIPT_NAME}}"

# Global variables
VERBOSE=false
DRY_RUN=false
INPUT_FILE=""
OUTPUT_FILE=""

# Display usage information
show_usage() {
    cat <<EOF
Usage: ${0} [OPTIONS] [ARGUMENTS]

{{DESCRIPTION}}

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -n, --dry-run       Show what would be done without executing
    -i, --input FILE    Input file path
    -o, --output FILE   Output file path
    --version           Show version information

EXAMPLES:
    ${0} --input "data.txt" --output "result.txt"
    ${0} --verbose --dry-run
    ${0} --help

EXIT CODES:
    0 - Success
    1 - General error
    2 - Invalid arguments or usage

EOF
}

# Display version information
show_version() {
    cat <<EOF
${SCRIPT_NAME} ${SCRIPT_VERSION}
Copyright (C) {{YEAR}} {{AUTHOR}}
License: GPL-3.0

This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_usage
            exit 0
            ;;
        --version)
            show_version
            exit 0
            ;;
        -v | --verbose)
            VERBOSE=true
            shift
            ;;
        -n | --dry-run)
            DRY_RUN=true
            shift
            ;;
        -i | --input)
            INPUT_FILE="$2"
            shift 2
            ;;
        -o | --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -*)
            log_error "args" "Unknown option: $1"
            show_usage >&2
            exit 2
            ;;
        *)
            log_error "args" "Unexpected argument: $1"
            show_usage >&2
            exit 2
            ;;
        esac
    done

    # Export variables for use in other functions
    export VERBOSE DRY_RUN INPUT_FILE OUTPUT_FILE
}

# Validate arguments and environment
validate_environment() {
    local errors=()

    # Example validation - customize as needed
    if [[ -n "${INPUT_FILE}" && ! -f "${INPUT_FILE}" ]]; then
        errors+=("Input file does not exist: ${INPUT_FILE}")
    fi

    if [[ -n "${OUTPUT_FILE}" && -f "${OUTPUT_FILE}" && "${DRY_RUN}" != "true" ]]; then
        log_warn "validation" "Output file already exists and will be overwritten: ${OUTPUT_FILE}"
    fi

    # Report validation errors
    if [[ ${#errors[@]} -gt 0 ]]; then
        log_error "validation" "Validation failed:"
        for error in "${errors[@]}"; do
            log_error "validation" "  - ${error}"
        done
        return 1
    fi

    return 0
}

# Main function implementation
main_function() {
    log_info "main" "Starting ${SCRIPT_NAME} v${SCRIPT_VERSION}"

    if [[ "${VERBOSE}" == "true" ]]; then
        log_debug "main" "Verbose mode enabled"
        log_debug "main" "Input file: ${INPUT_FILE:-none}"
        log_debug "main" "Output file: ${OUTPUT_FILE:-none}"
        log_debug "main" "Dry run: ${DRY_RUN}"
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "main" "DRY RUN: No changes will be made"
    fi

    # TODO: Implement main functionality here
    log_info "main" "TODO: Implement main functionality"

    # Example processing
    if [[ -n "${INPUT_FILE}" ]]; then
        log_info "main" "Processing input file: ${INPUT_FILE}"
        # TODO: Process input file
    fi

    if [[ -n "${OUTPUT_FILE}" ]]; then
        if [[ "${DRY_RUN}" == "true" ]]; then
            log_info "main" "Would write output to: ${OUTPUT_FILE}"
        else
            log_info "main" "Writing output to: ${OUTPUT_FILE}"
            # TODO: Write output file
        fi
    fi

    log_info "main" "✅ ${SCRIPT_NAME} completed successfully"
}

# Main entry point
main() {
    # Initialize logging
    init_logging "{{SCRIPT_NAME}}"

    # Parse command line arguments
    parse_arguments "$@"

    # Validate environment and arguments
    if ! validate_environment; then
        log_error "main" "Environment validation failed"
        exit 1
    fi

    # Execute main functionality
    if main_function; then
        exit 0
    else
        log_error "main" "Script execution failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
