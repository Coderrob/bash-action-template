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

set -euo pipefail

echo "Setting up development environment..."

# Make scripts executable
chmod +x scripts/*.sh

# Install pre-commit hooks if .pre-commit-config.yaml exists
if [[ -f ".pre-commit-config.yaml" ]]; then
    echo "Installing pre-commit hooks..."
    pre-commit install
fi

# Create necessary directories
mkdir -p /tmp/github_outputs
mkdir -p /tmp/test_logs

# Verify all tools are working
echo "Verifying tool installations..."
shellcheck --version
shfmt --version
prettier --version
act --version
gh --version

# Test basic functionality
echo "Testing basic functionality..."
make --version
python3 --version

echo "Development environment setup complete!"
echo ""
echo "Available commands:"
echo "  make ci          - Run all CI checks locally"
echo "  make test-action - Test the action with various inputs"
echo "  make act-test    - Run action using act (GitHub Actions simulator)"
echo "  make dev-setup   - Set up development environment"
echo ""
echo "For integration testing with act:"
echo "  act -j test-action -v"
echo "  act pull_request -v"
echo "  act push -v"
