#!/bin/bash

#==============================================================================
# License Header Template
#==============================================================================
# This file contains the standard GPL-3.0 license header used across all
# scripts in this project to ensure consistency and reduce duplication.
#==============================================================================

generate_license_header() {
    local year="${1:-2025}"
    local author="${2:-Robert Lindley}"

    cat <<EOF
#==============================================================================
#
#    Copyright (C) ${year} ${author}
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
EOF
}

# Export function for use in other scripts
export -f generate_license_header
