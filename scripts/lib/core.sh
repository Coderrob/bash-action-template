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
# Core Library - Shared Functionality for Bash Scripts
#==============================================================================
# Description: Centralized library providing common functionality used across
#              all bash scripts in the project. This eliminates code duplication
#              and ensures consistency.
#
# Features:
#   - Unified argument parsing
#   - Consistent logging with multiple levels
#   - Standardized error handling
#   - JSON creation utilities
#   - Common validation functions
#
# Usage: Source this file in scripts that need shared functionality
#==============================================================================

set -euo pipefail

# Source constants if available
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/constants.sh" ]]; then
    # shellcheck source=./constants.sh
    source "$(dirname "${BASH_SOURCE[0]}")/constants.sh"
fi

#==============================================================================
# Argument Parsing Functions
#==============================================================================

# Parse common help and version arguments
# Usage: parse_common_help_args "$script_name" "show_usage_function"
parse_common_help_args() {
    local script_name="$1"
    local show_usage_func="$2"

    case "${1:-}" in
    -h | --help)
        "${show_usage_func}"
        exit "${EXIT_SUCCESS}"
        ;;
    --version)
        if [[ -n "${SCRIPT_VERSION:-}" ]]; then
            echo "${script_name} ${SCRIPT_VERSION}"
        else
            echo "${script_name} (version unknown)"
        fi
        exit "${EXIT_SUCCESS}"
        ;;
    esac
}

# Parse verbosity arguments (--verbose, --quiet)
# Usage: parse_verbosity_args "$1" && shift
parse_verbosity_args() {
    case "${1:-}" in
    -v | --verbose)
        VERBOSE=true
        return 0
        ;;
    -q | --quiet)
        QUIET=true
        return 0
        ;;
    *)
        return 1
        ;;
    esac
}

# Handle unknown options with consistent error message
# Usage: handle_unknown_option "$option" "$component"
handle_unknown_option() {
    local option="$1"
    local component="${2:-args}"

    log_error "${component}" "Unknown option: ${option}"
    if [[ $(type -t show_usage) == function ]]; then
        show_usage >&2
    fi
    exit "${EXIT_INVALID_ARGS}"
}

#==============================================================================
# Logging Functions
#==============================================================================

# Initialize logging with specified level
# Usage: init_logging "component_name" ["log_level"]
init_logging() {
    local component="$1"
    local level="${2:-info}"

    # Set default log level if not already set
    LOG_LEVEL="${LOG_LEVEL:-${LOG_LEVEL_INFO}}"

    # Override with specified level
    case "${level,,}" in
    debug) LOG_LEVEL="${LOG_LEVEL_DEBUG}" ;;
    info) LOG_LEVEL="${LOG_LEVEL_INFO}" ;;
    warn | warning) LOG_LEVEL="${LOG_LEVEL_WARN}" ;;
    error) LOG_LEVEL="${LOG_LEVEL_ERROR}" ;;
    *) log_warn "logging" "Unknown log level '${level}', using 'info'" ;;
    esac

    # Set component for logging
    LOG_COMPONENT="${component}"

    log_debug "logging" "Initialized logging for component: ${component}, level: ${level}"
}

# Get current timestamp in ISO format
get_timestamp() {
    date -u +"${ISO_DATETIME_FORMAT}"
}

# Structured logging function
log_structured() {
    local level="$1"
    local component="$2"
    local message="$3"
    local metadata="${4:-}"

    local timestamp
    timestamp="$(get_timestamp)"

    # Format: timestamp | level | component | message | metadata
    local structured_message="${timestamp} | ${level} | ${component} | ${message}"
    if [[ -n "${metadata}" ]]; then
        structured_message="${structured_message} | ${metadata}"
    fi

    # Output to stderr for logging
    echo "${structured_message}" >&2

    # GitHub Actions integration
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        case "${level,,}" in
        debug) echo "::debug::${message}" ;;
        warn | warning) echo "::warning::${message}" ;;
        error) echo "::error::${message}" ;;
        esac
    fi
}

