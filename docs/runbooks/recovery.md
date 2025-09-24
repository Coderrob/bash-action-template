# 🛟 Recovery Runbook

!!! info "RunMe Interactive Runbook"
This runbook provides procedures for recovering from critical failures and data loss scenarios. Use when automated self-healing is insufficient.

## 🚨 Critical Failure Scenarios

### Complete Repository Corruption

#### Symptoms

- Repository becomes inaccessible
- All files are corrupted or missing
- Git history is lost

#### Recovery Steps

```bash
# Step 1: Assess damage
echo "Assessing repository damage..."
ls -la
git status 2>/dev/null || echo "Git repository corrupted"

# Step 2: Create emergency backup (if possible)
if [[ -d ".git" ]]; then
    emergency_backup="/tmp/emergency-backup-$(date +%Y%m%d_%H%M%S)"
    cp -r . "$emergency_backup" 2>/dev/null || echo "Could not create backup"
    echo "Emergency backup created: $emergency_backup"
fi

# Step 3: Restore from clean source
echo "Restoring from clean source..."
git clone https://github.com/Coderrob/bash-action-template.git /tmp/clean-repo
cp -r /tmp/clean-repo/* .
cp -r /tmp/clean-repo/.* . 2>/dev/null || true

echo "✅ Repository restored from clean source"
```

### Action Execution Failures

#### Symptoms

- Actions fail to run in workflows
- Scripts produce errors
- Outputs are incorrect

#### Diagnostic Steps

```bash
# Step 1: Test action locally
echo "Testing action locally..."
export INPUT_EXAMPLE_INPUT="diagnostic-test"
export INPUT_LOG_LEVEL="debug"
export GITHUB_OUTPUT="/tmp/diagnostic-output"

if ./scripts/services/main.sh; then
    echo "✅ Local execution successful"
    cat /tmp/diagnostic-output
else
    echo "❌ Local execution failed"
fi

# Step 2: Check script syntax
echo "Checking script syntax..."
for script in scripts/*.sh; do
    if bash -n "$script"; then
        echo "✅ $script syntax OK"
    else
        echo "❌ $script syntax ERROR"
    fi
done

# Step 3: Validate action.yml
echo "Validating action.yml..."
python3 -c "import yaml; yaml.safe_load(open('action.yml'))" && echo "✅ action.yml valid"

# Step 4: Check permissions
echo "Checking permissions..."
ls -la scripts/
```

### Data Loss Recovery

#### Data Loss Symptoms

- Configuration files are missing
- Custom scripts are lost
- Documentation is corrupted

#### Data Recovery Steps

```bash
# Step 1: Identify missing files
echo "Checking for missing critical files..."
critical_files=("action.yml" "scripts/services/main.sh" "scripts/lib/utils.sh" "README.md")
for file in "${critical_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "❌ Missing: $file"
    else
        echo "✅ Present: $file"
    fi
done

# Step 2: Restore from template defaults
echo "Restoring template defaults..."
git checkout origin/main -- action.yml
git checkout origin/main -- scripts/
git checkout origin/main -- docs/

echo "✅ Template files restored"

# Step 3: Reapply customizations (manual step)
echo "⚠️ Manual step required: Reapply your customizations"
echo "Compare with backup or recreate changes"
```

## 🔄 Rollback Procedures

### Git-Based Rollback

```bash
# Safe rollback to previous commit
safe_rollback() {
    local commits_back=${1:-1}

    echo "Rolling back $commits_back commit(s)..."

    # Check for uncommitted changes
    if git status --porcelain | grep -q .; then
        echo "❌ Uncommitted changes detected. Commit or stash them first."
        git status
        exit 1
    fi

    # Create backup branch
    backup_branch="backup-$(date +%Y%m%d_%H%M%S)"
    git checkout -b "$backup_branch"
    echo "✅ Backup created on branch: $backup_branch"

    # Perform rollback
    git checkout main
    git reset --hard HEAD~"$commits_back"
    git push --force-with-lease origin main

    echo "✅ Rollback completed"
}

# Usage examples:
# safe_rollback 1    # Rollback 1 commit
# safe_rollback 3    # Rollback 3 commits
```

### Emergency Rollback

```bash
# Emergency rollback when git is corrupted
emergency_rollback() {
    echo "🚨 Performing emergency rollback..."

    # Download clean version
    temp_dir="/tmp/emergency-restore-$(date +%Y%m%d_%H%M%S)"
    git clone https://github.com/Coderrob/bash-action-template.git "$temp_dir"

    # Backup current state
    backup_dir="/tmp/pre-rollback-backup-$(date +%Y%m%d_%H%M%S)"
    cp -r . "$backup_dir" 2>/dev/null || true
    echo "Backup created: $backup_dir"

    # Restore clean version
    cp -r "$temp_dir"/* .
    cp -r "$temp_dir"/.* . 2>/dev/null || true

    echo "✅ Emergency rollback completed"
    echo "Original state backed up to: $backup_dir"
}

# Uncomment to perform emergency rollback
# emergency_rollback
```

## 🛠️ Advanced Recovery Techniques

