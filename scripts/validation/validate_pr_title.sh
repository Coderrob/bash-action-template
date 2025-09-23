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
# PR Title Validation Script
#==============================================================================
# Description: Validates pull request titles against required format
# Version:     1.0.0
# Author:      GitHub Action Template
# License:     GPL-3.0
#
# Purpose:     This script validates PR titles to ensure they follow the
#              standardized format: [category][severity][case-id] Description
#
# Usage:       ./validate_pr_title.sh "PR_TITLE_HERE"
#              ./validate_pr_title.sh --help
#
# Format:      [category][severity][case-id] Description
# Examples:    [feat][major][ABC-123] Add new authentication system
#              [fix][minor][DEF-456] Resolve memory leak in utils.sh
#              [docs][patch][GHI-789] Update README with new examples
#
# Categories:  feat, fix, docs, style, refactor, test, chore, ci, perf, security
# Severities:  major, minor, patch
# Case ID:     ABC-123 (letters followed by dash and numbers)
#==============================================================================

set -euo pipefail

# Source utility functions
# shellcheck source=../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
# shellcheck source=../lib/common_args.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common_args.sh"
# shellcheck source=../lib/script_init.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/script_init.sh"

# Initialize script
init_script "validate_pr_title" "info" "true"

# Configuration
readonly VALID_CATEGORIES=("feat" "fix" "docs" "style" "refactor" "test" "chore" "ci" "perf" "security")
readonly VALID_SEVERITIES=("major" "minor" "patch")

# Expected format pattern
readonly TITLE_PATTERN='^\[([a-zA-Z]+)\]\[([a-zA-Z]+)\]\[([A-Z]+-[0-9]+)\] (.+)$'

# Display usage information
show_usage() {
    cat <<EOF
Usage: ${0} [OPTIONS] "PR_TITLE"

Validates pull request titles against the required format.

OPTIONS:
    -h, --help     Show this help message
    -v, --verbose  Enable verbose output
    -q, --quiet    Suppress non-error output

FORMAT:
    [category][severity][case-id] Description

EXAMPLES:
    [feat][major][ABC-123] Add new authentication system
    [fix][minor][DEF-456] Resolve memory leak in utils.sh
    [docs][patch][GHI-789] Update README with new examples

VALID CATEGORIES:
    ${VALID_CATEGORIES[*]}

VALID SEVERITIES:
    ${VALID_SEVERITIES[*]}

CASE ID FORMAT:
    ABC-123 (uppercase letters followed by dash and numbers)

EXIT CODES:
    0 - PR title is valid
    1 - PR title is invalid
    2 - Invalid arguments or usage
EOF
}

# Parse command line arguments
parse_arguments() {
    local verbose=false
    local quiet=false
    local pr_title=""

    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_usage
            exit 0
            ;;
        -v | --verbose)
            verbose=true
            shift
            ;;
        -q | --quiet)
            quiet=true
            shift
            ;;
        -*)
            log_error "validation" "Unknown option: $1"
            show_usage >&2
            exit 2
            ;;
        *)
            if [[ -z "${pr_title}" ]]; then
                pr_title="$1"
            else
                log_error "validation" "Multiple PR titles provided. Please provide only one."
                show_usage >&2
                exit 2
            fi
            shift
            ;;
        esac
    done

    # Export settings for use in other functions
    export VERBOSE="${verbose}"
    export QUIET="${quiet}"
    export PR_TITLE="${pr_title}"

    # Validate required arguments
    validate_required "PR_TITLE" "PR title is required" || {
        show_usage >&2
        exit "${EXIT_INVALID_ARGS}"
    }
}

# Validate array contains value
array_contains() {
    local array_name="$1"
    local value="$2"
    local -n array_ref="${array_name}"

    for item in "${array_ref[@]}"; do
        if [[ "${item}" == "${value}" ]]; then
            return 0
        fi
    done
    return 1
}

# Extract components from PR title using regex
extract_components() {
    local title="$1"

    if [[ ! "${title}" =~ ${TITLE_PATTERN} ]]; then
        return 1
    fi

    # Export extracted components
    export CATEGORY="${BASH_REMATCH[1]}"
    export SEVERITY="${BASH_REMATCH[2]}"
    export CASE_ID="${BASH_REMATCH[3]}"
    export DESCRIPTION="${BASH_REMATCH[4]}"

    return 0
}

# Validate PR title format
validate_pr_title() {
    local title="$1"

    [[ "${QUIET}" != "true" ]] && log_info "validation" "Validating PR title: ${title}"

    # Check basic format
    if ! extract_components "${title}"; then
        log_error "validation" "PR title does not follow the required format"
        log_error "validation" "Expected format: [category][severity][case-id] Description"
        log_error "validation" ""
        log_error "validation" "Examples:"
        log_error "validation" "  [feat][major][ABC-123] Add new authentication system"
        log_error "validation" "  [fix][minor][DEF-456] Resolve memory leak in utils.sh"
        log_error "validation" "  [docs][patch][GHI-789] Update README with new examples"
        log_error "validation" ""
        log_error "validation" "Valid categories: ${VALID_CATEGORIES[*]}"
        log_error "validation" "Valid severities: ${VALID_SEVERITIES[*]}"
        log_error "validation" "Valid case-id format: ABC-123 (letters followed by dash and numbers)"
        return 1
    fi

    [[ "${VERBOSE}" == "true" ]] && {
        log_info "validation" "Category: ${CATEGORY}"
        log_info "validation" "Severity: ${SEVERITY}"
        log_info "validation" "Case ID: ${CASE_ID}"
        log_info "validation" "Description: ${DESCRIPTION}"
    }

    # Validate category
    if ! array_contains "VALID_CATEGORIES" "${CATEGORY}"; then
        log_error "validation" "Invalid category '${CATEGORY}'. Valid categories: ${VALID_CATEGORIES[*]}"
        return 1
    fi

    # Validate severity
    if ! array_contains "VALID_SEVERITIES" "${SEVERITY}"; then
        log_error "validation" "Invalid severity '${SEVERITY}'. Valid severities: ${VALID_SEVERITIES[*]}"
        return 1
    fi

    # Validate case-id format (double-check even though regex matched)
    if [[ ! "${CASE_ID}" =~ ^[A-Z]+-[0-9]+$ ]]; then
        log_error "validation" "Invalid case-id format '${CASE_ID}'. Expected format: ABC-123"
        return 1
    fi

    # Validate description is not empty
    validate_not_empty "DESCRIPTION" "${DESCRIPTION}" "Description cannot be empty" || return 1

    # Validate description length and content
    if [[ ${#DESCRIPTION} -lt 10 ]]; then
        log_warn "validation" "Description is quite short (${#DESCRIPTION} characters). Consider adding more detail."
    fi

    [[ "${QUIET}" != "true" ]] && log_info "validation" "PR title format is valid ✓"
    return 0
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Validate the PR title
    if validate_pr_title "${PR_TITLE}"; then
        [[ "${QUIET}" != "true" ]] && log_info "validation" "✅ PR title validation passed"
        exit 0
    else
        log_error "validation" "❌ PR title validation failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if is_main_execution; then
    main "$@"
fi
