# Quick Fixes Runbook

!!! info "RunMe Interactive Runbook"
This runbook provides quick diagnostic and remediation steps for common issues with the bash-action-template. Click the **Run** button next to each code block to execute it.

## Initial Diagnostics

### Check Environment Setup

```bash
# Verify we're in the right directory
pwd && ls -la

# Check if scripts are executable
ls -la scripts/

# Verify Node.js and npm are available (for DevContainer)
node --version && npm --version

# Check if act is available for testing
which act || echo "act not found - install with: curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash"
```

### Validate Action Structure

```bash
# Check action.yml syntax
cat action.yml

# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('action.yml'))" && echo "✅ action.yml is valid YAML"

# Check main script syntax
bash -n scripts/services/main.sh && echo "✅ main.sh syntax is valid"

# Check utils script syntax
bash -n scripts/lib/utils.sh && echo "✅ utils.sh syntax is valid"
```

## Common Quick Fixes

### Fix Script Permissions

```bash
# Make all scripts executable
chmod +x scripts/*.sh
echo "✅ All scripts are now executable"
```

### Fix Missing Dependencies

```bash
# Install common missing tools
which shellcheck || (echo "Installing shellcheck..." && apt-get update && apt-get install -y shellcheck)
which shfmt || (echo "Installing shfmt..." && wget -O /tmp/shfmt.tar.gz https://github.com/mvdan/sh/releases/download/v3.7.0/shfmt_v3.7.0_linux_amd64.tar.gz && tar -xzf /tmp/shfmt.tar.gz -C /tmp && mv /tmp/shfmt_v3.7.0_linux_amd64/shfmt /usr/local/bin/shfmt && chmod +x /usr/local/bin/shfmt)
which act || (echo "Installing act..." && wget -O /tmp/act.tar.gz https://github.com/nektos/act/releases/download/v0.2.55/act_Linux_x86_64.tar.gz && tar -xzf /tmp/act.tar.gz -C /tmp && mv /tmp/act /usr/local/bin/act && chmod +x /usr/local/bin/act)

echo "✅ Dependencies check complete"
```

### Clean Build Artifacts

```bash
# Remove temporary files and caches
rm -rf /tmp/github_outputs/
rm -rf /tmp/test_logs/
rm -f /tmp/action-output*

# Clean any generated files
find . -name "*.tmp" -delete
find . -name "*.log" -delete

echo "✅ Cleanup complete"
```

## Testing & Validation

### Run Local Action Test

```bash
# Set up test environment
export INPUT_EXAMPLE_INPUT="test-input"
export INPUT_LOG_LEVEL="debug"
export GITHUB_OUTPUT="/tmp/action-output-test"

# Run the action
./scripts/services/main.sh

# Check output
echo "Action output:"
cat /tmp/action-output-test
```

### Validate with act (GitHub Actions Simulator)

```bash
# Test with act if available
if which act >/dev/null 2>&1; then
    echo "Running action with act..."
    act -j test-action --container-architecture linux/amd64 -v
else
    echo "act not installed. Install with: curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash"
fi
```

### Run CI Checks Locally

```bash
# Run linting
if which shellcheck >/dev/null 2>&1; then
    find scripts/ -name "*.sh" -exec shellcheck {} \;
    echo "✅ ShellCheck passed"
else
    echo "⚠️ ShellCheck not available"
fi

# Run formatting check
if which shfmt >/dev/null 2>&1; then
    find scripts/ -name "*.sh" -exec shfmt -d {} \;
    echo "✅ Formatting check passed"
else
    echo "⚠️ shfmt not available"
fi
```

## Advanced Diagnostics

### Check GitHub API Rate Limits

```bash
# Check if GITHUB_TOKEN is available
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    echo "GITHUB_TOKEN is set"
    # Check rate limit status
    curl -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" https://api.github.com/rate_limit
else
    echo "GITHUB_TOKEN not set - some features may be limited"
fi
```

### Validate Workflow Files

```bash
# Check all workflow files
for workflow in .github/workflows/*.yml; do
    echo "Validating $workflow..."
    python3 -c "import yaml; yaml.safe_load(open('$workflow'))" && echo "✅ $workflow is valid"
done
```

### Performance Profiling

```bash
# Time action execution
echo "Timing action execution..."
time (
    export INPUT_EXAMPLE_INPUT="performance-test"
    export INPUT_LOG_LEVEL="info"
    export GITHUB_OUTPUT="/tmp/perf-output"
    ./scripts/services/main.sh >/dev/null 2>&1
)
echo "✅ Performance test complete"
```

## Emergency Recovery

### Reset to Clean State

```bash
# WARNING: This will reset your working directory
echo "⚠️  This will reset all uncommitted changes!"
read -p "Are you sure? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git reset --hard HEAD
    git clean -fd
    echo "✅ Repository reset to clean state"
else
    echo "Operation cancelled"
fi
```

### Reinstall DevContainer Environment

```bash
# If using DevContainer, rebuild environment
echo "To rebuild DevContainer environment:"
echo "1. Close VS Code"
echo "2. Delete .devcontainer/.vscode-server directory"
echo "3. Reopen in VS Code and select 'Rebuild Container'"
```

## Getting Help

If these quick fixes don't resolve your issue:

1. **Check the full documentation**: Visit our [maintenance guide](maintenance.md)
2. **Search existing issues**: Look at [GitHub Issues](https://github.com/Coderrob/bash-action-template/issues)
3. **Create a new issue**: Provide detailed information about your problem
4. **Join the discussion**: Check [GitHub Discussions](https://github.com/Coderrob/bash-action-template/discussions)

### Diagnostic Information to Include

When asking for help, please include:

```bash
# System information
uname -a
bash --version

# Repository state
git status
git log --oneline -5

# Environment info
env | grep -E "(GITHUB|INPUT|ACTION)" | head -10
```
