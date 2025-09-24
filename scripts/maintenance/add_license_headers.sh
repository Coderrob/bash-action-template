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

# Add license headers to source files
# Ensures all source files have appropriate license headers

set -euo pipefail

# Source utility functions
# shellcheck source=../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
# shellcheck source=../lib/script_init.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/script_init.sh"

# Initialize script
init_script "add_license_headers" "info" "true"

LICENSE_FILE="LICENSE"
HEADER_TEMPLATE="#==============================================================================
#
#    Copyright (C) $(date +%Y) Robert Lindley
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

"

add_license_headers() {
    log_info "license" "Starting license header check and update"

    # Check if LICENSE file exists
    if [[ ! -f "${LICENSE_FILE}" ]]; then
        log_warn "license" "LICENSE file not found, skipping license header updates"
        return 0
    fi

    local files_updated=0

    # Find source files that should have license headers
    while IFS= read -r -d '' file; do
        # Skip if file already has a license header
        if head -20 "${file}" | grep -q "GNU General Public License"; then
            log_debug "license" "File already has license header: ${file}"
            continue
        fi

        # Skip binary files and certain file types
        if [[ "${file}" =~ \.(png|jpg|jpeg|gif|ico|svg|pdf|zip|tar\.gz|woff|woff2|eot|ttf)$ ]]; then
            continue
        fi

        # Skip certain directories
        if [[ "${file}" =~ ^(\.git|node_modules|build|dist)/ ]]; then
            continue
        fi

        log_info "license" "Adding license header to: ${file}"

        # Create a temporary file with header + original content
        {
            echo "${HEADER_TEMPLATE}"
            echo ""
            cat "${file}"
        } >"${file}.tmp"

        # Move temporary file back
        mv "${file}.tmp" "${file}"

        ((files_updated++))
    done < <(find . -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.md" \) -print0 2>/dev/null)

    log_info "license" "License header update completed" "files_updated=${files_updated}"

    if [[ ${files_updated} -gt 0 ]]; then
        return 0
    else
        return 1 # No changes made
    fi
}

# Run the update if called directly
if is_main_execution; then
    add_license_headers "$@"
fi
