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
# Common Arguments Library - Shared Argument Parsing Patterns
#==============================================================================
# Description: Centralized argument parsing patterns used across multiple scripts.
#              This eliminates duplication and ensures consistent argument handling.
#
# Features:
#   - Common flag parsing (--verbose, --quiet, --dry-run, --force)
#   - Path argument validation
#   - Boolean flag handling
#   - Standardized argument processing
#
# Usage: Source this file in scripts that need common argument patterns
#==============================================================================

# Source core library for logging and constants
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/core.sh" ]]; then
    # shellcheck source=./core.sh
    source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
fi

#==============================================================================
# Common Argument Parsing Functions
#==============================================================================

# Parse common help and version arguments
# Usage: parse_common_help_args "$script_name" "show_usage_function"
parse_common_help_args() {
    local script_name="$1"
    local show_usage_func="$2"

    case "${1:-}" in
        -h|--help)
            "$show_usage_func"
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
        -v|--verbose)
            VERBOSE=true
            return 0
            ;;
        -q|--quiet)
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

    log_error "$component" "Unknown option: $option"
    if [[ $(type -t show_usage) == function ]]; then
        show_usage >&2
    fi
    exit "${EXIT_INVALID_ARGS}"
}

# Parse common boolean flags
# Usage: parse_common_flags "$@" && shift $?
parse_common_flags() {
    local parsed_flags=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                VERBOSE=true
                parsed_flags=$((parsed_flags + 1))
                shift
                ;;
            -q|--quiet)
                QUIET=true
                parsed_flags=$((parsed_flags + 1))
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                parsed_flags=$((parsed_flags + 1))
                shift
                ;;
            --force|-f)
                FORCE=true
                parsed_flags=$((parsed_flags + 1))
                shift
                ;;
            --no-color|--no-colour)
                NO_COLOR=true
                parsed_flags=$((parsed_flags + 1))
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    return "${parsed_flags}"
}

# Parse path arguments with validation
# Usage: parse_path_arg "$arg_name" "$path_value" ["directory"|"file"]
parse_path_arg() {
    local arg_name="$1"
    local path_value="$2"
    local path_type="${3:-}"

    # Expand tilde if present
    path_value="${path_value/#\~/$HOME}"

    # Convert to absolute path
    if [[ ! "${path_value}" =~ ^/ ]]; then
        path_value="$(cd "$(dirname "${path_value}")" 2>/dev/null && pwd)/$(basename "${path_value}")" 2>/dev/null || {
            log_error "args" "Invalid path for ${arg_name}: ${path_value}"
            return "${EXIT_INVALID_ARGS}"
        }
    fi

    # Validate path type if specified
    case "${path_type,,}" in
        directory|dir)
            if [[ ! -d "${path_value}" ]]; then
                log_error "args" "Directory does not exist: ${path_value}"
                return "${EXIT_INVALID_ARGS}"
            fi
            ;;
        file)
            if [[ ! -f "${path_value}" ]]; then
                log_error "args" "File does not exist: ${path_value}"
                return "${EXIT_INVALID_ARGS}"
            fi
            ;;
    esac

    # Return the validated path
    echo "${path_value}"
}

# Parse numeric arguments with validation
# Usage: parse_numeric_arg "$arg_name" "$value" ["min_value"] ["max_value"]
parse_numeric_arg() {
    local arg_name="$1"
    local value="$2"
    local min_value="${3:-}"
    local max_value="${4:-}"

    # Check if value is numeric
    if ! [[ "${value}" =~ ^[0-9]+$ ]]; then
        log_error "args" "${arg_name} must be a positive integer: ${value}"
        return "${EXIT_INVALID_ARGS}"
    fi

    # Check minimum value
    if [[ -n "${min_value}" ]] && [[ "${value}" -lt "${min_value}" ]]; then
        log_error "args" "${arg_name} must be at least ${min_value}: ${value}"
        return "${EXIT_INVALID_ARGS}"
    fi

    # Check maximum value
    if [[ -n "${max_value}" ]] && [[ "${value}" -gt "${max_value}" ]]; then
        log_error "args" "${arg_name} must be at most ${max_value}: ${value}"
        return "${EXIT_INVALID_ARGS}"
    fi

    # Return the validated number
    echo "${value}"
}

