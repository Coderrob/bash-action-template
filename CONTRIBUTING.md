# Contributing to Bash Action Template

Thank you for your interest in contributing to this project! This document provides guidelines and information for contributors.

## 🤝 Code of Conduct

By participating in this project, you are expected to uphold our code of conduct:

- **Be respectful**: Treat everyone with respect and kindness
- **Be inclusive**: Welcome newcomers and help them get started
- **Be constructive**: Provide helpful feedback and suggestions
- **Be collaborative**: Work together towards common goals

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have:

- Bash 4.0 or higher
- Git
- ShellCheck for linting
- shfmt for formatting
- A GitHub account

### Development Setup

1. **Fork the repository**
2. **Clone your fork**:

   ```bash
   git clone https://github.com/your-username/bash-action-template-.git
   cd bash-action-template-
   ```

3. **Create a feature branch**:

   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Set up pre-commit hooks** (optional but recommended):

   ```bash
   # Install pre-commit
   pip install pre-commit

   # Install hooks
   pre-commit install
   ```

### DevContainer Development Environment

For the most consistent development experience with all tools pre-configured, use the DevContainer:

1. **Open in DevContainer**:
   - Install the "Dev Containers" extension in VS Code
   - Open the repository in VS Code
   - Use Command Palette: `Dev Containers: Reopen in Container`

2. **Benefits**:
   - All development tools automatically installed and configured
   - Consistent environment across all contributors
   - Full integration testing with `act` (GitHub Actions simulator)
   - Pre-configured VS Code settings and extensions

3. **Testing in DevContainer**:

   ```bash
   # Run all CI checks locally
   make ci

   # Integration testing with act
   make act-test
   make act-ci

   # Test different scenarios
   make act-test-matrix
   ```

### Manual Development Setup

This repository uses automated self-healing workflows to maintain code quality and keep dependencies up-to-date.

### Self-Healing Workflow

A daily scheduled workflow performs the following maintenance tasks:

- **Rate Limit Checking**: Ensures sufficient GitHub API calls before operations
- **VS Code Snippets**: Updates GitHub Actions snippets from upstream repository
- **License Headers**: Adds GNU GPL v3 license headers to source files
- **Automated Commits**: Creates maintenance branches and pull requests

### Manual Maintenance

You can also trigger maintenance manually:

```bash
# Run the self-healing workflow manually
gh workflow run self-healing.yml
```

### Maintenance Branches

Automated maintenance creates branches with the pattern `self-healing/{run_id}` and opens pull requests for review.

## 🔧 Development Guidelines

### Shell Scripting Standards

- **Use `set -euo pipefail`** at the beginning of scripts
- **Quote variables** to prevent word splitting: `"${variable}"`
- **Use `readonly`** for constants
- **Use `local`** for function variables
- **Follow the existing code style** and formatting

### Code Quality

All contributions must pass:

- **ShellCheck**: Static analysis for shell scripts
- **shfmt**: Code formatting validation
- **CI tests**: All automated tests must pass

### Testing Your Changes

1. **Run linting**:

   ```bash
   find . -name "*.sh" -type f | xargs shellcheck
   ```

2. **Check formatting**:

   ```bash
   find . -name "*.sh" -type f | xargs shfmt -l -d
   ```

3. **Test the action locally**:

   ```bash
   export INPUT_EXAMPLE_INPUT="test-value"
   export INPUT_LOG_LEVEL="debug"
   ./scripts/services/main.sh
   ```

4. **Run the CI workflow locally** (if you have act installed):

   ```bash
   act -j lint
   act -j test
   ```

## 📝 Commit Guidelines

### Commit Message Format

Use the conventional commits specification:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **test**: Adding missing tests or correcting existing tests
- **chore**: Changes to the build process or auxiliary tools

### Examples

```bash
feat: add input validation for file paths
fix: resolve issue with error handling in utils.sh
docs: update README with new usage examples
test: add tests for utility functions
```

## 📋 Pull Request Process

1. **Ensure your code follows** the style guidelines
2. **Update documentation** if necessary
3. **Add tests** for new functionality
4. **Update the README.md** with details of changes if applicable
5. **Ensure all CI checks pass**
6. **Request review** from maintainers

