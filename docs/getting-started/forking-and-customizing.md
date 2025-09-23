# ==============================================================================

#

# Copyright (C) 2025 Robert Lindley

#

# This program is free software: you can redistribute it and/or modify

# it under the terms of the GNU General Public License as published by

# the Free Software Foundation, either version 3 of the License, or

# (at your option) any later version

#

# This program is distributed in the hope that it will be useful

# but WITHOUT ANY WARRANTY; without even the implied warranty of

# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the

# GNU General Public License for more details

#

# You should have received a copy of the GNU General Public License

# along with this program. If not, see <https://www.gnu.org/licenses/>

#

# ==============================================================================

# Forking and Customizing Your Action

!!! info "Ready to make this template your own?"
This guide walks you through forking the repository and customizing it for your specific needs, including publishing your own GitHub Action.

## Why Fork This Template?

Forking this template gives you:

- **Complete control** over your action's behavior and features
- **Custom branding** and documentation
- **Tailored functionality** for your specific use cases
- **Publishing rights** for your own GitHub Marketplace listing
- **Community contributions** back to the original project

## Forking Process

### Step 1: Create Your Fork

1. Visit the [bash-action-template repository](https://github.com/Coderrob/bash-action-template)
2. Click the **"Fork"** button in the top-right corner
3. Select your GitHub account as the destination
4. Wait for GitHub to create your fork

### Step 2: Clone Your Fork

```bash
# Clone your fork (replace 'yourusername' with your GitHub username)
git clone https://github.com/yourusername/bash-action-template.git
cd bash-action-template

# Set up the original repository as upstream for future updates
git remote add upstream https://github.com/Coderrob/bash-action-template.git
git fetch upstream
```

### Step 3: Set Up Development Environment

```bash
# Start the development environment
docker-compose up -d

# Or use DevContainer in VS Code
# Open the project and click "Reopen in Container" when prompted
```

## Customization Guide

### Basic Customization

#### 1. Update Repository Information

Edit the following files to reflect your action:

**`action.yml`**:

```yaml
name: "Your Custom Action Name"
description: "Brief description of what your action does"
author: "Your Name"
```

**`README.md`**:

- Update the title and description
- Replace example usage with your specific use cases
- Update badges and links

#### 2. Customize Scripts

**`scripts/main.sh`**:

- Modify the main logic to implement your action's functionality
- Update input/output handling
- Add your custom validation and processing

**`scripts/utils.sh`**:

- Add utility functions specific to your use case
- Extend existing functions as needed

#### 3. Update Documentation

**`docs/index.md`**:

- Rewrite the homepage to describe your action
- Update the architecture diagram if needed

**`mkdocs.yml`**:

- Change the site name and description
- Update navigation to match your action's features

### Advanced Customization

#### Adding Custom Templates

The template system allows you to create custom output formats:

1. **Create template files** in `scripts/` directory:

   ```bash
   # Example: scripts/custom_report.md
   # Custom report template
   ## {{TITLE}}

   Date: {{GENERATION_TIME}}
   Status: {{STATUS}}

   ### Results
   {{CUSTOM_DATA}}
   ```

2. **Update summary generation** in `scripts/summary.sh`:

   ```bash
   # Add custom template logic
   generate_custom_report() {
       # Your custom report generation logic
   }
   ```

#### Extending Input/Output Schema

**`action.yml`** - Add your custom inputs:

```yaml
inputs:
  custom_input:
    description: "Description of your custom input"
    required: false
    default: "default value"
  another_input:
    description: "Another custom input"
    required: true
```

**`scripts/main.sh`** - Handle the new inputs:

```bash
# Read custom inputs
CUSTOM_INPUT="${INPUT_CUSTOM_INPUT:-default}"
ANOTHER_INPUT="${INPUT_ANOTHER_INPUT}"

# Validate and process
if [[ -z "$ANOTHER_INPUT" ]]; then
    log_error "another_input is required"
    exit 1
fi
```

## Publishing Your Action

### Step 1: Prepare for Release

1. **Update version information**:

   ```bash
   # Update action.yml with new version
   # Tag your release: git tag v1.0.0
   # Push tags: git push origin --tags
   ```

2. **Test thoroughly**:

   ```bash
   # Run all tests
   make test

   # Test with act locally
   act -j test

   # Validate action.yml
   yamllint action.yml
   ```

3. **Update documentation**:
   - Ensure all examples work with your changes
   - Update changelog
   - Review and update README

### Step 2: Create GitHub Release

1. Go to your repository on GitHub
2. Click **"Releases"** → **"Create a new release"**
3. Create a version tag (e.g., `v1.0.0`)
4. Add release notes describing your changes
5. Publish the release

### Step 3: Publish to Marketplace (Optional)

1. **Enable Marketplace** in repository settings
2. **Create marketplace listing**:
   - Go to **Settings** → **Developer settings** → **GitHub Apps**
   - Create a new GitHub App for your action
   - Configure the marketplace listing

3. **Submit for review** (if required for verified badge)

## Staying Updated

### Syncing with Upstream

Regularly sync your fork with the original repository:

```bash
# Fetch upstream changes
git fetch upstream

# Merge changes into your main branch
git merge upstream/main

# Resolve any conflicts and push
git push origin main
```

### Contributing Back

Consider contributing improvements back to the original project:

1. Create a feature branch: `git checkout -b feature/your-improvement`
2. Make your changes and test thoroughly
3. Create a pull request to the upstream repository
4. Engage with maintainers for feedback

## Testing Your Custom Action

### Local Testing

```bash
# Test with act
act -j test

# Test specific workflows
act -j custom-workflow

# Debug with verbose output
act -j test --verbose
```

### Integration Testing

Create test workflows in `.github/workflows/`:

```yaml
# .github/workflows/test-custom-action.yml
name: Test Custom Action
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test Action
        uses: ./ # Uses action from current repository
        with:
          custom_input: "test value"
```

## Branding and Documentation

### Custom Branding

1. **Update colors and themes** in `mkdocs.yml`
2. **Replace logos and icons** in documentation
3. **Customize code examples** to match your style
4. **Update repository topics** and description

### Documentation Structure

Consider organizing your docs:

```text
docs/
├── index.md                 # Homepage
├── getting-started/         # Quick start guides
├── features/               # Feature documentation
├── examples/               # Usage examples
├── api/                    # API reference
├── troubleshooting/        # Common issues
└── contributing/           # How to contribute
```

## Best Practices for Custom Actions

### Code Quality

- **Use ShellCheck** for linting: `shellcheck scripts/*.sh`
- **Format code** with shfmt: `shfmt -w scripts/*.sh`
- **Write tests** for all functionality
- **Document everything** thoroughly

### Security

- **Validate all inputs** thoroughly
- **Use safe shell practices** (`set -euo pipefail`)
- **Avoid command injection** vulnerabilities
- **Keep dependencies updated**

### Performance

- **Minimize external calls** where possible
- **Use efficient shell constructs**
- **Cache results** when appropriate
- **Profile and optimize** bottlenecks

### Maintainability

- **Keep functions small** and focused
- **Use consistent naming** conventions
- **Document complex logic** with comments
- **Version your releases** properly

## Getting Help

### Community Support

- **GitHub Discussions**: Ask questions and share ideas
- **Issues**: Report bugs or request features
- **Pull Requests**: Contribute improvements

### Professional Services

If you need help with customization or have specific requirements:

- **Consulting services** for complex implementations
- **Code review** services for security and performance
- **Training** for your team

---

!!! success "Ready to customize?"
You've got the power to create amazing GitHub Actions. Start small, iterate often, and don't hesitate to ask for help. The automation community is incredibly supportive!

[:fontawesome-solid-arrow-left: Back to Getting Started](index.md){ .md-button }
[:fontawesome-solid-play: Quick Start](quick-start.md){ .md-button .md-button--primary }
