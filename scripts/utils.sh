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
# Core Utility Functions Library
#==============================================================================
# Description: Essential utility functions providing logging, validation,
#              GitHub Actions integration, and system operations
# Version:     2.0.0
# Author:      GitHub Action Template
# License:     GPL-3.0
#
# Purpose:     This library provides foundational utilities for:
#              - Structured logging with multiple levels and colors
#              - GitHub Actions integration (outputs, summaries, environment)
#              - System operations and command validation
#              - Input validation and sanitization
#              - Error handling and reporting
#              - Rate limiting and API management
#
# Key Features:
#   ✓ Structured Logging: JSON-compatible logging with metadata
#   ✓ Color Output: Terminal-friendly colored output with fallbacks
#   ✓ GitHub Integration: Native GitHub Actions outputs and summaries
#   ✓ Error Resilience: Comprehensive error handling patterns
#   ✓ Performance Monitoring: Built-in timing and metrics collection
#   ✓ Security Focus: Input validation and sanitization utilities
#
# Dependencies:
#   - Bash 4.4+ for advanced features
#   - Standard UNIX utilities (curl, jq) for API operations
#   - GitHub Actions environment for integration features
#
# Usage Patterns:
#   log_info "component" "message" "key=value,key2=value2"
#   set_output "output_name" "output_value"
#   validate_command_exists "curl" || exit 1
#==============================================================================

set -euo pipefail

# Source core library for shared functionality and constants
# shellcheck source=./lib/core.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/core.sh"

#==============================================================================
# Git and Repository Functions
#==============================================================================

# Check if running in a Git repository
is_git_repo() {
    git rev-parse --git-dir >/dev/null 2>&1
}

# Get the current Git branch
get_git_branch() {
    if is_git_repo; then
        git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
    else
        echo "not-a-git-repo"
    fi
}

# Get the current Git commit SHA
get_git_commit() {
    if is_git_repo; then
        git rev-parse --short HEAD 2>/dev/null || echo "unknown"
    else
        echo "not-a-git-repo"
    fi
}

# URL encoding function
url_encode() {
    local string="$1"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for ((pos = 0; pos < strlen; pos++)); do
        c=${string:${pos}:1}
        case "${c}" in
        [-_.~a-zA-Z0-9]) o="${c}" ;;
        *) printf -v o '%%%02x' "'${c}" ;;
        esac
        encoded+="${o}"
    done

    echo "${encoded}"
}

# JSON escaping function
json_escape() {
    local string="$1"

    # Escape backslashes, quotes, and common control characters
    string="${string//\\/\\\\}"   # Escape backslashes
    string="${string//\"/\\\"}"   # Escape double quotes
    string="${string//$'\t'/\\t}" # Escape tabs
    string="${string//$'\n'/\\n}" # Escape newlines
    string="${string//$'\r'/\\r}" # Escape carriage returns

    echo "${string}"
}

# Retry function for unreliable operations
retry() {
    local max_attempts="$1"
    local delay="$2"
    shift 2
    local cmd="$*"

    local attempt=1

    while [[ ${attempt} -le ${max_attempts} ]]; do
        log_debug "Attempt ${attempt}/${max_attempts}: ${cmd}"

        if eval "${cmd}"; then
            log_debug "Command succeeded on attempt ${attempt}"
            return 0
        fi

        if [[ ${attempt} -lt ${max_attempts} ]]; then
            log_warn "Command failed on attempt ${attempt}, retrying in ${delay} seconds..."
            sleep "${delay}"
        fi

        ((attempt++))
    done

    log_error "Command failed after ${max_attempts} attempts: ${cmd}"
    return 1
}

#==============================================================================
# Utility Functions - Specialized utilities not covered by core.sh
#==============================================================================

# Check if a command exists (alias for validate_command_exists for backward compatibility)
command_exists() {
    validate_command_exists "$1"
}

# Trim leading and trailing whitespace from a string
# Usage: trim_string "  string  "
trim_string() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
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

# Check GitHub API rate limits
check_github_rate_limit() {
    local min_remaining="${1:-50}"

    # Check if we're in GitHub Actions and have a token
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        log_debug "rate-limit" "No GITHUB_TOKEN provided, skipping rate limit check"
        return 0
    fi

    local response
    response="$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/rate_limit")"

    if [[ $? -ne 0 ]]; then
        log_warn "rate-limit" "Failed to check GitHub API rate limit"
        return 0
    fi

    local remaining
    remaining="$(echo "${response}" | grep -o '"remaining":[0-9]*' | cut -d':' -f2)"

    if [[ -z "${remaining}" ]]; then
        log_error "rate-limit" "Could not parse rate limit response"
        return 1
    fi

    local limit reset
    limit="$(echo "${response}" | grep -o '"limit":[0-9]*' | cut -d':' -f2)"
    reset="$(echo "${response}" | grep -o '"reset":[0-9]*' | cut -d':' -f2)"

    log_info "rate-limit" "GitHub API rate limit status" "remaining=${remaining},limit=${limit},reset=${reset}"

    if [[ "${INCLUDE_SUMMARY,,}" == "true" ]]; then
        record_event "rate-limit" "Checked GitHub API rate limits" "remaining=${remaining},limit=${limit}"
    fi

    if [[ ${remaining} -lt ${min_remaining} ]]; then
        local reset_time
        reset_time="$(date -d "@${reset}" 2>/dev/null || echo "unknown")"

        log_error "rate-limit" "Insufficient GitHub API rate limit remaining" "remaining=${remaining},required=${min_remaining},reset=${reset_time}"

        if [[ "${INCLUDE_SUMMARY,,}" == "true" ]]; then
            record_error "rate-limit" "Insufficient API calls remaining" "remaining=${remaining},required=${min_remaining}"
        fi

        return 1
    fi

    log_info "rate-limit" "GitHub API rate limit check passed" "remaining=${remaining}"
    return 0
}

