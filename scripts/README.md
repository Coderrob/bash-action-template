# Scripts — Overview

This folder contains the shell scripts used by the Bash Action Template. The scripts are organized into focused areas so it's easy to find shared libraries, primary action logic, validation checks, and developer maintenance tools.

## Layout

```
scripts/
├── lib/           # core libraries and shared utilities
├── services/      # main service scripts (primary functionality)
├── validation/    # validation and quality assurance scripts
└── maintenance/   # developer and maintenance tools
```

## What lives where

- `lib/`
  - Shared libraries and helpers used across scripts (for example: `core.sh`, `utils.sh`, `script_init.sh`).

- `services/`
  - Primary entry points and orchestration scripts. `main.sh` is the canonical example and can be replaced or extended for your action's business logic.

- `validation/`
  - Scripts that perform checks and quality gates, such as PR title validation, action output verification, and change detection.

- `maintenance/`
  - Utility scripts used by maintainers: license header application, snippet updates, template generation, and summary/report generation.

## Conventions and usage

- All scripts use Bash strict mode (`set -euo pipefail`) and require Bash 4.4+.
- Libraries in `lib/` are intended to be sourced by scripts in the other directories. Use relative sourcing to keep paths portable:

  ```bash
  # Example from a script inside services/ or validation/
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/core.sh"
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
  ```

- Use `init_script()` from `script_init.sh` in new scripts to ensure consistent logging, summary collection, and cleanup handling.

## Adding a new script

1. Place the script in the directory that best matches its purpose (lib/services/validation/maintenance).
2. Source required libraries from `../lib/`.
3. Call `init_script "<name>" "<log-level>" "<include-summary>"` early in your script.
4. Keep functions small, prefer pure functions for logic, and add tests in `tests/`.

## Examples

- Create a new service script:

  ```bash
  #!/bin/bash
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/script_init.sh"
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/core.sh"
  init_script "my-service" "info" "true"

  main() {
    log_info "startup" "My service started"
    # business logic
  }

  main "$@"
  ```

- Write a validation script that uses shared utilities:

  ```bash
  #!/bin/bash
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/common_args.sh"
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/script_init.sh"

  init_script "validate-pr" "info" "false"
  # validation logic
  ```

## Notes for maintainers

- Run `shellcheck` and `shfmt` before committing changes.
- Extend tests in `tests/` when introducing new functionality.
- Keep `lib/` focused on pure helpers and side-effect-free utilities where possible.

If you'd like, I can also add a brief checklist template for pull requests that modify scripts (recommended for contributors).
