# Self-Healing Runbook

!!! info "RunMe Interactive Runbook"
This runbook provides automated procedures to detect and fix common repository issues. Designed to run as part of CI/CD or scheduled maintenance.

## Automated Issue Detection

### Health Check Script

```bash
#!/bin/bash
# Comprehensive health check for bash-action-template

set -euo pipefail

echo "Running comprehensive health check..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

issues_found=0

# Function to report issues
report_issue() {
    echo -e "${RED}❌ $1${NC}"
    ((issues_found++))
}

# Function to report success
report_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Check 1: Script permissions
echo "Checking script permissions..."
for script in scripts/*.sh; do
    if [[ ! -x "$script" ]]; then
        report_issue "Script $script is not executable"
        chmod +x "$script"
        report_success "Fixed permissions for $script"
    fi
done

# Check 2: YAML syntax validation
echo "Validating YAML files..."
for yaml_file in action.yml .github/workflows/*.yml; do
    if [[ -f "$yaml_file" ]]; then
        if python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
            report_success "$yaml_file syntax is valid"
        else
            report_issue "$yaml_file has YAML syntax errors"
        fi
    fi
done

# Check 3: Shell script syntax
echo "Checking shell script syntax..."
for script in scripts/*.sh; do
    if bash -n "$script" 2>/dev/null; then
        report_success "$script syntax is valid"
    else
        report_issue "$script has syntax errors"
    fi
done

# Check 4: Required tools availability
echo "Checking required tools..."
tools=("bash" "git")
for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        report_success "$tool is available"
    else
        report_issue "$tool is not available"
    fi
done

# Optional tools check
optional_tools=("shellcheck" "shfmt" "act")
for tool in "${optional_tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        report_success "$tool is available"
    else
        echo -e "${YELLOW}Warning: $tool is not available (optional)${NC}"
    fi
done

# Check 5: Repository structure
echo "Checking repository structure..."
required_files=("action.yml" "scripts/services/main.sh" "scripts/lib/utils.sh")
for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        report_success "$file exists"
    else
        report_issue "$file is missing"
    fi
done

# Check 6: Test action functionality
echo "Testing action functionality..."
if [[ -x "scripts/services/main.sh" ]]; then
    export INPUT_EXAMPLE_INPUT="health-check-test"
    export INPUT_LOG_LEVEL="info"
    export GITHUB_OUTPUT="/tmp/health-check-output"

    if ./scripts/services/main.sh >/dev/null 2>&1; then
        if [[ -f "/tmp/health-check-output" ]]; then
            report_success "Action executes successfully"
        else
            report_issue "Action executed but no output file created"
        fi
    else
        report_issue "Action execution failed"
    fi
else
    report_issue "Main script is not executable"
fi

# Summary
echo
if [[ $issues_found -eq 0 ]]; then
    echo -e "${GREEN}All health checks passed! Repository is healthy.${NC}"
    exit 0
else
    echo -e "${RED}Found $issues_found issue(s) that need attention.${NC}"
    exit 1
fi
```

### Run Health Check

```bash
# Execute the health check
bash health-check.sh
```

## Automated Fixes

### Permission Autofix

```bash
# Automatically fix script permissions
echo "Fixing script permissions..."
find scripts/ -name "*.sh" -type f -exec chmod +x {} \;
echo "All scripts are now executable"
```

### Dependency Auto-Installation

```bash
# Auto-install missing tools (Ubuntu/Debian)
install_if_missing() {
    local tool=$1
    local package=$2

    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Installing $tool..."
        apt-get update && apt-get install -y "$package"
        echo "$tool installed"
    else
        echo "$tool already installed"
    fi
}

# Install required tools
install_if_missing shellcheck shellcheck
install_if_missing shfmt shfmt

# Install act (GitHub Actions simulator)
if ! command -v act >/dev/null 2>&1; then
    echo "Installing act..."
    wget -O /tmp/act.tar.gz https://github.com/nektos/act/releases/download/v0.2.55/act_Linux_x86_64.tar.gz
    tar -xzf /tmp/act.tar.gz -C /tmp
    mv /tmp/act /usr/local/bin/act
    chmod +x /usr/local/bin/act
    echo "act installed"
else
    echo "act already installed"
fi
```

### Code Formatting Autofix

```bash
# Auto-format shell scripts
if command -v shfmt >/dev/null 2>&1; then
    echo "Auto-formatting shell scripts..."
    find scripts/ -name "*.sh" -exec shfmt -w {} \;
    echo "Scripts formatted"
else
    echo "shfmt not available for auto-formatting"
fi
```

## Self-Healing Workflow

### Automated Maintenance Script

