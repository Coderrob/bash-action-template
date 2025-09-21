# 🔧 Maintenance Runbook

!!! info "RunMe Interactive Runbook"
This runbook provides scheduled maintenance procedures to keep your bash-action-template healthy and up-to-date. Run these regularly to prevent issues.

## 📅 Daily Maintenance

### Update Dependencies

```bash
# Update package lists
apt-get update

# Upgrade system packages (be careful in production!)
apt-get upgrade -y

# Update Node.js dependencies if any
if [[ -f "package.json" ]]; then
    npm audit fix
fi

echo "✅ Dependencies updated"
```

### Clean Old Logs and Artifacts

```bash
# Remove old log files (older than 7 days)
find . -name "*.log" -type f -mtime +7 -delete

# Clean temporary directories
rm -rf /tmp/github_outputs/
rm -rf /tmp/test_logs/

# Remove old test artifacts
find . -name "test-output-*" -type f -mtime +1 -delete

# Clean Docker images (if using Docker)
docker system prune -f

echo "✅ Cleanup completed"
```

### Validate Repository Health

```bash
# Check for broken symlinks
find . -type l -exec test ! -e {} \; -print

# Validate all YAML files
for file in $(find . -name "*.yml" -o -name "*.yaml"); do
    echo "Checking $file..."
    python3 -c "import yaml; yaml.safe_load(open('$file'))" || echo "❌ $file has YAML errors"
done

# Check script syntax
for script in scripts/*.sh; do
    echo "Checking $script..."
    bash -n "$script" || echo "❌ $script has syntax errors"
done

echo "✅ Health check completed"
```

## 📊 Weekly Maintenance

### Security Audit

```bash
# Run security audit on dependencies
if [[ -f "package.json" ]]; then
    npm audit
fi

# Check for vulnerable patterns in code
echo "Checking for common security issues..."

# Look for hardcoded secrets
grep -r "password\|secret\|token\|key" --include="*.sh" . | grep -v "INPUT_" | grep -v "GITHUB_" || echo "No hardcoded secrets found"

# Check for eval usage
grep -r "eval" --include="*.sh" . || echo "No eval usage found"

# Check for insecure curl
grep -r "curl.*-k\|curl.*--insecure" --include="*.sh" . || echo "No insecure curl found"

echo "✅ Security audit completed"
```

### Performance Monitoring

```bash
# Benchmark action execution time
echo "Running performance benchmarks..."

# Test with different input sizes
for size in 100 1000 10000; do
    input=$(head -c $size < /dev/zero | tr '\0' 'x')
    export INPUT_EXAMPLE_INPUT="$input"
    export GITHUB_OUTPUT="/tmp/perf-test-$size"

    start_time=$(date +%s%N)
    ./scripts/main.sh >/dev/null 2>&1
    end_time=$(date +%s%N)

    duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
    echo "Input size $size: ${duration}ms"
done

echo "✅ Performance benchmarks completed"
```

### Update Tool Versions

```bash
# Check current tool versions
echo "Current tool versions:"
shellcheck --version
shfmt --version
act --version 2>/dev/null || echo "act not installed"

# Check for updates (manual step - would need automation)
echo "To update tools manually:"
echo "1. shellcheck: Check https://github.com/koalaman/shellcheck/releases"
echo "2. shfmt: Check https://github.com/mvdan/sh/releases"
echo "3. act: Check https://github.com/nektos/act/releases"

echo "✅ Version check completed"
```

## 📈 Monthly Maintenance

### Comprehensive Testing

```bash
# Run full test suite
echo "Running comprehensive tests..."

# Unit tests (if any)
if [[ -d "tests/" ]]; then
    for test in tests/*.sh; do
        echo "Running $test..."
        bash "$test" || echo "❌ $test failed"
    done
fi

# Integration tests with act
if which act >/dev/null 2>&1; then
    echo "Running integration tests with act..."
    act -j test-action --container-architecture linux/amd64 || echo "❌ Integration tests failed"
else
    echo "act not available for integration testing"
fi

echo "✅ Comprehensive testing completed"
```

