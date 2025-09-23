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
#    but WITHOUT ANY WARRANTY; without ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#==============================================================================

#==============================================================================
# Script Initialization Library - Standardized Script Setup
#==============================================================================
# Description: Provides standardized initialization patterns for all bash scripts.
#              This eliminates duplication and ensures consistent script setup.
#
# Features:
#   - Strict mode configuration
#   - Security settings (IFS)
#   - Core library sourcing
#   - Logging initialization
#   - Main execution guard
#   - Cleanup handler registration
#
# Usage: Source this file and call init_script() at the beginning of scripts
#==============================================================================

# Source core library for shared functionality
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/core.sh" ]]; then
    # shellcheck source=./core.sh
    source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
fi

#==============================================================================
# Script Initialization Functions
#==============================================================================

# Initialize a script with standard setup
# Usage: init_script "component_name" ["log_level"] ["enable_main_guard"]
init_script() {
    local component="$1"
    local log_level="${2:-info}"
    local enable_main_guard="${3:-true}"

    # Strict mode - fail fast and be explicit
    set -euo pipefail

    # IFS security - prevent word splitting issues
    IFS=$'\n\t'

    # Initialize logging
    init_logging "${component}" "${log_level}"

    # Set up cleanup handlers
    setup_cleanup_handlers

    # Set up main guard if requested
    if [[ "${enable_main_guard,,}" == "true" ]]; then
        setup_main_guard
    fi

    log_debug "init" "Script initialized successfully" "component=${component},log_level=${log_level}"
}

# Set up cleanup handlers for script termination
# Usage: setup_cleanup_handlers
setup_cleanup_handlers() {
    # Register cleanup function if it exists
    if declare -f cleanup >/dev/null 2>&1; then
        trap cleanup EXIT
        log_debug "init" "Cleanup handler registered"
    fi
}

# Set up main execution guard
# Usage: setup_main_guard
setup_main_guard() {
    # This function should be called at the end of scripts to set up the main guard
    # It sets a variable that can be checked later
    readonly SCRIPT_MAIN_GUARD_ENABLED=true
    log_debug "init" "Main execution guard enabled"
}

# Check if script is being executed directly (not sourced)
# Usage: if is_main_execution; then main "$@"; fi
is_main_execution() {
    [[ "${BASH_SOURCE[0]}" == "${0}" ]]
}

# Get script metadata
# Usage: get_script_info
get_script_info() {
    local script_name
    local script_dir
    local script_path

    script_name="$(basename "${BASH_SOURCE[1]}")"
    script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    script_path="${script_dir}/${script_name}"

    echo "name=${script_name},dir=${script_dir},path=${script_path}"
}

# Validate script environment
# Usage: validate_script_environment ["required_commands..."]
validate_script_environment() {
    local required_commands=("$@")
    local missing_commands=()

    # Check required commands
    for cmd in "${required_commands[@]}"; do
        if ! validate_command_exists "${cmd}"; then
            missing_commands+=("${cmd}")
        fi
    done

    # Report missing commands
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "init" "Missing required commands" "missing=${missing_commands[*]}"
        return "${EXIT_FAILURE}"
    fi

    log_debug "init" "Environment validation passed"
    return "${EXIT_SUCCESS}"
}

# Set up script working directory
# Usage: setup_working_directory ["target_directory"]
setup_working_directory() {
    local target_dir="${1:-.}"

    if [[ ! -d "${target_dir}" ]]; then
        log_error "init" "Working directory does not exist" "dir=${target_dir}"
        return "${EXIT_INVALID_ARGS}"
    fi

    if ! cd "${target_dir}"; then
        log_error "init" "Failed to change to working directory" "dir=${target_dir}"
        return "${EXIT_FAILURE}"
    fi

    log_debug "init" "Working directory set" "dir=$(pwd)"
    return "${EXIT_SUCCESS}"
}

#==============================================================================
# Script Template Functions
#==============================================================================

# Generate a basic script template
# Usage: generate_script_template "script_name" "description"
generate_script_template() {
    local script_name="$1"
    local description="$2"

    cat <<EOF
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
# ${script_name} - ${description}
#==============================================================================

# Initialize script
init_script "${script_name,,}" "info" "true"

#==============================================================================
# Main Function
#==============================================================================

main() {
    log_info "main" "Starting ${script_name}"

    # TODO: Implement script logic here

    log_info "main" "${script_name} completed successfully"
}

#==============================================================================
# Script Entry Point
#==============================================================================

if is_main_execution; then
    main "\$@"
fi
EOF
}

#==============================================================================
# Export Functions for Use in Other Scripts
#==============================================================================

# Export all functions so they can be used when this file is sourced
export -f init_script
export -f setup_cleanup_handlers
export -f setup_main_guard
export -f is_main_execution
export -f get_script_info
export -f validate_script_environment
export -f setup_working_directory
export -f generate_script_template