# Individual logging level functions
log_debug() {
    [[ "${LOG_LEVEL:-${LOG_LEVEL_INFO}}" -le "${LOG_LEVEL_DEBUG}" ]] || return 0
    log_structured "DEBUG" "$1" "$2" "${3:-}"
}

log_info() {
    [[ "${LOG_LEVEL:-${LOG_LEVEL_INFO}}" -le "${LOG_LEVEL_INFO}" ]] || return 0
    log_structured "INFO" "$1" "$2" "${3:-}"
}

log_warn() {
    [[ "${LOG_LEVEL:-${LOG_LEVEL_INFO}}" -le "${LOG_LEVEL_WARN}" ]] || return 0
    log_structured "WARN" "$1" "$2" "${3:-}"
}

log_error() {
    [[ "${LOG_LEVEL:-${LOG_LEVEL_INFO}}" -le "${LOG_LEVEL_ERROR}" ]] || return 0
    log_structured "ERROR" "$1" "$2" "${3:-}"
}

log_success() {
    log_structured "SUCCESS" "$1" "$2" "${3:-}"
}

# GitHub Actions group logging functions
log_group_start() {
    local group_name="$1"
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "::group::${group_name}"
    else
        log_info "group" "Starting group: ${group_name}"
    fi
}

log_group_end() {
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "::endgroup::"
    else
        log_debug "group" "Ending group"
    fi
}

#==============================================================================
# JSON Creation Utilities
#==============================================================================

# Create a JSON event object
# Usage: create_json_event "category" "message" ["metadata"]
create_json_event() {
    local category="$1"
    local message="$2"
    local metadata="${3:-}"
    local timestamp
    timestamp="$(get_timestamp)"

    echo "{\"timestamp\":\"${timestamp}\",\"category\":\"${category}\",\"message\":\"${message//\"/\\\"}\",\"metadata\":\"${metadata//\"/\\\"}\"}"
}

# Create a JSON object from key-value pairs
# Usage: create_json_object "key1=value1" "key2=value2" ...
create_json_object() {
    local json="{"
    local first=true

    for pair in "$@"; do
        if [[ ${pair} == *"="* ]]; then
            local key="${pair%%=*}"
            local value="${pair#*=}"

            if [[ "${first}" == "true" ]]; then
                first=false
            else
                json="${json},"
            fi

            json="${json}\"${key}\":\"${value//\"/\\\"}\""
        fi
    done

    json="${json}}"
    echo "${json}"
}

#==============================================================================
# Validation Functions
#==============================================================================

# Validate that a command exists
# Usage: validate_command_exists "command_name"
validate_command_exists() {
    local cmd="$1"

    if ! command -v "${cmd}" >/dev/null 2>&1; then
        log_error "validation" "Required command not found: ${cmd}"
        return 1
    fi

    return 0
}

# Validate that a file exists and is readable
# Usage: validate_file_readable "file_path"
validate_file_readable() {
    local file_path="$1"

    if [[ ! -f "${file_path}" ]]; then
        log_error "validation" "File not found: ${file_path}"
        return 1
    fi

    if [[ ! -r "${file_path}" ]]; then
        log_error "validation" "File not readable: ${file_path}"
        return 1
    fi

    return 0
}

# Validate that a directory exists and is writable
# Usage: validate_directory_writable "dir_path"
validate_directory_writable() {
    local dir_path="$1"

    if [[ ! -d "${dir_path}" ]]; then
        log_error "validation" "Directory not found: ${dir_path}"
        return 1
    fi

    if [[ ! -w "${dir_path}" ]]; then
        log_error "validation" "Directory not writable: ${dir_path}"
        return 1
    fi

    return 0
}

#==============================================================================
# GitHub Actions Integration
#==============================================================================