### Code Quality Review

```bash
# Run all linting and formatting checks
echo "Running code quality checks..."

# ShellCheck
find scripts/ -name "*.sh" -exec shellcheck {} \;

# Formatting check
find scripts/ -name "*.sh" -exec shfmt -d {} \;

# YAML validation
find . -name "*.yml" -o -name "*.yaml" | xargs -I {} python3 -c "import yaml; yaml.safe_load(open('{}'))"

echo "✅ Code quality review completed"
```

### Backup Important Data

```bash
# Create timestamped backup
timestamp=$(date +%Y%m%d_%H%M%S)
backup_dir="/tmp/bash-action-backup-$timestamp"

mkdir -p "$backup_dir"

# Backup configuration files
cp action.yml "$backup_dir/"
cp -r scripts/ "$backup_dir/"
cp -r .github/ "$backup_dir/"

# Create archive
tar -czf "$backup_dir.tar.gz" -C /tmp "bash-action-backup-$timestamp"

echo "✅ Backup created: $backup_dir.tar.gz"
echo "Consider storing this in a safe location"
```

## 🔄 Self-Healing Procedures

### Automated Repository Maintenance

```bash
# Run self-healing workflow (if available)
if [[ -f ".github/workflows/self-healing.yml" ]]; then
    echo "Triggering self-healing workflow..."
    # This would typically be done via GitHub API
    echo "Manual trigger: Go to Actions tab and run 'Self-Healing' workflow"
else
    echo "Self-healing workflow not configured"
fi
```

### Fix Common Issues Automatically

```bash
# Auto-fix script permissions
chmod +x scripts/*.sh

# Auto-fix common formatting issues
if which shfmt >/dev/null 2>&1; then
    find scripts/ -name "*.sh" -exec shfmt -w {} \;
    echo "✅ Scripts auto-formatted"
fi

# Clean up whitespace in YAML files
for file in $(find . -name "*.yml" -o -name "*.yaml"); do
    # Remove trailing whitespace
    sed -i 's/[[:space:]]*$//' "$file"
done

echo "✅ Auto-fixes applied"
```

## 📋 Maintenance Checklist

Use this checklist to ensure all maintenance tasks are completed:

### Daily Tasks

- [ ] Update system packages
- [ ] Clean temporary files
- [ ] Validate repository health

### Weekly Tasks

- [ ] Run security audit
- [ ] Performance monitoring
- [ ] Check tool versions

### Monthly Tasks

- [ ] Comprehensive testing
- [ ] Code quality review
- [ ] Create backups

### Quarterly Tasks

- [ ] Review and update dependencies
- [ ] Audit access permissions
- [ ] Update documentation

## 🚨 Alert Configuration

### Set Up Monitoring Alerts

```bash
# Example: Monitor for failed workflows
echo "To set up workflow failure alerts:"
echo "1. Go to repository Settings > Notifications"
echo "2. Configure email alerts for workflow failures"
echo "3. Set up Slack/Discord webhooks for critical alerts"

# Example: Monitor repository size
repo_size=$(du -sh . | cut -f1)
echo "Current repository size: $repo_size"

if [[ $(du -s . | cut -f1) -gt 100000 ]]; then
    echo "⚠️ Repository size is getting large. Consider cleanup."
fi
```

## 📞 Escalation Procedures

If maintenance tasks reveal critical issues:

1. **Stop automated processes** immediately
2. **Create a new branch** for emergency fixes
3. **Notify team members** via appropriate channels
4. **Document the issue** with detailed reproduction steps
5. **Implement fix** with comprehensive testing
6. **Deploy gradually** with rollback plan ready

Remember: **Maintenance is prevention, not reaction**. Regular attention keeps small issues from becoming big problems.
