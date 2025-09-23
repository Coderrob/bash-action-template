# Templates

This directory contains various templates for the bash-action-template project. These templates provide consistent formatting and structure for different types of files and documentation.

## Available Templates

### 📄 Documentation Templates

#### `pull_request_template.md`

Standard template for pull requests with:

- Purpose and change description
- Testing checklist
- Type of change indicators
- Comprehensive checklist for reviewers

#### `issue_template.md`

Comprehensive issue template supporting:

- Bug reports with reproduction steps
- Feature requests with use cases
- Environment information
- Clear categorization

### 🔧 Code Templates

#### `script_template.sh`

Standard bash script template featuring:

- GPL-3.0 license header
- Comprehensive argument parsing
- Logging integration with utils.sh
- Help and version commands
- Error handling and validation

#### `workflow_template.yml`

GitHub Actions workflow template with:

- Configurable triggers and jobs
- Standard permissions setup
- Artifact upload capabilities
- Placeholder system for customization

### 📊 Reporting Templates

#### `summary_template.md`

Execution summary template with:

- Status and timing information
- Input/output documentation
- Event, warning, and error logging
- JSON data export
- Professional formatting

## Template Usage

### Placeholder System

Templates use a `{{PLACEHOLDER}}` system for customization:

```bash
# Example placeholders in script_template.sh
{{YEAR}}         - Copyright year
{{AUTHOR}}       - Author name
{{SCRIPT_NAME}}  - Name of the script
{{DESCRIPTION}}  - Brief description
{{VERSION}}      - Version number
{{PURPOSE}}      - Detailed purpose
```

### Using Templates

1. **Copy the template** to your desired location
2. **Replace placeholders** with actual values
3. **Customize content** as needed for your specific use case
4. **Remove unused sections** that don't apply

### Script Template Example

```bash
# Create a new script from template
cp templates/script_template.sh scripts/my_new_script.sh

# Replace placeholders (example using sed)
sed -i 's/{{YEAR}}/2025/g' scripts/my_new_script.sh
sed -i 's/{{AUTHOR}}/John Doe/g' scripts/my_new_script.sh
sed -i 's/{{SCRIPT_NAME}}/My New Script/g' scripts/my_new_script.sh
# ... continue for other placeholders

# Make executable
chmod +x scripts/my_new_script.sh
```

## Template Guidelines

### Creating New Templates

When creating new templates:

1. **Use clear placeholders** with descriptive names
2. **Include comprehensive documentation** within the template
3. **Follow project style guidelines**
4. **Test the template** by creating a real file from it
5. **Document the template** in this README

### Placeholder Naming

- Use `{{ALL_CAPS_WITH_UNDERSCORES}}`
- Be descriptive: `{{AUTHOR_NAME}}` not `{{AUTH}}`
- Group related placeholders: `{{SCRIPT_*}}`, `{{WORKFLOW_*}}`

### Documentation Standards

Each template should include:

- Purpose and use case
- List of all placeholders
- Example usage
- Any special requirements or dependencies

## Contributing

When adding new templates:

1. Place them in the appropriate subdirectory or root of `templates/`
2. Update this README with documentation
3. Test the template thoroughly
4. Consider adding example usage to tests

## Related Files

- `scripts/maintenance/summary.sh` - Uses `summary_template.md`
- `.github/workflows/` - Can use `workflow_template.yml` as reference
- All scripts should follow patterns from `script_template.sh`
