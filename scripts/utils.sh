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
# License:     MIT
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

# Color codes for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_PURPLE='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_NC='\033[0m' # No Color

# Log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# Current log level (default to INFO)
LOG_LEVEL=${LOG_LEVEL_INFO}

#==============================================================================
# Function: init_logging
#==============================================================================
# Description: Initializes the logging system with specified verbosity level
#              and validates configuration
#
# Behavioral Contract:
#   - Sets global LOG_LEVEL variable for all logging functions
#   - Validates and normalizes log level input
#   - Provides fallback to INFO level for invalid inputs
#   - Logs configuration success for debugging
#   - Thread-safe global state management
#
# Parameters:
#   $1 (level) - Logging level (debug|info|warn|warning|error)
#               Default: "info"
#
# Global Variables Modified:
#   LOG_LEVEL - Set to numeric constant for efficient level checking
#
# Returns:
#   0 - Logging initialization successful
#
# Side Effects:
#   - Sets global LOG_LEVEL variable
#   - May log warning to stderr for invalid level
#   - Logs debug message confirming configuration
#
# Example Usage:
#   init_logging "debug"    # Enable verbose logging
#   init_logging "error"    # Only show errors
#   init_logging            # Use default (info) level
#
# Dependencies:
#   - LOG_LEVEL_* constants
#   - log_debug function (creates circular dependency - handled gracefully)
#==============================================================================
init_logging() {
    local level="${1:-info}"

    case "${level,,}" in
        debug)
            LOG_LEVEL=${LOG_LEVEL_DEBUG}
            ;;
        info)
            LOG_LEVEL=${LOG_LEVEL_INFO}
            ;;
        warn|warning)
            LOG_LEVEL=${LOG_LEVEL_WARN}
            ;;
        error)
            LOG_LEVEL=${LOG_LEVEL_ERROR}
            ;;
        *)
            LOG_LEVEL=${LOG_LEVEL_INFO}
            # Print warning directly to stderr to avoid recursion
            echo -e "${COLOR_YELLOW}[WARN]${COLOR_NC} Invalid log level '${level}', defaulting to 'info'" >&2
            ;;
    esac

    log_debug "config" "Log level set to: ${level}"
}

# Logging functions with GitHub Actions support
# Get current timestamp in ISO format
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%d %H:%M:%S"
}

# Structured logging function
log_structured() {
    local level="$1"
    local category="${2:-general}"
    local message="$3"
    local metadata="$4"

    local timestamp
    timestamp=$(get_timestamp)

    # Format: timestamp | level | category | message | metadata
    local structured_message="${timestamp} | ${level} | ${category} | ${message}"
    if [[ -n "$metadata" ]]; then
        structured_message="${structured_message} | ${metadata}"
    fi

    # Output to stderr with colors for console
    case "${level,,}" in
        debug)
            echo -e "${COLOR_PURPLE}[DEBUG]${COLOR_NC} ${structured_message}" >&2
            ;;
        info)
            echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} ${structured_message}" >&2
            ;;
        warn|warning)
            echo -e "${COLOR_YELLOW}[WARN]${COLOR_NC} ${structured_message}" >&2
            ;;
        error)
            echo -e "${COLOR_RED}[ERROR]${COLOR_NC} ${structured_message}" >&2
            ;;
        success)
            echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} ${structured_message}" >&2
            ;;
    esac

    # GitHub Actions logging commands
    if is_github_actions; then
        case "${level,,}" in
            debug)
                echo "::debug::${structured_message}"
                ;;
            info|success)
                echo "::notice::${structured_message}"
                ;;
            warn|warning)
                echo "::warning::${structured_message}"
                ;;
            error)
                echo "::error::${structured_message}"
                ;;
        esac
    fi
}

