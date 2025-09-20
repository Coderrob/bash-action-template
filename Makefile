# Makefile for Bash Action Template

.PHONY: help test lint format clean install-tools check-tools validate

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Development targets
test: ## Run all tests
	@echo "Running tests..."
	@./tests/simple_test.sh

lint: check-tools ## Run ShellCheck on all shell scripts
	@echo "Running ShellCheck..."
	@find . -name "*.sh" -type f | xargs shellcheck -e SC1091

format: check-tools ## Check shell script formatting with shfmt
	@echo "Checking shell script formatting..."
	@if command -v shfmt >/dev/null 2>&1; then \
		find . -name "*.sh" -type f | xargs shfmt -l -d; \
	else \
		echo "shfmt not installed. Run 'make install-tools' first."; \
		exit 1; \
	fi

format-fix: check-tools ## Auto-fix shell script formatting
	@echo "Auto-fixing shell script formatting..."
	@if command -v shfmt >/dev/null 2>&1; then \
		find . -name "*.sh" -type f | xargs shfmt -l -w; \
		echo "Formatting applied."; \
	else \
		echo "shfmt not installed. Run 'make install-tools' first."; \
		exit 1; \
	fi

validate: ## Validate action.yml and required files
	@echo "Validating action structure..."
	@python3 -c "import yaml; yaml.safe_load(open('action.yml'))" && echo "✓ action.yml is valid YAML"
	@test -f scripts/main.sh && echo "✓ scripts/main.sh exists"
	@test -x scripts/main.sh && echo "✓ scripts/main.sh is executable"
	@test -f scripts/utils.sh && echo "✓ scripts/utils.sh exists"
	@test -x scripts/utils.sh && echo "✓ scripts/utils.sh is executable"
	@test -f .shellcheckrc && echo "✓ .shellcheckrc exists"
	@test -f .editorconfig && echo "✓ .editorconfig exists"
	@test -f .github/workflows/ci.yml && echo "✓ CI workflow exists"

# Tool installation
install-tools: ## Install development tools (ShellCheck, shfmt)
	@echo "Installing development tools..."
	@echo "Installing ShellCheck..."
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		if command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y shellcheck; \
		elif command -v brew >/dev/null 2>&1; then \
			brew install shellcheck; \
		else \
			echo "Please install ShellCheck manually: https://github.com/koalaman/shellcheck#installing"; \
		fi; \
	else \
		echo "ShellCheck already installed"; \
	fi
	@echo "Installing shfmt..."
	@if ! command -v shfmt >/dev/null 2>&1; then \
		if command -v go >/dev/null 2>&1; then \
			go install mvdan.cc/sh/v3/cmd/shfmt@latest; \
		else \
			echo "Downloading shfmt binary..."; \
			curl -L "https://github.com/mvdan/sh/releases/latest/download/shfmt_v3.7.0_linux_amd64" -o /tmp/shfmt; \
			chmod +x /tmp/shfmt; \
			sudo mv /tmp/shfmt /usr/local/bin/shfmt; \
		fi; \
	else \
		echo "shfmt already installed"; \
	fi

check-tools: ## Check if required tools are installed
	@echo "Checking required tools..."
	@command -v shellcheck >/dev/null 2>&1 || (echo "ShellCheck not found. Run 'make install-tools'"; exit 1)
	@echo "✓ ShellCheck found"

# Utility targets
clean: ## Clean up temporary files and test artifacts
	@echo "Cleaning up..."
	@rm -rf tests/output/
	@rm -f /tmp/github_output_test
	@find . -name "*.tmp" -type f -delete 2>/dev/null || true
	@find . -name "*.temp" -type f -delete 2>/dev/null || true
	@echo "Cleanup completed"

permissions: ## Fix script permissions
	@echo "Setting correct permissions..."
	@chmod +x scripts/*.sh
	@chmod +x tests/*.sh
	@echo "Permissions updated"

# Testing targets
test-local: ## Test the action locally with sample inputs
	@echo "Testing action locally..."
	@export INPUT_EXAMPLE_INPUT="local-test" && \
	 export INPUT_LOG_LEVEL="debug" && \
	 export INPUT_WORKING_DIRECTORY="." && \
	 export GITHUB_OUTPUT="/tmp/github_output_test" && \
	 ./scripts/main.sh
	@echo "Local test completed"

# CI simulation
ci: lint validate test ## Run all CI checks locally
	@echo "All CI checks passed!"

# Development workflow
dev-setup: install-tools permissions ## Set up development environment
	@echo "Development environment setup completed"

# Release preparation
pre-release: clean ci format-fix ## Prepare for release
	@echo "Pre-release checks completed"
	@echo "Ready for release!"

# Documentation
docs: ## Generate or update documentation
	@echo "Documentation targets:"
	@echo "  - README.md: Main documentation"
	@echo "  - CONTRIBUTING.md: Contribution guidelines"
	@echo "  - examples/: Usage examples"
	@echo "All documentation is manually maintained"