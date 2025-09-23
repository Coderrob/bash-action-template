# Quick Start: Your First Bash Action in 10 Minutes

!!! quote "Let's create something awesome together!"

    Ready to dive in? Perfect! By the end of this guide, you'll have created, tested, and deployed your very first bash-based GitHub Action.

## What You'll Build

We'll create a **Text Processor Action** that:

- Takes text input from users
- Transforms it (uppercase conversion)
- Outputs the processed result
- Includes proper logging and error handling

## Prerequisites

!!! info "What you need" - A GitHub account - VS Code with Dev Containers extension (recommended) - 10 minutes of focused time

## Step 1: Set Up Your Workspace

### Option A: DevContainer (Recommended)

1. **Open in VS Code**: Launch VS Code and open this repository
2. **DevContainer Magic**: When prompted, click "Reopen in Container"
3. **Wait**: The environment sets itself up automatically (this takes 1-2 minutes)

### Option B: Manual Setup

1. **Clone the repository**:

   git clone <https://github.com/your-username/bash-action-template.git>
   cd bash-action-template

2. **Make scripts executable**:

   chmod +x scripts/\*.sh

## Step 2: Understand the Action Structure

Before we modify anything, let's understand what we're working with:

    bash-action-template/
    ├── action.yml          # Action metadata and configuration
    ├── scripts/
    │   ├── main.sh        # Main action logic (this is what we'll modify)
    │   └── utils.sh       # Helper functions
    └── Makefile           # Build and test commands

The `action.yml` defines your action's interface (inputs/outputs), while `scripts/main.sh` contains the actual logic.

## Step 3: Customize Your Action

### Update Action Metadata

First, let's personalize the action metadata in `action.yml`:

    name: 'My Text Processor Action'
    description: 'A custom text processing action built with bash'
    author: 'Your Name'

    inputs:
      text-input:
        description: 'The text to process'
        required: true
        default: 'hello world'

    outputs:
      processed-text:
        description: 'The processed text output'
        value: ${{ steps.main.outputs.processed-text }}

### Modify the Main Script

Now let's update `scripts/main.sh` to implement our text processing logic:

    #!/bin/bash
    set -euo pipefail

    # Source utility functions
    source "$(dirname "$0")/utils.sh"

    main() {
        log_group "Starting Text Processor Action"

        # Get inputs
        local input_text="${INPUT_TEXT_INPUT:-}"
        local log_level="${INPUT_LOG_LEVEL:-info}"

        # Configure logging
        configure_logging "$log_level"

        log_info "action" "Processing text input" "input_length=${#input_text}"

        # Validate input
        if [[ -z "$input_text" ]]; then
            log_error "No text input provided"
            exit 1
        fi

        # Process the text (uppercase conversion)
        local processed_text
        processed_text=$(echo "$input_text" | tr '[:lower:]' '[:upper:]')

        log_info "processing" "Text transformation complete"

        # Set output
        set_output "processed-text" "$processed_text"

        log_success "Text processing completed successfully"
        log_info "result" "Final output: $processed_text"
    }

    main "$@"

## Step 4: Test Your Action Locally

Let's test our action before deploying it:

### Basic Test

    # Set up environment variables
    export INPUT_TEXT_INPUT="hello world"
    export INPUT_LOG_LEVEL="debug"
    export GITHUB_OUTPUT="/tmp/action-output"

    # Run the action
    ./scripts/main.sh

You should see output like:

    [INFO] 2025-09-21T05:25:02Z | INFO | action | Processing text input | input_length=11
    [INFO] 2025-09-21T05:25:02Z | INFO | processing | Text transformation complete
    [INFO] 2025-09-21T05:25:02Z | INFO | result | Final output: HELLO WORLD

### Check the Output

    cat /tmp/action-output

You should see:

    processed-text=HELLO WORLD

## Step 5: Deploy and Use Your Action

### Create a Test Workflow

Create `.github/workflows/test-my-action.yml`:

    name: Test My Action

    on:
      push:
        branches: [ main ]
      pull_request:
        branches: [ main ]
      workflow_dispatch:

    jobs:
      test-action:
        runs-on: ubuntu-latest

        steps:
          - name: Checkout
            uses: actions/checkout@v4

          - name: Test Action
            id: process-text
            uses: ./
            with:
              text-input: "Hello from GitHub Actions!"
              log-level: "info"

          - name: Display Result
            run: |
              echo "Original: Hello from GitHub Actions!"
              echo "Processed: ${{ steps.process-text.outputs.processed-text }}"

### Commit and Push

    git add .
    git commit -m "feat: create custom text processor action"
    git push origin main

## Congratulations

!!! success "You've done it!"
In just 10 minutes, you've created a fully functional GitHub Action!

## What's Next?

Now that you have the basics down, explore:

- **[Forking & Customizing](forking-and-customizing.md)**: Adapt the template to your needs
- **[Runbooks](../runbooks/quick-fixes.md)**: Common solutions and maintenance
- **[Contributing](../contributing.md)**: Help improve the template

---

[:fontawesome-solid-forward: Explore Forking & Customizing](forking-and-customizing.md){ .md-button }
[:fontawesome-solid-question: Need Help?](../runbooks/quick-fixes.md){ .md-button }
