# Bash Action Template

A production-ready GitHub Action template implementing shell scripting best practices, functional programming principles, and enterprise-grade observability. Features zero-boilerplate initialization, comprehensive testing framework, and security-first design.

## 🚀 Key Features

### Code Quality & Architecture

- **Zero Boilerplate**: Centralized `init.sh` eliminates 87% of repeated setup code
- **Functional Programming**: Pure functions with immutable parameters
- **Single Responsibility**: One definitive implementation for each component
- **Type Safety**: Comprehensive input validation and sanitization
- **Security First**: Built-in security patterns and secure defaults

### Enterprise Observability

- **Structured Logging**: JSON-compatible logging with metadata and context
- **Performance Monitoring**: Automatic timing, resource tracking, and metrics collection
- **Error Tracking**: Comprehensive error context with stack traces
- **Business Metrics**: Built-in support for custom metrics and KPIs

### Developer Experience

- **Comprehensive Testing**: Advanced test framework with performance monitoring
- **Rich Documentation**: Detailed guides, examples, and architecture documentation
- **Easy Migration**: Simple upgrade path from existing shell scripts
- **IDE Integration**: Full ShellCheck support and VS Code development snippets

## 📁 Architecture

The template follows a clean, single-responsibility architecture with centralized utilities:

```bash
bash-action-template/
├── action.yml                    # GitHub Action definition
├── scripts/
│   ├── init.sh                   # Centralized initialization (eliminates boilerplate)
│   ├── functional_utils.sh       # Pure functional programming utilities
│   ├── main.sh                   # Main script demonstrating best practices
│   ├── utils.sh                  # Core utility functions and helpers
│   ├── summary.sh                # Summary generation and reporting
│   ├── add_license_headers.sh    # License management automation
│   └── update_snippets.sh        # VS Code snippets updater
├── tests/
│   ├── test_runner.sh            # Comprehensive test framework
│   ├── simple_test.sh            # Basic validation tests
│   └── summarization_test.sh     # Summary functionality tests
├── docs/
│   └── enhanced-architecture.md  # Detailed architecture documentation
├── .github/workflows/
│   ├── ci.yml                    # CI/CD pipeline
│   └── self-healing.yml          # Automated maintenance
├── .shellcheckrc                 # ShellCheck configuration
├── .editorconfig                 # Editor configuration
├── CONTRIBUTING.md               # Contribution guidelines
└── README.md                     # This documentation
```

### Core Components

- **`init.sh`**: Centralized initialization that handles logging setup, error handling, summary integration, and common patterns
- **`functional_utils.sh`**: Collection of pure functions for string manipulation, validation, security, and data processing
- **`main.sh`**: Demonstrates the complete implementation with functional programming and observability patterns
- **`test_runner.sh`**: Advanced testing framework with performance monitoring and comprehensive reporting

## � Quick Start

### Zero-Boilerplate Script Creation

Create a production-ready script with comprehensive observability in just a few lines:

```bash
#!/bin/bash
# Source the centralized initialization - handles all common setup
source "$(dirname "${BASH_SOURCE[0]}")/init.sh"

# Initialize with logging, summary, and optional rate limiting
init_script "info" "true" "true"

# Your business logic here - error handling is automatic!
main() {
    log_info "startup" "Script started" "version=1.0.0"

    # Process inputs with built-in validation
    local readonly user_input="${INPUT_USER_INPUT:-}"
    validate_var_set "user_input" "$user_input" || exit 1

    # Use pure functions for data processing (immutable parameters)
    local processed_result
    processed_result="$(to_uppercase "$(trim_string "$user_input")")"

    # Security-first: sanitize before output
    processed_result="$(sanitize_input "$processed_result")"

    # Output with automatic monitoring and summary integration
    set_output "result" "$processed_result"
    log_success "completion" "Script completed" "result=$processed_result"
}

main "$@"
```

### GitHub Action Usage

```yaml
- name: Run Bash Action
  uses: your-username/bash-action-template@v1
  with:
    user-input: "your-value"
    log-level: "info"
    include-summary: "true"
```

### Advanced Configuration

```yaml
- name: Run with Full Observability
  uses: your-username/bash-action-template@v1
  with:
    user-input: "production-data"
    working-directory: "./subdirectory"
    log-level: "debug"
    include-summary: "true"
    check-rate-limit: "true"
```

### Testing Your Implementation

```bash
# Run the comprehensive test suite
./tests/test_runner.sh

# Expected output:
# ✅ PASS: File Existence (0.002s)
# ✅ PASS: Script Permissions (0.001s)
# ✅ PASS: Utility Functions (0.015s)
# ✅ PASS: String Functions (0.008s)
# ✅ PASS: Basic Execution (0.245s)
#
# Test Suite Summary
# ==================
# Total Tests: 5
# Passed: 5 (100%)
# Failed: 0
# Total Time: 0.271s
```

