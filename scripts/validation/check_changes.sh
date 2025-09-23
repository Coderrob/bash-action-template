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
# Check for Repository Changes Script
#==============================================================================
# Description: Checks if the repository has uncommitted changes
# Version:     1.0.0
# Author:      GitHub Action Template
# License:     GPL-3.0
#
# Purpose:     This script checks for changes in the repository and sets
#              GitHub Actions output accordingly. It supports force update mode.
#
# Usage:       ./check_changes.sh [--force]
#
# Outputs:     Sets GITHUB_OUTPUT with 'changes=true|false'
#==============================================================================

set -euo pipefail

# Source utility functions
# shellcheck source=../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
# shellcheck source=../lib/script_init.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/script_init.sh"

# Initialize script
init_script "check_changes" "info" "true"

# Parse command line arguments
parse_arguments() {
    local force_update=false

    while [[ $# -gt 0 ]]; do
        case $1 in
        --force)
            force_update=true
            shift
            ;;
        -h | --help)
            show_usage
            exit 0
            ;;
        *)
            log_error "check-changes" "Unknown option: $1"
            exit 1
            ;;
        esac
    done

    export FORCE_UPDATE="${force_update}"
}

# Display usage information
show_usage() {
    cat <<EOF
Usage: ${0} [OPTIONS]

Checks for repository changes and sets GitHub Actions output.

OPTIONS:
    --force        Force update even if no changes detected
    -h, --help     Show this help message

OUTPUTS:
    Sets GITHUB_OUTPUT with 'changes=true|false'

EXAMPLES:
    ${0}                    # Check for changes normally
    ${0} --force           # Force update regardless of changes
EOF
}

# Check for repository changes
check_repository_changes() {
    local changes_detected=false

    log_info "check-changes" "Checking for repository changes..."

    # Check git status for uncommitted changes
    if [[ -n "$(git status --porcelain)" ]]; then
        changes_detected=true
        log_info "check-changes" "Uncommitted changes detected"

        # Show what changed (for debugging)
        if [[ "${LOG_LEVEL:-info}" == "debug" ]]; then
            log_debug "check-changes" "Changed files:"
            git status --porcelain | while read -r line; do
                log_debug "check-changes" "  ${line}"
            done
        fi
    else
        log_info "check-changes" "No uncommitted changes detected"
    fi

    # Check force update flag
    if [[ "${FORCE_UPDATE}" == "true" ]]; then
        changes_detected=true
        log_info "check-changes" "Force update requested"
    fi

    # Set GitHub Actions output
    if [[ "${changes_detected}" == "true" ]]; then
        echo "changes=true" >>"${GITHUB_OUTPUT:-/dev/stdout}"
        log_info "check-changes" "✅ Changes detected or force update requested"
        return 0
    else
        echo "changes=false" >>"${GITHUB_OUTPUT:-/dev/stdout}"
        log_info "check-changes" "ℹ️ No changes detected"
        return 1
    fi
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Check for changes
    check_repository_changes
}

# Run main function if script is executed directly
if is_main_execution; then
    main "$@"
fi