### Pull Request Title Convention

All pull request titles must follow the strict format:

```text
[category][severity][case-id] Description
```

#### Components

- **category**: The type of change
  - `feat`: A new feature
  - `fix`: A bug fix
  - `docs`: Documentation only changes
  - `style`: Changes that do not affect the meaning of the code (formatting, etc.)
  - `refactor`: A code change that neither fixes a bug nor adds a feature
  - `test`: Adding missing tests or correcting existing tests
  - `chore`: Changes to the build process or auxiliary tools
  - `ci`: Changes to CI/CD configuration
  - `perf`: Performance improvements
  - `security`: Security-related changes

- **severity**: The impact level of the change
  - `major`: Breaking changes or significant new features
  - `minor`: New features that are backwards compatible
  - `patch`: Bug fixes and small improvements

- **case-id**: A unique identifier in the format `ABC-123` (uppercase letters, dash, numbers)

- **Description**: A clear, concise description of the change

#### PR Title Examples

```markdown
[feat][major][AUTH-001] Add OAuth2 authentication support
[fix][patch][BUG-123] Resolve memory leak in utils.sh
[docs][minor][DOC-456] Update API documentation with new endpoints
[refactor][major][REFACTOR-789] Restructure codebase for better maintainability
[test][patch][TEST-101] Add unit tests for validation functions
[ci][minor][CI-202] Migrate to GitHub Actions from Travis CI
```

#### Validation

PR titles are automatically validated by a GitHub Actions workflow. If your PR title doesn't match the required format, the CI will fail with detailed error messages explaining the expected format.

### Pull Request Template

When creating a PR, please include:

- **Description of changes**
- **Motivation and context**
- **Type of change** (bug fix, new feature, etc.)
- **Testing performed**
- **Checklist of completed items**

## 🐛 Reporting Issues

### Bug Reports

When reporting bugs, please include:

- **Clear description** of the issue
- **Steps to reproduce** the problem
- **Expected behavior**
- **Actual behavior**
- **Environment details** (OS, Bash version, etc.)
- **Relevant logs** or error messages

### Feature Requests

For feature requests, please include:

- **Clear description** of the feature
- **Use case** and motivation
- **Proposed implementation** (if you have ideas)
- **Alternative solutions** considered

## 📚 Documentation

### Documentation Standards

- **Use clear, concise language**
- **Include code examples** where helpful
- **Keep documentation up-to-date** with code changes
- **Follow Markdown best practices**

### Types of Documentation

- **README.md**: Main project documentation
- **Code comments**: Inline documentation for complex logic
- **Action metadata**: Descriptions in `action.yml`
- **Contributing guidelines**: This document

## 🔒 Security

### Reporting Security Issues

**Do not report security vulnerabilities through public GitHub issues.**

Instead, please email the maintainers directly or use GitHub's private vulnerability reporting feature.

### Security Guidelines

- **Never commit secrets** or sensitive information
- **Validate all inputs** thoroughly
- **Use secure coding practices**
- **Follow the principle of least privilege**

## 🏷️ Release Process

Releases follow semantic versioning (SemVer):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

### Release Steps

1. **Update version** in relevant files
2. **Update CHANGELOG.md**
3. **Create release PR**
4. **Tag the release**
5. **Publish GitHub release**

## 💡 Tips for Contributors

- **Start small**: Begin with documentation fixes or small bug fixes
- **Ask questions**: Don't hesitate to ask for clarification
- **Be patient**: Reviews take time, especially for complex changes
- **Stay updated**: Keep your fork synchronized with the main repository
- **Test thoroughly**: Always test your changes before submitting

## 📞 Getting Help

If you need help or have questions:

- **Check existing issues** and discussions
- **Read the documentation** thoroughly
- **Ask in discussions** for general questions
- **Create an issue** for specific problems

## 🙏 Recognition

Contributors will be recognized in:

- **README.md**: Contributors section
- **Release notes**: Major contributions acknowledged
- **GitHub**: Contributor statistics and graphs

---

Thank you for contributing to make this project better! 🎉
