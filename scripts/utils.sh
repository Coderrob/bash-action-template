#!/bin/bash

# Utility functions for the GitHub Action
# This file contains reusable functions and best practices

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

# Initialize logging with specified level
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
            log_warn "Invalid log level '${level}', defaulting to 'info'"
            ;;
    esac
    
    log_debug "Log level set to: ${level}"
}

# Logging functions
log_debug() {
    [[ ${LOG_LEVEL} -le ${LOG_LEVEL_DEBUG} ]] || return 0
    echo -e "${COLOR_PURPLE}[DEBUG]${COLOR_NC} $*" >&2
}

log_info() {
    [[ ${LOG_LEVEL} -le ${LOG_LEVEL_INFO} ]] || return 0
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $*" >&2
}

log_warn() {
    [[ ${LOG_LEVEL} -le ${LOG_LEVEL_WARN} ]] || return 0
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_NC} $*" >&2
}

log_error() {
    [[ ${LOG_LEVEL} -le ${LOG_LEVEL_ERROR} ]] || return 0
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $*" >&2
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $*" >&2
}

# GitHub Actions specific functions
set_output() {
    local name="$1"
    local value="$2"
    
    log_debug "Setting output: ${name}=${value}"
    
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
        openssl rand -hex $((length / 2)) 2>/dev/null
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

# Export functions that might be used by other scripts
export -f log_debug log_info log_warn log_error log_success
export -f set_output set_env add_to_path
export -f run_command retry command_exists