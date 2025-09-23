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

format: check-tools ## Check shell script formatting with shfmt and prettier
	@echo "Checking shell script formatting..."
	@if command -v shfmt >/dev/null 2>&1; then \
		find . -name "*.sh" -type f | xargs shfmt -l -d; \
	else \
		echo "shfmt not installed. Run 'make install-tools' first."; \
		exit 1; \
	fi
	@echo "Checking markdown/yaml formatting..."
	@if command -v prettier >/dev/null 2>&1; then \
		prettier --check "**/*.{md,yml,yaml}" --ignore-path .gitignore || echo "Prettier formatting issues found"; \
	else \
		echo "prettier not installed. Run 'make install-tools' first."; \
	fi

format-fix: check-tools ## Autofix shell script formatting and prettier formatting
	@echo "Autofixing shell script formatting..."
	@if command -v shfmt >/dev/null 2>&1; then \
		find . -name "*.sh" -type f | xargs shfmt -l -w; \
		echo "Shell formatting applied."; \
	else \
		echo "shfmt not installed. Run 'make install-tools' first."; \
		exit 1; \
	fi
	@echo "Autofixing markdown/yaml formatting..."
	@if command -v prettier >/dev/null 2>&1; then \
		prettier --write "**/*.{md,yml,yaml}" --ignore-path .gitignore; \
		echo "Prettier formatting applied."; \
	else \
		echo "prettier not installed. Run 'make install-tools' first."; \
	fi

pre-commit-install: ## Install pre-commit hooks
	@echo "Installing pre-commit hooks..."
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit install; \
		pre-commit install --hook-type commit-msg; \
	else \
		echo "pre-commit not installed. Run 'make install-tools' first."; \
		exit 1; \
	fi

pre-commit-run: ## Run pre-commit on all files
	@echo "Running pre-commit on all files..."
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo "pre-commit not installed. Run 'make install-tools' first."; \
		exit 1; \
	fi

pre-commit-update: ## Update pre-commit hooks
	@echo "Updating pre-commit hooks..."
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit autoupdate; \
	else \
		echo "pre-commit not installed. Run 'make install-tools' first."; \
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
install-tools: ## Install development tools (ShellCheck, shfmt, prettier, pre-commit)
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
	@echo "Installing prettier..."
	@if ! command -v prettier >/dev/null 2>&1; then \
		if command -v npm >/dev/null 2>&1; then \
			npm install -g prettier; \
		else \
			echo "Please install Node.js and npm first, then run: npm install -g prettier"; \
		fi; \
	else \
		echo "prettier already installed"; \
	fi
	@echo "Installing pre-commit..."
	@if ! command -v pre-commit >/dev/null 2>&1; then \
		if command -v pip3 >/dev/null 2>&1; then \
			pip3 install pre-commit; \
		elif command -v pip >/dev/null 2>&1; then \
			pip install pre-commit; \
		else \
			echo "Please install Python and pip first, then run: pip install pre-commit"; \
		fi; \
	else \
		echo "pre-commit already installed"; \
	fi

check-tools: ## Check if required tools are installed
	@echo "Checking required tools..."
	@command -v shellcheck >/dev/null 2>&1 || (echo "ShellCheck not found. Run 'make install-tools'"; exit 1)
	@echo "✓ ShellCheck found"
	@command -v shfmt >/dev/null 2>&1 || (echo "shfmt not found. Run 'make install-tools'"; exit 1)
	@echo "✓ shfmt found"
	@command -v prettier >/dev/null 2>&1 || (echo "prettier not found. Run 'make install-tools'"; exit 1)
	@echo "✓ prettier found"
	@command -v pre-commit >/dev/null 2>&1 || (echo "pre-commit not found. Run 'make install-tools'"; exit 1)
	@echo "✓ pre-commit found"
	@command -v python3 >/dev/null 2>&1 || (echo "python3 not found. Required for YAML validation"; exit 1)
	@echo "✓ python3 found"

permissions-check: ## Check script permissions (CI simulation)
	@echo "Checking script permissions..."
	@find scripts -name "*.sh" -type f | while read -r script; do \
		if [[ ! -x "$$script" ]]; then \
			echo "Error: Script $$script is not executable"; \
			exit 1; \
		fi; \
	done
	@echo "✓ All scripts are executable"

