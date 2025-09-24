# Maintenance Runbook

!!! info "RunMe Interactive Runbook"
This runbook provides scheduled maintenance procedures to keep your bash-action-template healthy and up-to-date. Run these regularly to prevent issues.

## Daily Maintenance

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

echo "Dependencies updated"
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

echo "Cleanup completed"
```

### Validate Repository Health

```bash
# Check for broken symlinks
find . -type l -exec test ! -e {} \; -print

# Validate all YAML files
for file in $(find . -name "*.yml" -o -name "*.yaml"); do
    echo "Checking $file..."
    python3 -c "import yaml; yaml.safe_load(open('$file'))" || echo "$file has YAML errors"
done

# Check script syntax
for script in scripts/*.sh; do
    echo "Checking $script..."
    bash -n "$script" || echo "$script has syntax errors"
done

echo "Health check completed"
```

## Security Maintenance

### Run Security Audits

```bash
# Run shell script security checks
if command -v shellcheck >/dev/null 2>&1; then
    find scripts/ -name "*.sh" -exec shellcheck --severity=warning {} \;
fi

# Check for vulnerable dependencies
if [[ -f "package.json" ]]; then
    npm audit
fi

# Scan for secrets (if tool available)
if command -v gitleaks >/dev/null 2>&1; then
    gitleaks detect --verbose
fi

echo "Security audit completed"
```

## Performance Maintenance

### Run Benchmarks

```bash
# Benchmark action execution time
echo "Benchmarking action performance..."

start_time=$(date +%s.%3N)
export INPUT_EXAMPLE_INPUT="benchmark-test"
export INPUT_LOG_LEVEL="error"
export GITHUB_OUTPUT="/tmp/benchmark-output"

./scripts/services/main.sh >/dev/null 2>&1

end_time=$(date +%s.%3N)
execution_time=$(echo "$end_time - $start_time" | bc)

echo "Execution time: ${execution_time}s"

echo "Performance benchmarks completed"
```

## Version Management

### Check for Updates

```bash
# Check for newer versions of tools
check_tool_version() {
    local tool=$1
    local current_version
    current_version=$(command -v "$tool" >/dev/null 2>&1 && "$tool" --version 2>&1 | head -1 || echo "not installed")
    echo "$tool: $current_version"
}

check_tool_version bash
check_tool_version git
check_tool_version shellcheck
check_tool_version shfmt

echo "Version check completed"
```

## Testing Maintenance

### Run Comprehensive Tests

```bash
# Run all available tests
echo "Running comprehensive test suite..."

# Unit tests
if [[ -f "tests/test_runner.sh" ]]; then
    ./tests/test_runner.sh
fi

# Integration tests with act
if command -v act >/dev/null 2>&1; then
    act -j test --container-architecture linux/amd64
fi

# Load tests (if implemented)
if [[ -f "tests/load_test.sh" ]]; then
    ./tests/load_test.sh
fi

echo "Comprehensive testing completed"
```

## Code Quality Maintenance

### Automated Code Review

```bash
# Run code quality checks
echo "Running code quality analysis..."

# Lint shell scripts
if command -v shellcheck >/dev/null 2>&1; then
    find scripts/ -name "*.sh" -exec shellcheck {} \;
fi

# Format code
if command -v shfmt >/dev/null 2>&1; then
    shfmt -d scripts/*.sh
fi

# Check for TODO comments
grep -r "TODO\|FIXME\|XXX" scripts/ || echo "No TODO comments found"

echo "Code quality review completed"
```

## Backup Procedures

### Create Repository Backup

```bash
# Create timestamped backup
timestamp=$(date +%Y%m%d_%H%M%S)
backup_dir="backup_$timestamp"

mkdir -p "$backup_dir"
cp -r . "$backup_dir/"

# Compress backup
tar -czf "${backup_dir}.tar.gz" "$backup_dir"
rm -rf "$backup_dir"

echo "Backup created: ${backup_dir}.tar.gz"
```

## Self-Healing Procedures

### Automated Issue Resolution

```bash
# Attempt to fix common issues automatically
echo "Running self-healing procedures..."

# Fix permissions
chmod +x scripts/*.sh

# Auto-format code
if command -v shfmt >/dev/null 2>&1; then
    shfmt -w scripts/*.sh
    echo "Scripts auto-formatted"
fi

# Reinstall missing dependencies (if possible)
# Add dependency auto-installation logic here

echo "Autofixes applied"
```

## Maintenance Checklist

### Weekly Tasks

- [ ] Review security audit results
- [ ] Update all dependencies
- [ ] Run performance benchmarks
- [ ] Check for tool updates
- [ ] Validate backup integrity

### Monthly Tasks

- [ ] Full repository audit
- [ ] Performance optimization review
- [ ] Documentation updates
- [ ] Team knowledge sharing

### Quarterly Tasks

- [ ] Major version updates
- [ ] Architecture review
- [ ] Security assessment
- [ ] Process improvements

## Alert Configuration

### Set Up Monitoring Alerts

```bash
# Configure alerts for critical issues
setup_alerts() {
    echo "Configuring maintenance alerts..."

    # Check repository size
    repo_size=$(du -s . | cut -f1)
    if [[ $repo_size -gt 100000 ]]; then  # 100MB
        echo "Warning: Repository size is getting large. Consider cleanup."
    fi

    # Check for large files
    find . -type f -size +50M -exec ls -lh {} \;

    # Alert on failed health checks
    if ! bash health-check.sh >/dev/null 2>&1; then
        echo "Alert: Health check failed - manual intervention required"
    fi
}

setup_alerts
```

## Escalation Procedures

### When to Escalate

1. **Security Vulnerabilities**: Immediately escalate to security team
2. **Data Loss**: Escalate to data recovery team
3. **System Down**: Escalate to infrastructure team
4. **Performance Degradation**: Escalate to performance team

### Escalation Contacts

- Security Team: <security@company.com>
- Infrastructure: <infra@company.com>
- Development: <dev@company.com>

### Emergency Contacts

- On-call Engineer: +1-555-0123
- Management: +1-555-0124

---

This maintenance runbook ensures your bash-action-template remains healthy, secure, and performant. Run these procedures regularly to prevent issues before they occur.