```bash
#!/bin/bash
# Self-healing maintenance script
# Designed to run as a scheduled GitHub Action

set -euo pipefail

echo "Starting self-healing maintenance..."

# Step 1: Run health check
echo "Step 1: Health check..."
if ! bash health-check.sh; then
    echo "Health check failed, attempting fixes..."
else
    echo "Health check passed"
fi

# Step 2: Apply automatic fixes
echo "Step 2: Applying automatic fixes..."
bash autofix-permissions.sh
bash autoinstall-deps.sh
bash autoformat-code.sh

# Step 3: Re-run health check
echo "Step 3: Re-running health check..."
if bash health-check.sh; then
    echo "Self-healing successful!"
else
    echo "Some issues remain - manual intervention required"
    exit 1
fi

# Step 4: Run tests
echo "Step 4: Running tests..."
if command -v act >/dev/null 2>&1; then
    act -j test-action --container-architecture linux/amd64 || echo "Some tests failed"
else
    echo "act not available for testing"
fi

echo "Self-healing maintenance completed"
```

## Monitoring & Alerts

### Health Status Dashboard

```bash
# Generate health status report
generate_health_report() {
    echo "# Health Status Report"
    echo "Generated: $(date)"
    echo

    echo "## Repository Health"
    if bash health-check.sh >/dev/null 2>&1; then
        echo "Repository is healthy"
    else
        echo "Repository has issues requiring attention"
    fi
    echo

    echo "## Tool Availability"
    tools=("bash" "git" "shellcheck" "shfmt" "act")
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "$tool: Available"
        else
            echo "$tool: Missing"
        fi
    done
    echo

    echo "## Recent Activity"
    echo "Last commit: $(git log --oneline -1)"
    echo "Branch: $(git branch --show-current)"
    echo "Uncommitted changes: $(git status --porcelain | wc -l)"
}

# Generate and display report
generate_health_report
```

### Alert System

```bash
# Send alerts for critical issues
send_alert() {
    local message=$1
    local severity=${2:-warning}

    echo "$severity: $message"

    # In a real implementation, this could:
    # - Send Slack notifications
    # - Create GitHub issues
    # - Send email alerts
    # - Trigger PagerDuty incidents
}

# Check for critical issues
check_critical_issues() {
    # Check if main script is broken
    if ! bash -n scripts/services/main.sh 2>/dev/null; then
        send_alert "Main script has syntax errors" "critical"
    fi

    # Check if action.yml is valid
    if ! python3 -c "import yaml; yaml.safe_load(open('action.yml'))" 2>/dev/null; then
        send_alert "action.yml has YAML syntax errors" "critical"
    fi

    # Check repository size
    repo_size=$(du -s . | cut -f1)
    if [[ $repo_size -gt 500000 ]]; then  # 500MB
        send_alert "Repository size is very large: $(du -sh . | cut -f1)" "warning"
    fi
}

# Run critical checks
check_critical_issues
```

## Recovery Procedures

### Emergency Recovery Script

```bash
#!/bin/bash
# Emergency recovery script for critical failures

set -euo pipefail

echo "Starting emergency recovery..."

# Step 1: Create backup
backup_dir="/tmp/emergency-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"
cp -r . "$backup_dir/"
echo "Backup created in $backup_dir"

# Step 2: Reset to last known good state
echo "Resetting to last known good commit..."
git reset --hard HEAD~1 2>/dev/null || git reset --hard origin/main
echo "Repository reset"

# Step 3: Reapply fixes
echo "Reapplying fixes..."
chmod +x scripts/*.sh
# Add other recovery steps here

# Step 4: Validate recovery
if bash health-check.sh; then
    echo "Recovery successful"
else
    echo "Recovery incomplete - manual intervention required"
    exit 1
fi
```

### Rollback Procedures

```bash
# Quick rollback to previous version
rollback_to_previous() {
    echo "Rolling back to previous commit..."
    git reset --hard HEAD~1
    git push --force-with-lease origin main
    echo "Rollback completed"
}

# Rollback with safety checks
safe_rollback() {
    echo "Performing safe rollback..."

    # Check if rollback is safe
    if git status --porcelain | grep -q .; then
        echo "Uncommitted changes present - commit or stash first"
        exit 1
    fi

    # Create backup branch
    backup_branch="backup-before-rollback-$(date +%Y%m%d_%H%M%S)"
    git checkout -b "$backup_branch"
    git checkout main

    # Perform rollback
    rollback_to_previous
}

# Uncomment to perform rollback
# safe_rollback
```

## Continuous Improvement

### Learning from Failures

```bash
# Analyze past failures to improve self-healing
analyze_failures() {
    echo "Analyzing recent failures..."

    # Check recent workflow runs (would need GitHub API)
    echo "Recent workflow failures:"
    # Implementation would query GitHub API for failed runs

    # Common failure patterns
    echo "Common failure patterns:"
    echo "- Permission issues: Scripts not executable"
    echo "- Dependency issues: Missing required tools"
    echo "- Syntax errors: Invalid YAML or shell scripts"
    echo "- Test failures: Logic errors in action code"

    # Generate improvement suggestions
    echo "Improvement suggestions:"
    echo "1. Add more comprehensive health checks"
    echo "2. Implement automatic dependency management"
    echo "3. Add more granular error reporting"
    echo "4. Create better rollback mechanisms"
}

analyze_failures
```

Self-healing is about **prevention through automation**. By catching issues early and fixing them automatically, we maintain a healthy, reliable codebase that developers can trust.