security-check: ## Run security scan (CI simulation)
	@echo "Running security scan..."
	@echo "Checking for potential security issues..."
	@if grep -r -i "password\|secret\|key\|token" scripts/ --include="*.sh" | grep -v "INPUT_"; then \
		echo "Warning: Potential hardcoded secrets found"; \
		exit 1; \
	fi
	@if grep -r "eval" scripts/ --include="*.sh"; then \
		echo "Warning: eval usage found - review for security implications"; \
		exit 1; \
	fi
	@if grep -r "curl.*-k\|curl.*--insecure" scripts/ --include="*.sh"; then \
		echo "Error: Insecure curl usage found"; \
		exit 1; \
	fi
	@echo "✓ Security scan passed"

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

# Integration testing with act (GitHub Actions simulator)
act-test: ## Test the action using act (requires devcontainer or act installation)
	@echo "Testing action with act..."
	@if ! command -v act >/dev/null 2>&1; then \
		echo "act not found. Please run in devcontainer or install act."; \
		echo "See: https://github.com/nektos/act"; \
		exit 1; \
	fi
	@act -j test-action --container-architecture linux/amd64 -v

act-test-matrix: ## Test the action with different input combinations using act
	@echo "Testing action matrix with act..."
	@if ! command -v act >/dev/null 2>&1; then \
		echo "act not found. Please run in devcontainer or install act."; \
		exit 1; \
	fi
	@act -j test-matrix --container-architecture linux/amd64 -v

act-ci: ## Run full CI workflow using act
	@echo "Running full CI workflow with act..."
	@if ! command -v act >/dev/null 2>&1; then \
		echo "act not found. Please run in devcontainer or install act."; \
		exit 1; \
	fi
	@act --container-architecture linux/amd64 -v

act-pr: ## Simulate pull request workflow using act
	@echo "Simulating pull request workflow with act..."
	@if ! command -v act >/dev/null 2>&1; then \
		echo "act not found. Please run in devcontainer or install act."; \
		exit 1; \
	fi
	@act pull_request --container-architecture linux/amd64 -v

act-push: ## Simulate push workflow using act
	@echo "Simulating push workflow with act..."
	@if ! command -v act >/dev/null 2>&1; then \
		echo "act not found. Please run in devcontainer or install act."; \
		exit 1; \
	fi
	@act push --container-architecture linux/amd64 -v

test-action: ## Test the action with CI-like inputs
	@echo "Testing action with default inputs..."
	@export INPUT_EXAMPLE_INPUT="test-value" && \
	 export INPUT_LOG_LEVEL="info" && \
	 export INPUT_WORKING_DIRECTORY="." && \
	 export GITHUB_OUTPUT="/tmp/github_output_test_default" && \
	 ./scripts/main.sh > /tmp/action_test_default.log 2>&1 && \
	 echo "✓ Default test passed" || (echo "✗ Default test failed"; cat /tmp/action_test_default.log; exit 1)

	@echo "Testing action with custom inputs..."
	@export INPUT_EXAMPLE_INPUT="custom-test-value" && \
	 export INPUT_LOG_LEVEL="debug" && \
	 export INPUT_WORKING_DIRECTORY="." && \
	 export GITHUB_OUTPUT="/tmp/github_output_test_custom" && \
	 ./scripts/main.sh > /tmp/action_test_custom.log 2>&1 && \
	 echo "✓ Custom test passed" || (echo "✗ Custom test failed"; cat /tmp/action_test_custom.log; exit 1)

	@echo "Verifying outputs..."
	@if [[ ! -f "/tmp/github_output_test_default" ]] || [[ ! -f "/tmp/github_output_test_custom" ]]; then \
		echo "✗ Output files not created"; \
		exit 1; \
	fi
	@if ! grep -q "example-output=test-value" /tmp/github_output_test_default; then \
		echo "✗ Default output verification failed"; \
		exit 1; \
	fi
	@if ! grep -q "example-output=CUSTOM-TEST-VALUE" /tmp/github_output_test_custom; then \
		echo "✗ Custom output verification failed"; \
		exit 1; \
	fi
	@echo "✓ All action tests passed"

# CI simulation
ci: lint format permissions-check security-check validate test-action ## Run all CI checks locally
	@echo "All CI checks passed!"

ci-lint: lint permissions-check ## Run lint checks only
	@echo "Lint checks passed!"

ci-format: format ## Run format checks only
	@echo "Format checks passed!"

ci-security: security-check ## Run security checks only
	@echo "Security checks passed!"

ci-validate: validate ## Run validation checks only
	@echo "Validation checks passed!"

ci-test: test-action ## Run test checks only
	@echo "Test checks passed!"

# Development workflow
dev-setup: install-tools permissions pre-commit-install ## Set up development environment
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
