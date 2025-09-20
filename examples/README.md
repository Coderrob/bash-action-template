# Example Usage

This directory contains examples of how to use the bash action template.

## Basic Workflow Example

```yaml
name: Example Workflow

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  example:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Bash Action
        uses: ./  # Use this if the action is in the same repo
        # uses: your-username/your-action-repo@v1  # Use this for external actions
        id: bash-action
        with:
          example-input: "Hello, World!"
          log-level: "info"
          working-directory: "."

      - name: Use outputs
        run: |
          echo "Action output: ${{ steps.bash-action.outputs.example-output }}"
          echo "Execution time: ${{ steps.bash-action.outputs.execution-time }} seconds"
```

## Advanced Workflow Example

```yaml
name: Advanced Example

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options:
        - staging
        - production
      debug:
        description: 'Enable debug logging'
        required: false
        default: false
        type: boolean

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run deployment script
        uses: ./
        id: deploy
        with:
          example-input: ${{ github.event.inputs.environment }}
          log-level: ${{ github.event.inputs.debug && 'debug' || 'info' }}
          working-directory: "./deploy"

      - name: Report results
        run: |
          echo "Deployment to ${{ github.event.inputs.environment }} completed"
          echo "Result: ${{ steps.deploy.outputs.example-output }}"
          echo "Time taken: ${{ steps.deploy.outputs.execution-time }} seconds"

      - name: Notify on failure
        if: failure()
        run: |
          echo "Deployment failed!"
          exit 1
```

## Matrix Strategy Example

```yaml
name: Matrix Example

on:
  push:
    branches: [ main ]

jobs:
  test-matrix:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, ubuntu-20.04]
        environment: [dev, staging, prod]
        include:
          - os: ubuntu-latest
            environment: dev
            log-level: debug
          - os: ubuntu-20.04
            environment: staging
            log-level: info
          - os: ubuntu-latest
            environment: prod
            log-level: warn
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run action with matrix
        uses: ./
        with:
          example-input: ${{ matrix.environment }}
          log-level: ${{ matrix.log-level || 'info' }}
          working-directory: "."
```

## Conditional Execution Example

```yaml
name: Conditional Example

on:
  push:
    branches: [ main ]
    paths:
      - 'src/**'
      - 'scripts/**'

jobs:
  conditional:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Check if action should run
        id: should-run
        run: |
          if [[ "${{ github.event_name }}" == "push" ]] && [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "run=true" >> $GITHUB_OUTPUT
          else
            echo "run=false" >> $GITHUB_OUTPUT
          fi

      - name: Run action conditionally
        if: steps.should-run.outputs.run == 'true'
        uses: ./
        with:
          example-input: "Conditional execution"
          log-level: "info"

      - name: Skip notification
        if: steps.should-run.outputs.run == 'false'
        run: echo "Action was skipped due to conditions"
```

## Error Handling Example

```yaml
name: Error Handling Example

on:
  workflow_dispatch:

jobs:
  error-handling:
    runs-on: ubuntu-latest
    continue-on-error: true
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run action with error handling
        id: action-run
        uses: ./
        with:
          example-input: "test-input"
          log-level: "debug"
        continue-on-error: true

      - name: Check action result
        run: |
          if [[ "${{ steps.action-run.outcome }}" == "success" ]]; then
            echo "Action completed successfully"
            echo "Output: ${{ steps.action-run.outputs.example-output }}"
          else
            echo "Action failed, but workflow continues"
            echo "Conclusion: ${{ steps.action-run.conclusion }}"
          fi

      - name: Cleanup on failure
        if: steps.action-run.outcome == 'failure'
        run: |
          echo "Performing cleanup after action failure"
          # Add cleanup logic here
```

## Using Secrets Example

```yaml
name: Secrets Example

on:
  workflow_dispatch:

jobs:
  with-secrets:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run action with secrets
        uses: ./
        with:
          example-input: ${{ secrets.SECRET_INPUT }}
          log-level: "info"
        env:
          # Pass secrets as environment variables
          SECRET_TOKEN: ${{ secrets.SECRET_TOKEN }}
          API_KEY: ${{ secrets.API_KEY }}

      - name: Use outputs safely
        run: |
          # Never log secret values directly
          echo "Action completed with output length: ${#OUTPUT}"
        env:
          OUTPUT: ${{ steps.action-run.outputs.example-output }}
```