# Parse log level arguments
# Usage: parse_log_level_arg "$level_string"
parse_log_level_arg() {
    local level="$1"

    case "${level,,}" in
        debug) echo "${LOG_LEVEL_DEBUG}" ;;
        info) echo "${LOG_LEVEL_INFO}" ;;
        warn|warning) echo "${LOG_LEVEL_WARN}" ;;
        error) echo "${LOG_LEVEL_ERROR}" ;;
        *)
            log_error "args" "Invalid log level: ${level}. Must be debug, info, warn, or error."
            return "${EXIT_INVALID_ARGS}"
            ;;
    esac
}

# Parse timeout arguments
# Usage: parse_timeout_arg "$timeout_value"
parse_timeout_arg() {
    local timeout="$1"

    if ! [[ "${timeout}" =~ ^[0-9]+$ ]] || [[ "${timeout}" -le 0 ]]; then
        log_error "args" "Timeout must be a positive integer: ${timeout}"
        return "${EXIT_INVALID_ARGS}"
    fi

    if [[ "${timeout}" -gt 3600 ]]; then
        log_warn "args" "Large timeout specified: ${timeout}s. This may cause long waits."
    fi

    echo "${timeout}"
}

# Parse retry arguments
# Usage: parse_retry_arg "$retry_count"
parse_retry_arg() {
    local retries="$1"

    if ! [[ "${retries}" =~ ^[0-9]+$ ]] || [[ "${retries}" -lt 0 ]]; then
        log_error "args" "Retry count must be a non-negative integer: ${retries}"
        return "${EXIT_INVALID_ARGS}"
    fi

    if [[ "${retries}" -gt 10 ]]; then
        log_warn "args" "High retry count specified: ${retries}. This may cause long execution times."
    fi

    echo "${retries}"
}

# Parse and validate email arguments
# Usage: parse_email_arg "$email_value"
parse_email_arg() {
    local email="$1"

    if ! [[ "${email}" =~ ${EMAIL_PATTERN} ]]; then
        log_error "args" "Invalid email format: ${email}"
        return "${EXIT_INVALID_ARGS}"
    fi

    echo "${email}"
}

# Parse and validate URL arguments
# Usage: parse_url_arg "$url_value"
parse_url_arg() {
    local url="$1"

    if ! [[ "${url}" =~ ${URL_PATTERN} ]]; then
        log_error "args" "Invalid URL format: ${url}"
        return "${EXIT_INVALID_ARGS}"
    fi

    echo "${url}"
}

#==============================================================================
# Argument Processing Utilities
#==============================================================================

# Process remaining positional arguments
# Usage: process_positional_args "$@" ["arg1_name"] ["arg2_name"] ...
process_positional_args() {
    local args=("$@")
    local arg_names=("${args[@]:1}")
    local positional_index=0

    # Skip the first argument (script name or first processed arg)
    for ((i = 1; i < ${#args[@]}; i++)); do
        if [[ "${args[i]}" != -* ]]; then
            if [[ "${positional_index}" -lt "${#arg_names[@]}" ]]; then
                local arg_name="${arg_names[positional_index]}"
                eval "${arg_name}=\"${args[i]}\""
                positional_index=$((positional_index + 1))
            else
                log_error "args" "Unexpected positional argument: ${args[i]}"
                return "${EXIT_INVALID_ARGS}"
            fi
        fi
    done

    # Check for required positional arguments
    for ((i = positional_index; i < ${#arg_names[@]}; i++)); do
        log_error "args" "Missing required argument: ${arg_names[i]}"
        return "${EXIT_INVALID_ARGS}"
    done
}

# Validate that no conflicting flags are set
# Usage: validate_flag_conflicts ["flag1=flag2"] ["flag3=flag4"] ...
validate_flag_conflicts() {
    local conflicts=("$@")

    for conflict in "${conflicts[@]}"; do
        local flag1="${conflict%%=*}"
        local flag2="${conflict#*=}"

        if [[ "${!flag1:-false}" == "true" ]] && [[ "${!flag2:-false}" == "true" ]]; then
            log_error "args" "Conflicting flags: --${flag1//_/-} and --${flag2//_/-} cannot both be specified"
            return "${EXIT_INVALID_ARGS}"
        fi
    done
}

#==============================================================================
# Export Functions for Use in Other Scripts
#==============================================================================

# Export all functions so they can be used when this file is sourced
export -f parse_common_help_args
export -f parse_verbosity_args
export -f handle_unknown_option
export -f parse_common_flags
export -f parse_path_arg
export -f parse_numeric_arg
export -f parse_log_level_arg
export -f parse_timeout_arg
export -f parse_retry_arg
export -f parse_email_arg
export -f parse_url_arg
export -f process_positional_args
export -f validate_flag_conflicts
