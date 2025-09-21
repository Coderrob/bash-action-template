# Bash Action Template

A comprehensive template for creating GitHub Actions using bash scripts with industry best practices for DevOps, shell scripting, and CI/CD.

## 🚀 Features

- **Composite Action**: Uses GitHub's composite action approach for better reusability
- **Best Practices**: Implements shell scripting best practices with proper error handling
- **Comprehensive Logging**: Multiple log levels with colored output and structured logging
- **Input Validation**: Robust input validation and sanitization
- **CI/CD Pipeline**: Automated testing, linting, and security scanning
- **Code Quality**: ShellCheck linting and shfmt formatting
- **Documentation**: Comprehensive documentation with examples
- **Security**: Security scanning and best practices implementation
- **Self-Healing**: Automated repository maintenance with rate limit checking, snippet updates, and license header management

## 📁 Project Structure

```
bash-action-template/
├── action.yml                 # GitHub Action definition
├── scripts/
│   ├── main.sh               # Main action script
│   └── utils.sh              # Utility functions and helpers
├── .github/
│   └── workflows/
│       └── ci.yml            # CI/CD pipeline
├── .shellcheckrc             # ShellCheck configuration
├── .editorconfig             # Editor configuration
├── CONTRIBUTING.md           # Contribution guidelines
└── README.md                 # This file
```

## 🔧 Usage

### Basic Usage

```yaml
- name: Run Bash Action
  uses: your-username/your-action-repo@v1
  with:
    example-input: "your-value"
```

### Advanced Usage

```yaml
- name: Run Bash Action with Custom Settings
  uses: your-username/your-action-repo@v1
  with:
    example-input: "your-value"
    working-directory: "./subdirectory"
    log-level: "debug"
```

## 📥 Inputs

| Input               | Description                                              | Required | Default         |
| ------------------- | -------------------------------------------------------- | -------- | --------------- |
| `example-input`     | An example input parameter                               | No       | `default-value` |
| `working-directory` | Working directory for the action                         | No       | `.`             |
| `log-level`         | Log level (debug, info, warn, error)                     | No       | `info`          |
| `include-summary`   | Whether to generate and output a summary report          | No       | `false`         |
| `check-rate-limit`  | Whether to check GitHub API rate limits before execution | No       | `true`          |

## 📤 Outputs

| Output           | Description                      |
| ---------------- | -------------------------------- |
| `example-output` | An example output value          |
| `execution-time` | Script execution time in seconds |

## 🛠️ Development

### Prerequisites

- Bash 4.0 or higher
- Git
- ShellCheck (for linting)
- shfmt (for formatting)

### Getting Started

1. **Use this template** by clicking the "Use this template" button on GitHub
2. **Clone your new repository**:

   ```bash
   git clone https://github.com/your-username/your-action-repo.git
   cd your-action-repo
   ```

3. **Customize the action**:

   - Update `action.yml` with your action's metadata
   - Modify `scripts/main.sh` with your business logic
   - Update this README with your specific documentation

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

### Adding New Inputs

1. **Update `action.yml`**:

   ```yaml
   inputs:
     your-new-input:
       description: "Description of your input"
       required: false
       default: "default-value"
   ```

2. **Handle in scripts**:

   ```bash
   local your_input="${INPUT_YOUR_NEW_INPUT:-}"
   # Process the input...
   ```

### Adding New Outputs

1. **Update `action.yml`**:

   ```yaml
   outputs:
     your-new-output:
       description: "Description of your output"
       value: ${{ steps.main-script.outputs.your-new-output }}
   ```

2. **Set in scripts**:

   ```bash
   set_output "your-new-output" "your-value"
   ```

### Custom Utility Functions

Add reusable functions to `scripts/utils.sh`:

```bash
# Your custom function
your_custom_function() {
    local param="$1"

    log_debug "Processing: ${param}"
    # Your logic here...

    echo "result"
}
```

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

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [ShellCheck](https://github.com/koalaman/shellcheck) for shell script analysis
- [shfmt](https://github.com/mvdan/sh) for shell script formatting

## 📞 Support

If you have any questions or need help with this template:

- 📋 [Create an issue](https://github.com/your-username/your-action-repo/issues)
- 💬 [Start a discussion](https://github.com/your-username/your-action-repo/discussions)

---

## Happy scripting! 🎉
