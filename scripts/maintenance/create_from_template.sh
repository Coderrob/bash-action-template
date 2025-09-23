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
# Template Generator Script
#==============================================================================
# Description: Creates new files from templates with placeholder replacement
# Version:     1.0.0
# Author:      GitHub Action Template
# License:     GPL-3.0
#
# Purpose:     This script helps create new files from templates by copying
#              template files and replacing placeholders with actual values.
#
# Usage:       ./create_from_template.sh [OPTIONS] TEMPLATE_NAME OUTPUT_PATH
#
# Examples:    ./create_from_template.sh script_template.sh scripts/my_script.sh
#              ./create_from_template.sh --interactive workflow_template.yml .github/workflows/my_workflow.yml
#==============================================================================

set -euo pipefail

# Source utility functions
# shellcheck source=../lib/utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
# shellcheck source=../lib/script_init.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/script_init.sh"

# Initialize script
init_script "create_from_template" "info" "true"

# Configuration
readonly TEMPLATES_DIR="$(dirname "${BASH_SOURCE[0]}")/../templates"
readonly SCRIPT_VERSION="1.0.0"

# Global variables
INTERACTIVE=false
TEMPLATE_NAME=""
OUTPUT_PATH=""

# Display usage information
show_usage() {
    cat <<EOF
Usage: ${0} [OPTIONS] TEMPLATE_NAME OUTPUT_PATH

Creates new files from templates with placeholder replacement.

OPTIONS:
    -h, --help          Show this help message
    -i, --interactive   Interactive mode with prompts for placeholders
    -l, --list          List available templates
    --version           Show version information

ARGUMENTS:
    TEMPLATE_NAME       Name of the template file (e.g., script_template.sh)
    OUTPUT_PATH         Path where the new file should be created

EXAMPLES:
    ${0} script_template.sh scripts/my_new_script.sh
    ${0} --interactive workflow_template.yml .github/workflows/deploy.yml
    ${0} --list

AVAILABLE TEMPLATES:
$(find "${TEMPLATES_DIR}" -name "*.sh" -o -name "*.md" -o -name "*.yml" | sort | sed 's|.*/||' | sed 's/^/    /')

EOF
}

