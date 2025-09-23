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
# Constants Library - Shared Constants for Bash Scripts
#==============================================================================
# Description: Centralized constants used across all bash scripts in the project.
#              This ensures consistency and makes maintenance easier.
#==============================================================================

# Prevent multiple sourcing
if [[ -z "${CONSTANTS_SOURCED+x}" ]]; then
    readonly CONSTANTS_SOURCED=true

    # Exit Codes
    readonly EXIT_SUCCESS=0
    readonly EXIT_FAILURE=1
    readonly EXIT_INVALID_ARGS=2
    readonly EXIT_ENVIRONMENT_ERROR=3
    readonly EXIT_PERMISSION_DENIED=4
    readonly EXIT_FILE_NOT_FOUND=5
    readonly EXIT_COMMAND_NOT_FOUND=6

    # Log Levels (numeric values for comparison)
    readonly LOG_LEVEL_DEBUG=0
    readonly LOG_LEVEL_INFO=1
    readonly LOG_LEVEL_WARN=2
    readonly LOG_LEVEL_ERROR=3

    # Color Codes for Output
    readonly COLOR_RESET='\033[0m'
    readonly COLOR_NC='\033[0m' # No Color alias
    readonly COLOR_BLACK='\033[0;30m'
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[1;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_MAGENTA='\033[0;35m'
    readonly COLOR_CYAN='\033[0;36m'
    readonly COLOR_WHITE='\033[0;37m'
    readonly COLOR_BOLD='\033[1m'
    readonly COLOR_DIM='\033[2m'
    readonly COLOR_UNDERLINE='\033[4m'

    # Default Values
    readonly DEFAULT_LOG_LEVEL="info"
    readonly DEFAULT_WORKING_DIR="."
    readonly DEFAULT_TIMEOUT=30
    readonly DEFAULT_MAX_RETRIES=3
    readonly DEFAULT_RETRY_DELAY=5

    # File and Directory Paths
    readonly SCRIPT_DIR
    SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
    readonly PROJECT_ROOT
    PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
    readonly TEMPLATES_DIR="${PROJECT_ROOT}/templates"
    readonly TESTS_DIR="${PROJECT_ROOT}/tests"
    readonly DOCS_DIR="${PROJECT_ROOT}/docs"

    # Template Files
    readonly SCRIPT_TEMPLATE="${TEMPLATES_DIR}/script_template.sh"
    readonly WORKFLOW_TEMPLATE="${TEMPLATES_DIR}/workflow_template.yml"
    readonly SUMMARY_TEMPLATE="${TEMPLATES_DIR}/summary_template.md"
    readonly ISSUE_TEMPLATE="${TEMPLATES_DIR}/issue_template.md"
    readonly PR_TEMPLATE="${TEMPLATES_DIR}/pull_request_template.md"

    # Configuration Files
    readonly SHELLCHECK_CONFIG="${PROJECT_ROOT}/.shellcheckrc"
    readonly EDITOR_CONFIG="${PROJECT_ROOT}/.editorconfig"

    # GitHub Actions Related
    readonly GITHUB_API_BASE="https://api.github.com"
    readonly GITHUB_API_VERSION="2022-11-28"
    readonly DEFAULT_ARTIFACT_RETENTION=30

    # Validation Patterns
    readonly SEMVER_PATTERN='^[0-9]+\.[0-9]+\.[0-9]+$'
    readonly EMAIL_PATTERN='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    readonly URL_PATTERN='^https?://[^\s/$.?#].[^\s]*$'
    readonly UUID_PATTERN='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

    # PR Title Validation
    readonly PR_TITLE_PATTERN='^\[([a-zA-Z]+)\]\[([a-zA-Z]+)\]\[([A-Z]+-[0-9]+)\] (.+)$'
    readonly VALID_PR_CATEGORIES=("feat" "fix" "docs" "style" "refactor" "test" "chore" "ci" "perf" "security")
    readonly VALID_PR_SEVERITIES=("major" "minor" "patch")

    # File Extensions and Types
    readonly SHELL_EXTENSIONS=("sh" "bash")
    readonly SCRIPT_EXTENSIONS=("sh" "bash" "py" "js" "ts")
    readonly CONFIG_EXTENSIONS=("yml" "yaml" "json" "toml" "ini" "cfg")

    # Size Limits
    readonly MAX_FILE_SIZE_KB=1024
    readonly MAX_LINE_LENGTH=120
    readonly MAX_FUNCTION_LENGTH=100

    # Time Formats
    readonly ISO_DATE_FORMAT="%Y-%m-%d"
    readonly ISO_TIME_FORMAT="%H:%M:%S"
    readonly ISO_DATETIME_FORMAT="%Y-%m-%dT%H:%M:%SZ"

    # Common Messages
    readonly MSG_SUCCESS="✅ Operation completed successfully"
    readonly MSG_FAILURE="❌ Operation failed"
    readonly MSG_WARNING="⚠️  Warning"
    readonly MSG_INFO="ℹ️  Info"
    readonly MSG_DEBUG="🔍 Debug"

    # Error Messages
    readonly ERR_FILE_NOT_FOUND="File not found"
    readonly ERR_PERMISSION_DENIED="Permission denied"
    readonly ERR_INVALID_ARGUMENT="Invalid argument"
    readonly ERR_COMMAND_FAILED="Command execution failed"
    readonly ERR_NETWORK_ERROR="Network error"
    readonly ERR_VALIDATION_FAILED="Validation failed"
    readonly ERR_TIMEOUT="Operation timed out"

    # Success Messages
    readonly SUCCESS_FILE_CREATED="File created successfully"
    readonly SUCCESS_OPERATION_COMPLETED="Operation completed successfully"
    readonly SUCCESS_VALIDATION_PASSED="Validation passed"
    readonly SUCCESS_BUILD_COMPLETED="Build completed successfully"

    # Progress Messages
    readonly PROGRESS_STARTING="Starting operation..."
    readonly PROGRESS_PROCESSING="Processing..."
    readonly PROGRESS_COMPLETING="Completing operation..."
    readonly PROGRESS_CLEANUP="Cleaning up..."
fi
