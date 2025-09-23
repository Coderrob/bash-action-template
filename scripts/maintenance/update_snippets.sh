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

# Update VS Code GitHub Actions snippets
# Fetches latest snippets from Coderrob/github-actions-snippets

set -euo pipefail

# Source utility functions
# shellcheck source=../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
# shellcheck source=../lib/script_init.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/script_init.sh"

# Initialize script
init_script "update_snippets" "info" "true"

SNIPPETS_REPO="Coderrob/github-actions-snippets"
SNIPPETS_DIR=".vscode"
SNIPPETS_FILE="github-actions.code-snippets"

update_vscode_snippets() {
    log_info "snippets" "Starting VS Code snippets update from ${SNIPPETS_REPO}"

    # Create snippets directory if it doesn't exist
    mkdir -p "${SNIPPETS_DIR}"

    # Fetch latest snippets from the repository
    local api_url="https://api.github.com/repos/${SNIPPETS_REPO}/contents/${SNIPPETS_FILE}"

    log_debug "snippets" "Fetching snippets from ${api_url}"

    local response
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" "${api_url}")
    else
        response=$(curl -s -H "Accept: application/vnd.github.v3+json" "${api_url}")
    fi

    if [[ $? -ne 0 || -z "${response}" ]]; then
        log_error "snippets" "Failed to fetch snippets from repository"
        return 1
    fi

    # Check if response contains an error
    if echo "${response}" | grep -q '"message"'; then
        log_error "snippets" "API error response: $(echo "${response}" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)"
        return 1
    fi

    # Extract download URL
    local download_url
    download_url="$(echo "${response}" | grep -o '"download_url":"[^"]*"' | cut -d'"' -f4)"

    if [[ -z "${download_url}" ]]; then
        log_error "snippets" "Could not find download URL in API response"
        return 1
    fi

    log_debug "snippets" "Downloading snippets from ${download_url}"

    # Download the snippets file
    if ! curl -s -o "${SNIPPETS_DIR}/${SNIPPETS_FILE}.new" "${download_url}"; then
        log_error "snippets" "Failed to download snippets file"
        return 1
    fi

    # Check if the file is valid JSON
    if ! jq empty "${SNIPPETS_DIR}/${SNIPPETS_FILE}.new" 2>/dev/null; then
        log_error "snippets" "Downloaded file is not valid JSON"
        rm -f "${SNIPPETS_DIR}/${SNIPPETS_FILE}.new"
        return 1
    fi

    # Check if there are actual changes
    if [[ -f "${SNIPPETS_DIR}/${SNIPPETS_FILE}" ]]; then
        if diff -q "${SNIPPETS_DIR}/${SNIPPETS_FILE}" "${SNIPPETS_DIR}/${SNIPPETS_FILE}.new" >/dev/null 2>&1; then
            log_info "snippets" "Snippets are already up-to-date"
            rm -f "${SNIPPETS_DIR}/${SNIPPETS_FILE}.new"
            return 0
        fi
    fi

    # Move new file into place
    mv "${SNIPPETS_DIR}/${SNIPPETS_FILE}.new" "${SNIPPETS_DIR}/${SNIPPETS_FILE}"

    log_info "snippets" "Successfully updated VS Code snippets"
    return 0
}

# Run the update if called directly
if is_main_execution; then
    update_vscode_snippets "$@"
fi