# List available templates
list_templates() {
    echo "📁 Available templates in ${TEMPLATES_DIR}:"
    echo

    for template in "${TEMPLATES_DIR}"/*; do
        if [[ -f "${template}" && ! "${template}" =~ README\.md$ ]]; then
            local filename
            filename=$(basename "${template}")
            local description=""

            # Try to extract description from file
            case "${filename}" in
            *.sh)
                description=$(grep -m1 "^# Description:" "${template}" 2>/dev/null | sed 's/^# Description: //' || echo "Bash script template")
                ;;
            *.md)
                description=$(head -5 "${template}" | grep -v "^#" | head -1 | sed 's/<!-- //' | sed 's/ -->//' || echo "Markdown template")
                ;;
            *.yml)
                description="GitHub Actions workflow template"
                ;;
            *)
                description="Template file"
                ;;
            esac

            printf "  %-25s %s\n" "${filename}" "${description}"
        fi
    done
    echo
    echo "Use: ${0} TEMPLATE_NAME OUTPUT_PATH"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_usage
            exit 0
            ;;
        --version)
            echo "Template Generator v${SCRIPT_VERSION}"
            exit 0
            ;;
        -l | --list)
            list_templates
            exit 0
            ;;
        -i | --interactive)
            INTERACTIVE=true
            shift
            ;;
        -*)
            log_error "args" "Unknown option: $1"
            show_usage >&2
            exit 2
            ;;
        *)
            if [[ -z "${TEMPLATE_NAME}" ]]; then
                TEMPLATE_NAME="$1"
            elif [[ -z "${OUTPUT_PATH}" ]]; then
                OUTPUT_PATH="$1"
            else
                log_error "args" "Too many arguments: $1"
                show_usage >&2
                exit 2
            fi
            shift
            ;;
        esac
    done

    # Validate required arguments
    validate_required "TEMPLATE_NAME" "Template name is required" || {
        show_usage >&2
        exit "${EXIT_INVALID_ARGS}"
    }

    validate_required "OUTPUT_PATH" "Output path is required" || {
        show_usage >&2
        exit "${EXIT_INVALID_ARGS}"
    }

    export INTERACTIVE TEMPLATE_NAME OUTPUT_PATH
}

# Create file from template
create_from_template() {
    local template_file="${TEMPLATES_DIR}/${TEMPLATE_NAME}"

    # Validate template exists
    if [[ ! -f "${template_file}" ]]; then
        log_error "template" "Template not found: ${template_file}"
        log_info "template" "Available templates:"
        list_templates
        return 1
    fi

    # Validate output directory exists
    local output_dir
    output_dir=$(dirname "${OUTPUT_PATH}")
    if [[ ! -d "${output_dir}" ]]; then
        log_info "template" "Creating output directory: ${output_dir}"
        mkdir -p "${output_dir}"
    fi

    # Check if output file already exists
    if [[ -f "${OUTPUT_PATH}" ]]; then
        log_warn "template" "Output file already exists: ${OUTPUT_PATH}"
        read -p "Overwrite? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "template" "Aborted by user"
            return 1
        fi
    fi

    log_info "template" "Creating ${OUTPUT_PATH} from ${TEMPLATE_NAME}"

    # Copy template to output location
    cp "${template_file}" "${OUTPUT_PATH}"

    # Make executable if it's a shell script
    if [[ "${OUTPUT_PATH}" =~ \.sh$ ]]; then
        chmod +x "${OUTPUT_PATH}"
        log_info "template" "Made script executable"
    fi

    # Interactive placeholder replacement
    if [[ "${INTERACTIVE}" == "true" ]]; then
        replace_placeholders_interactive
    else
        log_info "template" "File created. You may need to replace placeholders manually."
        log_info "template" "Common placeholders: {{YEAR}}, {{AUTHOR}}, {{SCRIPT_NAME}}, {{DESCRIPTION}}"
    fi

    log_info "template" "✅ Successfully created ${OUTPUT_PATH}"
}

# Interactive placeholder replacement
replace_placeholders_interactive() {
    log_info "template" "Interactive placeholder replacement"

    # Common placeholders with defaults
    local year
    year=$(date +%Y)
    local author="${USER:-$(whoami)}"

    # Extract placeholders from file
    local placeholders
    placeholders=$(grep -o '{{[^}]*}}' "${OUTPUT_PATH}" | sort -u | sed 's/[{}]//g')

    if [[ -z "${placeholders}" ]]; then
        log_info "template" "No placeholders found in template"
        return 0
    fi

    echo "Found placeholders to replace:"
    for placeholder in ${placeholders}; do
        echo "  {{${placeholder}}}"
    done
    echo

    # Replace each placeholder
    for placeholder in ${placeholders}; do
        local default_value=""
        local prompt="Enter value for {{${placeholder}}}"

        # Provide defaults for common placeholders
        case "${placeholder}" in
        YEAR) default_value="${year}" ;;
        AUTHOR | AUTHOR_NAME) default_value="${author}" ;;
        SCRIPT_NAME) default_value=$(basename "${OUTPUT_PATH}" .sh | tr '_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1') ;;
        VERSION) default_value="1.0.0" ;;
        esac

        if [[ -n "${default_value}" ]]; then
            prompt="${prompt} [${default_value}]"
        fi

        read -p "${prompt}: " -r value
        if [[ -z "${value}" && -n "${default_value}" ]]; then
            value="${default_value}"
        fi

        if [[ -n "${value}" ]]; then
            sed -i "s|{{${placeholder}}}|${value}|g" "${OUTPUT_PATH}"
            log_debug "template" "Replaced {{${placeholder}}} with '${value}'"
        fi
    done
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Create file from template
    if create_from_template; then
        exit 0
    else
        log_error "main" "Failed to create file from template"
        exit 1
    fi
}

# Run main function if script is executed directly
if is_main_execution; then
    main "$@"
fi