## 📥 Inputs

| Input               | Description                                              | Required | Default         |
| ------------------- | -------------------------------------------------------- | -------- | --------------- |
| `user-input`        | User input for processing and transformation             | No       | `default-value` |
| `working-directory` | Working directory for the action                         | No       | `.`             |
| `log-level`         | Log level (debug, info, warn, error)                     | No       | `info`          |
| `include-summary`   | Whether to generate and output a summary report          | No       | `false`         |
| `check-rate-limit`  | Whether to check GitHub API rate limits before execution | No       | `true`          |

## 📤 Outputs

| Output           | Description                      |
| ---------------- | -------------------------------- |
| `result`         | Processed and validated result   |
| `execution-time` | Script execution time in seconds |
| `summary`        | Comprehensive execution summary  |

## 🛠️ Development

### Prerequisites

- Bash 4.4 or higher (for functional programming features)
- Git
- ShellCheck (for static analysis)
- shfmt (for code formatting)

### Getting Started

1. **Use this template** by clicking the "Use this template" button on GitHub

2. **Clone your new repository**:

   ```bash
   git clone https://github.com/your-username/your-action-repo.git
   cd your-action-repo
   ```

3. **Customize the action**:
   - Update `action.yml` with your action's metadata
   - Modify `scripts/main.sh` with your business logic (or create new scripts using `init.sh`)
   - Leverage `scripts/functional_utils.sh` for data processing with pure functions
   - Use `tests/test_runner.sh` as a template for comprehensive testing

### Development Workflow

The template provides a streamlined development experience:

```bash
# Make scripts executable
chmod +x scripts/*.sh tests/*.sh

# Test your implementation
./tests/test_runner.sh

# Run functional tests with performance monitoring
./tests/simple_test.sh

# Test string manipulation functions
source scripts/functional_utils.sh
echo "$(to_uppercase "$(trim_string "  hello world  ")")"  # Outputs: HELLO WORLD
```

### Key Development Patterns

1. **Initialize with zero boilerplate**:

   ```bash
   source "$(dirname "${BASH_SOURCE[0]}")/init.sh"
   init_script "info" "true" "true"
   ```

2. **Use pure functions for data processing**:

   ```bash
   # From functional_utils.sh
   result="$(to_uppercase "$(sanitize_input "$user_input")")"
   ```

3. **Implement comprehensive testing**:
   ```bash
   # From test_runner.sh patterns
   run_test "Test Name" test_function_name
   ```

### DevContainer Development Environment

For the best development experience with full integration testing capabilities, use the included DevContainer:

1. **Open in DevContainer**:

   - Install the "Dev Containers" extension in VS Code
   - Open the repository in VS Code
   - When prompted, click "Reopen in Container" or use Command Palette: `Dev Containers: Reopen in Container`

2. **What's included**:

   - All development tools pre-installed (ShellCheck, shfmt, Prettier, act)
   - GitHub CLI and Git configured
   - VS Code extensions for shell development
   - Pre-configured settings for code quality

3. **Integration Testing with act**:

   ```bash
   # Test the action using GitHub Actions simulator
   make act-test

   # Run full CI workflow simulation
   make act-ci

   # Test with different input combinations
   make act-test-matrix

   # Simulate pull request workflow
   make act-pr
   ```

4. **Available Make targets in DevContainer**:

   ```bash
   make ci              # Run all local CI checks
   make act-test        # Integration test with act
   make act-ci          # Full CI simulation
   make lint            # Code linting
   make format          # Code formatting
   make test-action     # Local action testing
   ```

### Local Development (without DevContainer)

If you prefer not to use DevContainer, you can set up the environment manually:

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Set environment variables for testing
export INPUT_EXAMPLE_INPUT="test-value"
export INPUT_LOG_LEVEL="debug"

# Run the main script
./scripts/main.sh
```

### Code Quality

This template includes several code quality tools:

- **ShellCheck**: Static analysis for shell scripts
- **shfmt**: Shell script formatter
- **EditorConfig**: Consistent coding styles

Run linting:

```bash
# Install ShellCheck (Ubuntu/Debian)
sudo apt-get install shellcheck

# Run ShellCheck
find . -name "*.sh" -type f | xargs shellcheck

# Install shfmt
curl -L "https://github.com/mvdan/sh/releases/latest/download/shfmt_v3.7.0_linux_amd64" -o shfmt
chmod +x shfmt
sudo mv shfmt /usr/local/bin/

# Check formatting
find . -name "*.sh" -type f | xargs shfmt -l -d