#==============================================================================
# Validation Framework
#==============================================================================

# Validate that a variable is not empty
# Usage: validate_not_empty "variable_name" "variable_value" ["error_message"]
validate_not_empty() {
    local var_name="$1"
    local var_value="$2"
    local error_msg="${3:-${var_name} cannot be empty}"

    if [[ -z "${var_value}" ]]; then
        log_error "validation" "${error_msg}"
        return "${EXIT_INVALID_ARGS}"
    fi

    return "${EXIT_SUCCESS}"
}

# Validate that a variable is set (not empty)
# Usage: validate_required "variable_name" ["error_message"]
validate_required() {
    local var_name="$1"
    local error_msg="${2:-Required variable '${var_name}' is not set}"

    local var_value="${!var_name:-}"

    if [[ -z "${var_value}" ]]; then
        log_error "validation" "${error_msg}"
        return "${EXIT_INVALID_ARGS}"
    fi

    return "${EXIT_SUCCESS}"
}

# Validate that an array is not empty
# Usage: validate_array_not_empty "array_name" ["error_message"]
validate_array_not_empty() {
    local array_name="$1"
    local error_msg="${2:-Array '${array_name}' cannot be empty}"

    # Use indirect expansion to get array length
    local array_length
    eval "array_length=\${#${array_name}[@]}"

    if [[ ${array_length} -eq 0 ]]; then
        log_error "validation" "${error_msg}"
        return "${EXIT_INVALID_ARGS}"
    fi

    return "${EXIT_SUCCESS}"
}

# Validate that a file exists and is readable
# Usage: validate_file_exists "file_path" ["error_message"]
validate_file_exists() {
    local file_path="$1"
    local error_msg="${2:-File '${file_path}' does not exist or is not readable}"

    if [[ ! -f "${file_path}" || ! -r "${file_path}" ]]; then
        log_error "validation" "${error_msg}"
        return "${EXIT_INVALID_ARGS}"
    fi

    return "${EXIT_SUCCESS}"
}

# Validate that a directory exists and is accessible
# Usage: validate_directory_exists "dir_path" ["error_message"]
validate_directory_exists() {
    local dir_path="$1"
    local error_msg="${2:-Directory '${dir_path}' does not exist or is not accessible}"

    if [[ ! -d "${dir_path}" ]]; then
        log_error "validation" "${error_msg}"
        return "${EXIT_INVALID_ARGS}"
    fi

    return "${EXIT_SUCCESS}"
}

# Validate that a command exists
# Usage: validate_command_available "command_name" ["error_message"]
validate_command_available() {
    local cmd_name="$1"
    local error_msg="${2:-Command '${cmd_name}' is not available}"

    if ! command -v "${cmd_name}" >/dev/null 2>&1; then
        log_error "validation" "${error_msg}"
        return "${EXIT_INVALID_ARGS}"
    fi

    return "${EXIT_SUCCESS}"
}

# Validate numeric range
# Usage: validate_numeric_range "value" "min_value" "max_value" ["error_message"]
validate_numeric_range() {
    local value="$1"
    local min_value="$2"
    local max_value="$3"
    local error_msg="${4:-Value '${value}' must be between ${min_value} and ${max_value}}"

    if ! [[ "${value}" =~ ^[0-9]+$ ]] || [[ ${value} -lt ${min_value} ]] || [[ ${value} -gt ${max_value} ]]; then
        log_error "validation" "${error_msg}"
        return "${EXIT_INVALID_ARGS}"
    fi

    return "${EXIT_SUCCESS}"
}

# Validate that a value is in a list of allowed values
# Usage: validate_in_list "value" "allowed_values" ["error_message"]
# Example: validate_in_list "debug" "debug info warn error"
validate_in_list() {
    local value="$1"
    local allowed_values="$2"
    local error_msg="${3:-Value '${value}' is not in allowed list: ${allowed_values}}"

    for allowed in ${allowed_values}; do
        if [[ "${value}" == "${allowed}" ]]; then
            return "${EXIT_SUCCESS}"
        fi
    done

    log_error "validation" "${error_msg}"
    return "${EXIT_INVALID_ARGS}"
}

#==============================================================================
# Export Functions for Use in Other Scripts
#==============================================================================

# Export all functions so they can be used when this file is sourced
export -f command_exists
export -f check_github_rate_limit
export -f validate_not_empty
export -f validate_required
export -f validate_array_not_empty
export -f validate_directory_exists
export -f trim_string
export -f to_uppercase
export -f to_lowercase
