# Bash Action Template

A production-ready GitHub Action template built with robust shell scripting patterns, functional-style utilities, and enterprise-grade observability. This repository is designed to help teams create maintainable, testable, and secure shell-based GitHub Actions with minimal boilerplate.

## What this project provides

- A minimal, consistent scaffolding for GitHub Actions implemented in Bash.
- Centralized initialization and shared libraries to eliminate repeated setup code.
- A lightweight testing framework and CI-friendly checks.
- Examples and templates for rapid onboarding and customization.

## Quick start

1. Clone the repository:

```bash
git clone https://github.com/your-username/bash-action-template.git
cd bash-action-template
```

1. Make scripts executable and run the main script locally:

```bash
chmod +x scripts/**/*.sh tests/*.sh
./scripts/services/main.sh
```

1. Run the test suite:

```bash
./tests/test_runner.sh
```

## High-level architecture

The repository is organized to separate concerns clearly:

- `scripts/` — all shell scripts, grouped by purpose (libraries, services, validation, maintenance).
- `templates/` — reusable file and workflow templates.
- `tests/` — executable tests and a test runner used by CI.
- `docs/` — supplementary documentation and examples.

Core principles used in the implementation:

- Single responsibility per file.
- Centralized initialization to avoid duplication.
- Pure, testable utility functions where practical.
- Strict input validation and secure defaults.

## Scripts and usage

Primary areas you will likely interact with:

- `scripts/lib/` — shared libraries such as `core.sh`, `utils.sh`, and `script_init.sh`.
- `scripts/services/main.sh` — the action's primary entrypoint; extend or replace this for your own logic.
- `scripts/validation/` — quality checks (PR title validation, output verification, etc.).
- `scripts/maintenance/` — developer conveniences (license headers, snippet updates, template generator).

When writing or adding scripts:

- Source libraries from `../lib/` using `$(dirname "${BASH_SOURCE[0]}")/../lib/...`.
- Use `init_script` from `script_init.sh` to standardize logging and teardown.
- Keep functions small and side-effect free when possible.

## Testing and CI

This template includes a test harness in `tests/test_runner.sh`. CI workflows run the test suite and linting (ShellCheck, shfmt) on every push.

Local checks:

```bash
# Static analysis
find . -name "*.sh" -type f | xargs shellcheck

# Formatting checks
find . -name "*.sh" -type f | xargs shfmt -l -d

# Run tests
./tests/test_runner.sh
```

## Development workflow

- Branch from `main` for any feature or fix.
- Keep changes small and focused; add or update tests as appropriate.
- Use the provided templates in `templates/` when creating new scripts or workflows.

## Contributing

Contributions are welcome. Please open issues to discuss larger changes before sending a pull request. See `CONTRIBUTING.md` for guidelines and the code of conduct.

## License

This project is distributed under the GNU General Public License v3.0. See the `LICENSE` file for details.