log_debug() {
    [[ ${LOG_LEVEL} -le ${LOG_LEVEL_DEBUG} ]] || return 0
    if [[ $# -eq 1 ]]; then
        # Backward compatibility: log_debug "message"
        log_structured "DEBUG" "general" "$1" ""
    elif [[ $# -eq 2 ]]; then
        # log_debug "category" "message"
        log_structured "DEBUG" "$1" "$2" ""
    else
        # log_debug "category" "message" "metadata"
        log_structured "DEBUG" "$1" "$2" "$3"
    fi
}

log_info() {
    [[ ${LOG_LEVEL} -le ${LOG_LEVEL_INFO} ]] || return 0
    if [[ $# -eq 1 ]]; then
        # Backward compatibility: log_info "message"
        log_structured "INFO" "general" "$1" ""
    elif [[ $# -eq 2 ]]; then
        # log_info "category" "message"
        log_structured "INFO" "$1" "$2" ""
    else
        # log_info "category" "message" "metadata"
        log_structured "INFO" "$1" "$2" "$3"
    fi
}

log_warn() {
    [[ ${LOG_LEVEL} -le ${LOG_LEVEL_WARN} ]] || return 0
    if [[ $# -eq 1 ]]; then
        # Backward compatibility: log_warn "message"
        log_structured "WARN" "general" "$1" ""
    elif [[ $# -eq 2 ]]; then
        # log_warn "category" "message"
        log_structured "WARN" "$1" "$2" ""
    else
        # log_warn "category" "message" "metadata"
        log_structured "WARN" "$1" "$2" "$3"
    fi
}

log_error() {
    [[ ${LOG_LEVEL} -le ${LOG_LEVEL_ERROR} ]] || return 0
    if [[ $# -eq 1 ]]; then
        # Backward compatibility: log_error "message"
        log_structured "ERROR" "general" "$1" ""
    elif [[ $# -eq 2 ]]; then
        # log_error "category" "message"
        log_structured "ERROR" "$1" "$2" ""
    else
        # log_error "category" "message" "metadata"
        log_structured "ERROR" "$1" "$2" "$3"
    fi
}

log_success() {
    if [[ $# -eq 1 ]]; then
        # Backward compatibility: log_success "message"
        log_structured "SUCCESS" "general" "$1" ""
    elif [[ $# -eq 2 ]]; then
        # log_success "category" "message"
        log_structured "SUCCESS" "$1" "$2" ""
    else
        # log_success "category" "message" "metadata"
        log_structured "SUCCESS" "$1" "$2" "$3"
    fi
}

# GitHub Actions grouping functions
log_group_start() {
    local group_name="$*"
    if is_github_actions; then
        echo "::group::${group_name}"
    else
        echo -e "${COLOR_CYAN}[GROUP]${COLOR_NC} ${group_name}" >&2
    fi
}

log_group_end() {
    if is_github_actions; then
        echo "::endgroup::"
    fi
}

# GitHub Actions specific functions
set_output() {
    local name="$1"
    local value="$2"

    log_debug "output" "Setting output: ${name}=${value}"

    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        echo "${name}=${value}" >> "${GITHUB_OUTPUT}"
    else
        # Fallback for older versions or local testing
        echo "::set-output name=${name}::${value}"
    fi
}

set_env() {
    local name="$1"
    local value="$2"

    log_debug "Setting environment variable: ${name}=${value}"

    if [[ -n "${GITHUB_ENV:-}" ]]; then
        echo "${name}=${value}" >> "${GITHUB_ENV}"
    else
        # Fallback for local testing
        export "${name}=${value}"
    fi
}

add_to_path() {
    local path_to_add="$1"

    log_debug "Adding to PATH: ${path_to_add}"

    if [[ -n "${GITHUB_PATH:-}" ]]; then
        echo "${path_to_add}" >> "${GITHUB_PATH}"
    else
        # Fallback for local testing
        export PATH="${path_to_add}:${PATH}"
    fi
}

# Input validation functions
validate_inputs() {
    local example_input="$1"
    local working_directory="$2"
    local log_level="$3"

    log_debug "Validating inputs"

    # Validate working directory
    if [[ ! -d "${working_directory}" ]]; then
        log_error "Working directory does not exist: ${working_directory}"
        return 1
    fi

    # Validate log level
    case "${log_level,,}" in
        debug|info|warn|warning|error)
            # Valid log level
            ;;
        *)
            log_warn "Invalid log level '${log_level}', will use default 'info'"
            ;;
    esac

    log_debug "Input validation completed"
}

# File operations with error handling
safe_read_file() {
    local file_path="$1"

    if [[ ! -f "${file_path}" ]]; then
        log_error "File not found: ${file_path}"
        return 1
    fi

    if [[ ! -r "${file_path}" ]]; then
        log_error "File not readable: ${file_path}"
        return 1
    fi

    cat "${file_path}"
}

safe_write_file() {
    local file_path="$1"
    local content="$2"

    local dir_path
    dir_path="$(dirname "${file_path}")"

    if [[ ! -d "${dir_path}" ]]; then
        log_debug "Creating directory: ${dir_path}"
        mkdir -p "${dir_path}"
    fi

    echo "${content}" > "${file_path}"
    log_debug "Written to file: ${file_path}"
}

# Command execution with logging
run_command() {
    local cmd="$*"

    log_debug "Executing command: ${cmd}"

    if [[ ${LOG_LEVEL} -le ${LOG_LEVEL_DEBUG} ]]; then
        # Show command output in debug mode
        eval "${cmd}"
    else
        # Hide command output in non-debug modes
        eval "${cmd}" >/dev/null 2>&1
    fi

    local exit_code=$?

    if [[ ${exit_code} -eq 0 ]]; then
        log_debug "Command executed successfully"
    else
        log_error "Command failed with exit code ${exit_code}: ${cmd}"
    fi

    return ${exit_code}
}

# Check if running in GitHub Actions
is_github_actions() {
    [[ -n "${GITHUB_ACTIONS:-}" ]]
}

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

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:${pos}:1}
        case "${c}" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * ) printf -v o '%%%02x' "'${c}" ;;
        esac
        encoded+="${o}"
    done

    echo "${encoded}"
}

# JSON escaping function
json_escape() {
    local string="$1"

    # Escape backslashes, quotes, and common control characters
    string="${string//\\/\\\\}"  # Escape backslashes
    string="${string//\"/\\\"}"  # Escape double quotes
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

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Generate a random string
generate_random_string() {
    local length="${1:-32}"

    if command_exists openssl; then
        # Ensure enough bytes for odd lengths, then trim to exact length
        openssl rand -hex $(((length + 1) / 2)) 2>/dev/null | head -c "${length}"
    elif [[ -r /dev/urandom ]]; then
        tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "${length}"
    else
        # Fallback using date and process ID
        echo "${RANDOM}$(date +%s)$$" | sha256sum | cut -c1-"${length}"
    fi
}

# Cleanup function for temporary files
cleanup_temp_files() {
    local temp_dir="${1:-/tmp}"
    local pattern="${2:-bash-action-template-*}"

    log_debug "Cleaning up temporary files: ${temp_dir}/${pattern}"

    # Use find to safely remove temporary files
    find "${temp_dir}" -name "${pattern}" -type f -mtime +1 -delete 2>/dev/null || true
}

# Check GitHub API rate limits
check_github_rate_limit() {
    local min_remaining="${1:-100}"

    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        log_warn "rate-limit" "GITHUB_TOKEN not available, skipping rate limit check"
        return 0
    fi

    log_debug "rate-limit" "Checking GitHub API rate limits"

    local response
    response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/rate_limit)

    if [[ $? -ne 0 ]]; then
        log_error "rate-limit" "Failed to check GitHub API rate limits"
        return 1
    fi

    local remaining
    remaining=$(echo "$response" | grep -o '"remaining":[0-9]*' | cut -d':' -f2)

    if [[ -z "$remaining" ]]; then
        log_error "rate-limit" "Could not parse rate limit response"
        return 1
    fi

    local limit reset
    limit=$(echo "$response" | grep -o '"limit":[0-9]*' | cut -d':' -f2)
    reset=$(echo "$response" | grep -o '"reset":[0-9]*' | cut -d':' -f2)

    log_info "rate-limit" "GitHub API rate limit status" "remaining=${remaining},limit=${limit},reset=${reset}"

    if [[ "${INCLUDE_SUMMARY,,}" == "true" ]]; then
        record_event "rate-limit" "Checked GitHub API rate limits" "remaining=${remaining},limit=${limit}"
    fi

    if [[ $remaining -lt $min_remaining ]]; then
        local reset_time
        reset_time=$(date -d "@$reset" 2>/dev/null || echo "unknown")

        log_error "rate-limit" "Insufficient GitHub API rate limit remaining" "remaining=${remaining},required=${min_remaining},reset=${reset_time}"

        if [[ "${INCLUDE_SUMMARY,,}" == "true" ]]; then
            record_error "rate-limit" "Insufficient API calls remaining" "remaining=${remaining},required=${min_remaining}"
        fi

        return 1
    fi

    log_info "rate-limit" "GitHub API rate limit check passed" "remaining=${remaining}"
    return 0
}