### Partial File Recovery

```bash
# Recover specific files from git history
recover_file() {
    local file_path=$1
    local commit_ref=${2:-HEAD~1}

    echo "Recovering $file_path from $commit_ref..."

    if git show "$commit_ref:$file_path" > "$file_path"; then
        echo "✅ $file_path recovered"
    else
        echo "❌ Failed to recover $file_path"
    fi
}

# Usage examples:
# recover_file "scripts/services/main.sh"
# recover_file "action.yml" "HEAD~5"
# recover_file "README.md" "abc123"  # specific commit
```

### Configuration Reconstruction

```bash
# Reconstruct action.yml from scratch
reconstruct_action_yml() {
    cat > action.yml << 'EOF'
name: 'Bash Action Template'
description: 'A comprehensive template for creating GitHub Actions using bash scripts'
author: 'Your Name'

inputs:
  example-input:
    description: 'An example input parameter'
    required: false
    default: 'default-value'

outputs:
  example-output:
    description: 'An example output value'
    value: ${{ steps.main.outputs.example-output }}

runs:
  using: 'composite'
  steps:
    - name: Run action
      run: $GITHUB_ACTION_PATH/scripts/services/main.sh
      shell: bash
      id: main
EOF

    echo "✅ action.yml reconstructed"
}

# Reconstruct basic scripts
reconstruct_scripts() {
    # Create basic main.sh
    cat > scripts/services/main.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Source utilities
source "$(dirname "$0")/utils.sh"

main() {
    log_info "action" "Action started"
    set_output "example-output" "success"
    log_info "action" "Action completed"
}

main "$@"
EOF

    chmod +x scripts/services/main.sh
    echo "✅ Basic scripts reconstructed"
}

# Uncomment to reconstruct:
# reconstruct_action_yml
# reconstruct_scripts
```

## 📊 Post-Recovery Validation

### Comprehensive Validation

```bash
# Run full validation suite
validate_recovery() {
    echo "Running post-recovery validation..."

    local issues=0

    # Check file structure
    if [[ ! -f "action.yml" ]]; then
        echo "❌ action.yml missing"; ((issues++))
    fi

    if [[ ! -x "scripts/services/main.sh" ]]; then
        echo "❌ main.sh not executable"; ((issues++))
    fi

    # Validate YAML
    if ! python3 -c "import yaml; yaml.safe_load(open('action.yml'))" 2>/dev/null; then
        echo "❌ action.yml invalid YAML"; ((issues++))
    fi

    # Test execution
    if ! export INPUT_EXAMPLE_INPUT="test" GITHUB_OUTPUT="/tmp/test-output" && ./scripts/services/main.sh >/dev/null 2>&1; then
        echo "❌ Action execution failed"; ((issues++))
    fi

    # Summary
    if [[ $issues -eq 0 ]]; then
        echo "✅ Recovery validation passed"
        return 0
    else
        echo "❌ Recovery validation failed: $issues issues found"
        return 1
    fi
}

validate_recovery
```

### Performance Validation

```bash
# Test performance after recovery
performance_test() {
    echo "Running performance validation..."

    local start_time end_time duration

    start_time=$(date +%s%N)
    for i in {1..10}; do
        export INPUT_EXAMPLE_INPUT="perf-test-$i"
        export GITHUB_OUTPUT="/tmp/perf-output-$i"
        ./scripts/services/main.sh >/dev/null 2>&1
    done
    end_time=$(date +%s%N)

    duration=$(( (end_time - start_time) / 1000000 ))  # milliseconds
    avg_duration=$(( duration / 10 ))

    echo "Average execution time: ${avg_duration}ms"

    if [[ $avg_duration -gt 5000 ]]; then  # 5 seconds
        echo "⚠️ Performance degraded"
    else
        echo "✅ Performance acceptable"
    fi
}

performance_test
```

## 📋 Recovery Checklist

### Immediate Actions

- [ ] Assess damage extent
- [ ] Create backups of current state
- [ ] Isolate affected systems
- [ ] Notify stakeholders

### Recovery Execution

- [ ] Choose appropriate recovery method
- [ ] Execute recovery procedure
- [ ] Validate recovery success
- [ ] Test functionality
- [ ] Monitor for issues

### Post-Recovery

- [ ] Document incident and resolution
- [ ] Review prevention measures
- [ ] Update recovery procedures
- [ ] Test backup systems

## 🚨 When to Escalate

### Critical Indicators

- **Data loss** affecting multiple users
- **Security breaches** or unauthorized access
- **Complete system failure** preventing operations
- **Legal or compliance** issues

### Escalation Steps

1. **Stop all operations** immediately
2. **Secure the environment** - prevent further damage
3. **Contact incident response team**
4. **Follow organizational escalation procedures**
5. **Document everything** for post-mortem analysis

### External Resources

- **GitHub Support**: For platform-related issues
- **Security Team**: For security incidents
- **Legal Team**: For compliance issues
- **Infrastructure Team**: For system-level failures

---

**Remember**: Recovery is about **restoring service** and **learning from failure**. Every incident is an opportunity to improve our resilience and processes.