# Auto-format (if needed)
find . -name "*.sh" -type f | xargs shfmt -l -w
```

### Testing

The repository includes automated tests in the CI pipeline:

- **Linting**: ShellCheck analysis of all shell scripts
- **Formatting**: Code formatting validation with shfmt
- **Functional Testing**: Action execution with various inputs
- **Security Scanning**: Basic security checks for common issues
- **Action Validation**: Metadata and structure validation

## 🔒 Security Best Practices

This template implements several security best practices:

- **Input Sanitization**: All inputs are validated and sanitized
- **No Hardcoded Secrets**: Uses GitHub's secret management
- **Minimal Permissions**: Scripts run with minimal required permissions
- **Error Handling**: Comprehensive error handling prevents information leakage
- **Logging**: Secure logging that doesn't expose sensitive information

## 📚 Customization Guide

### Adding New Functionality

The template's architecture makes it easy to extend functionality while maintaining best practices:

#### 1. Update Action Metadata

Update `action.yml` with new inputs/outputs:

```yaml
inputs:
  your-new-input:
    description: "Description of your input"
    required: false
    default: "default-value"
outputs:
  your-new-output:
    description: "Description of your output"
    value: ${{ steps.main-script.outputs.your-new-output }}
```

#### 2. Implement with Zero Boilerplate

Create your script using the centralized initialization:

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/init.sh"
init_script "info" "true" "true"

main() {
    local readonly your_input="${INPUT_YOUR_NEW_INPUT:-}"
    validate_var_set "your_input" "$your_input" || exit 1

    # Use pure functions for processing
    local result
    result="$(your_custom_function "$your_input")"

    set_output "your-new-output" "$result"
    log_success "completion" "Processing completed" "result=$result"
}

main "$@"
```

#### 3. Add Pure Functions

Extend `scripts/functional_utils.sh` with new pure functions:

```bash
# Pure function: same input always produces same output
your_custom_function() {
    local readonly input="$1"

    # Validate input (pure functions should validate their parameters)
    [[ -n "$input" ]] || { echo "ERROR: Input required" >&2; return 1; }

    # Process with immutable approach
    local result
    result="$(to_lowercase "$(trim_string "$input")")"

    # Return result (no side effects)
    echo "$result"
}
```

#### 4. Add Comprehensive Tests

Extend `tests/test_runner.sh` with new test cases:

```bash
test_your_custom_function() {
    local result

    # Test normal case
    result="$(your_custom_function "  HELLO WORLD  ")"
    assert_equals "hello world" "$result" "Should trim and lowercase"

    # Test edge cases
    result="$(your_custom_function "")"
    assert_non_zero "$?" "Should fail on empty input"

    return 0
}
```

### Architecture Patterns

The template enforces several key patterns for maintainable code:

- **Single Responsibility**: Each file has one clear purpose
- **Pure Functions**: Functions in `functional_utils.sh` have no side effects
- **Centralized Initialization**: All scripts use `init.sh` for consistent setup
- **Comprehensive Testing**: Every function should have corresponding tests
- **Security First**: All inputs are validated and sanitized

## � Self-Healing Features

This template includes automated self-healing capabilities to keep your repository up-to-date and well-maintained.

### Rate Limit Protection

The action automatically checks GitHub API rate limits before execution to prevent failures:

```yaml
- uses: your-username/your-action@v1
  with:
    check-rate-limit: true # Default: true
```

### Automated Maintenance

A scheduled workflow runs daily to perform maintenance tasks:

- **VS Code Snippets**: Updates GitHub Actions snippets from [Coderrob/github-actions-snippets](https://github.com/Coderrob/github-actions-snippets)
- **License Headers**: Adds GNU GPL v3 license headers to source files
- **Automated PRs**: Creates pull requests for maintenance updates

### Self-Healing Workflow

The `.github/workflows/self-healing.yml` runs automatically and:

1. Checks GitHub API rate limits
2. Updates VS Code snippets
3. Adds license headers to new files
4. Commits changes to a `self-healing/{run_id}` branch
5. Creates a pull request for review

## �🤝 Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 🏷️ Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your-username/your-action-repo/tags).

## 🙏 Acknowledgments

- [GitHub Actions Documentation](https://docs.github.com/en/actions) for composite action patterns
- [ShellCheck](https://github.com/koalaman/shellcheck) for comprehensive shell script analysis
- [shfmt](https://github.com/mvdan/sh) for consistent shell script formatting
- [Bash Functional Programming](https://mywiki.wooledge.org/BashGuide) for pure function patterns
- [VS Code GitHub Actions Snippets](https://github.com/Coderrob/github-actions-snippets) for development acceleration

## 📞 Support

If you have questions, need help implementing functional programming patterns, or want to contribute improvements:

- 📋 [Create an issue](https://github.com/your-username/your-action-repo/issues) for bugs or feature requests
- 💬 [Start a discussion](https://github.com/your-username/your-action-repo/discussions) for architecture questions
- 🔍 Check `docs/enhanced-architecture.md` for detailed implementation patterns
- 🧪 Review `tests/test_runner.sh` for testing best practices

---

## Happy scripting with zero boilerplate! 🎉

Transform your shell scripts into production-ready, observable, and maintainable solutions.