# Set GitHub Actions output
# Usage: set_output "name" "value"
set_output() {
    local name="$1"
    local value="$2"

    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        echo "${name}=${value}" >>"${GITHUB_OUTPUT}"
    else
        log_debug "gha" "Would set output ${name}=${value}"
    fi
}

# Set GitHub Actions environment variable
# Usage: set_env "name" "value"
set_env() {
    local name="$1"
    local value="$2"

    if [[ -n "${GITHUB_ENV:-}" ]]; then
        echo "${name}=${value}" >>"${GITHUB_ENV}"
    else
        log_debug "gha" "Would set env ${name}=${value}"
    fi
}

# Add to GitHub Actions PATH
# Usage: add_to_path "path"
add_to_path() {
    local path="$1"

    if [[ -n "${GITHUB_PATH:-}" ]]; then
        echo "${path}" >>"${GITHUB_PATH}"
    else
        log_debug "gha" "Would add to PATH: ${path}"
    fi
}

# Check if running in GitHub Actions
is_github_actions() {
    [[ -n "${GITHUB_ACTIONS:-}" ]]
}

#==============================================================================
# Utility Functions
#==============================================================================

# Trim whitespace from string
# Usage: trim_string "  string  "
trim_string() {
    local str="$1"
    # Remove leading whitespace
    str="${str#"${str%%[![:space:]]*}"}"
    # Remove trailing whitespace
    str="${str%"${str##*[![:space:]]}"}"
    echo "${str}"
}

# Convert string to uppercase
# Usage: to_uppercase "string"
to_uppercase() {
    echo "${1^^}"
}

# Convert string to lowercase
# Usage: to_lowercase "STRING"
to_lowercase() {
    echo "${1,,}"
}

# Check if string contains substring
# Usage: string_contains "haystack" "needle"
string_contains() {
    [[ "$1" == *"$2"* ]]
}

# Get string length
# Usage: string_length "string"
string_length() {
    echo "${#1}"
}

# Sanitize input for safe usage in commands
# Usage: sanitize_input "user input"
sanitize_input() {
    local input="$1"
    local sanitized="${input}"

    # Remove or escape dangerous characters
    sanitized="${sanitized//;/}"  # Remove semicolons
    sanitized="${sanitized//|/}"  # Remove pipes
    sanitized="${sanitized//&/}"  # Remove ampersands
    sanitized="${sanitized//\`/}" # Remove backticks
    sanitized="${sanitized//(/}"  # Remove opening parentheses
    sanitized="${sanitized//)/}"  # Remove closing parentheses
    sanitized="${sanitized//</}"  # Remove less than
    sanitized="${sanitized//>/}"  # Remove greater than

    echo "${sanitized}"
}

# Create a metric for monitoring/tracking
# Usage: create_metric "name" "value" "unit" "metadata"
create_metric() {
    local name="$1"
    local value="$2"
    local unit="${3:-}"
    local metadata="${4:-}"

    log_debug "metric" "Recorded metric" "name=${name},value=${value},unit=${unit},metadata=${metadata}"
}

# Get script directory (works when sourced or executed)
# Usage: get_script_dir
get_script_dir() {
    dirname "${BASH_SOURCE[0]}"
}

#==============================================================================
# Export Functions for Use in Other Scripts
#==============================================================================

# Export all functions so they can be used when this file is sourced
export -f parse_common_help_args
export -f parse_verbosity_args
export -f handle_unknown_option
export -f init_logging
export -f get_timestamp
export -f log_structured
export -f log_debug
export -f log_info
export -f log_warn
export -f log_error
export -f log_success
export -f create_json_event
export -f create_json_object
export -f validate_command_exists
export -f validate_file_readable
export -f validate_directory_writable
export -f set_output
export -f set_env
export -f add_to_path
export -f is_github_actions
export -f trim_string
export -f to_uppercase
export -f to_lowercase
export -f string_contains
export -f string_length
export -f sanitize_input
export -f create_metric
export -f get_script_dir
export -f log_group_start
export -f log_group_end
