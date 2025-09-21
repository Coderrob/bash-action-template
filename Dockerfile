# This Dockerfile provides a complete development environment for working with
# the bash-action-template repository, including all necessary tools for
# development, testing, and documentation.

FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install system dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        curl \
        wget \
        git \
        make \
        jq \
        ca-certificates \
        gnupg \
        lsb-release \
        build-essential \
        shellcheck \
        python3 \
        python3-pip \
        python3-venv \
        nodejs \
        npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Go (required for shfmt)
RUN wget -O /tmp/go.tar.gz https://go.dev/dl/go1.21.5.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Install shfmt (shell formatter) - using go install for latest version
RUN go install mvdan.cc/sh/v3/cmd/shfmt@latest \
    && mv /root/go/bin/shfmt /usr/local/bin/shfmt

# Install Prettier
RUN npm install -g prettier@3.1.0

# Install act (GitHub Actions runner)
RUN wget -O /tmp/act.tar.gz https://github.com/nektos/act/releases/download/v0.2.55/act_Linux_x86_64.tar.gz \
    && tar -xzf /tmp/act.tar.gz -C /tmp \
    && mv /tmp/act /usr/local/bin/act \
    && chmod +x /usr/local/bin/act \
    && rm -rf /tmp/act*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install additional Python tools for security checks and documentation
RUN python3 -m pip install --break-system-packages \
        pre-commit \
        yamllint \
        bandit \
        safety \
        mkdocs \
        mkdocs-material \
        mkdocs-git-revision-date-plugin \
        mkdocs-git-committers-plugin-2 \
        mkdocs-minify-plugin

# Install MkDocs plugins
RUN python3 -m pip install --break-system-packages \
        pymdown-extensions \
        mkdocs-mermaid2-plugin

# Create workspace directory
RUN mkdir -p /workspaces/bash-action-template
WORKDIR /workspaces/bash-action-template

# Set environment variables
ENV SHELL=/bin/bash
ENV PATH="/usr/local/bin:${PATH}"

# Create non-root user for development
RUN useradd -m -s /bin/bash developer \
    && chown -R developer:developer /workspaces

USER developer

# Verify installations
RUN echo "Verifying installations:" \
    && shellcheck --version \
    && shfmt --version \
    && prettier --version \
    && act --version \
    && gh --version \
    && python3 --version \
    && pip --version \
    && mkdocs --version \
    && echo "All tools installed successfully"

# Default command
CMD ["/bin/bash"]
