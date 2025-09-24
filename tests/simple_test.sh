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

# Simple test runner for the bash action template

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running basic validation tests..."

# Test 1: Check if main files exist
echo "Testing file existence..."
required_files=(
    "action.yml"
    "scripts/services/main.sh"
    "scripts/lib/utils.sh"
    ".shellcheckrc"
    ".editorconfig"
    ".github/workflows/ci.yml"
)

for file in "${required_files[@]}"; do
    if [[ -f "${SCRIPT_DIR}/../${file}" ]]; then
        echo "✓ ${file} exists"
    else
        echo "✗ ${file} is missing"
        exit 1
    fi
done

# Test 2: Check script permissions
echo ""
echo "Testing script permissions..."
for script in "${SCRIPT_DIR}/../scripts"/*.sh; do
    if [[ -x "${script}" ]]; then
        echo "✓ $(basename "${script}") is executable"
    else
        echo "✗ $(basename "${script}") is not executable"
        exit 1
    fi
done

# Test 3: Source utils.sh and test basic functions
echo ""
echo "Testing utility functions..."
cd "${SCRIPT_DIR}/.."

# shellcheck source=../scripts/lib/utils.sh
source scripts/lib/utils.sh

# Test logging initialization
if init_logging "info" >/dev/null 2>&1; then
    echo "✓ init_logging function works"
else
    echo "✗ init_logging function failed"
    exit 1
fi

# Test command_exists function
if command_exists "bash"; then
    echo "✓ command_exists function works"
else
    echo "✗ command_exists function failed"
    exit 1
fi

# Test 4: Basic action execution
echo ""
echo "Testing basic action execution..."

# Set up minimal environment
export INPUT_EXAMPLE_INPUT="test-value"
export INPUT_LOG_LEVEL="info"
export INPUT_WORKING_DIRECTORY="."
export INPUT_INCLUDE_SUMMARY="false"
export INPUT_CHECK_RATE_LIMIT="false"

# Mock GitHub Actions environment
temp_output_file="/tmp/github_output_test"
export GITHUB_OUTPUT="${temp_output_file}"

# Run the main script
if timeout 30 ./scripts/services/main.sh >/dev/null 2>&1; then
    echo "✓ Main script executes successfully"

    # Check if output was generated
    if [[ -f "${temp_output_file}" ]]; then
        echo "✓ Output file created"
        if grep -q "example-output=" "${temp_output_file}"; then
            echo "✓ Expected output generated"
        else
            echo "✗ Expected output missing"
            exit 1
        fi
    else
        echo "✗ Output file not created"
        exit 1
    fi
else
    echo "✗ Main script execution failed or timed out"
    exit 1
fi

# Cleanup
rm -f "${temp_output_file}"

echo ""
echo "🎉 All tests passed! The bash action template is working correctly."
