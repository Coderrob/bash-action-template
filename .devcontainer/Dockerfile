# Use Ubuntu as base image
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install shfmt (shell formatter)
RUN wget -O /tmp/shfmt.tar.gz https://github.com/mvdan/sh/releases/download/v3.7.0/shfmt_v3.7.0_linux_amd64.tar.gz \
    && tar -xzf /tmp/shfmt.tar.gz -C /tmp \
    && mv /tmp/shfmt_v3.7.0_linux_amd64/shfmt /usr/local/bin/shfmt \
    && chmod +x /usr/local/bin/shfmt \
    && rm -rf /tmp/shfmt*

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

# Install additional Python tools for security checks
RUN python3 -m pip install --upgrade pip \
    && python3 -m pip install \
        pre-commit \
        yamllint \
        bandit \
        safety

# Create workspace directory
RUN mkdir -p /workspaces/bash-action-template
WORKDIR /workspaces/bash-action-template

# Set environment variables
ENV SHELL=/bin/bash
ENV PATH="/usr/local/bin:${PATH}"

# Verify installations
RUN echo "Verifying installations:" \
    && shellcheck --version \
    && shfmt --version \
    && prettier --version \
    && act --version \
    && gh --version \
    && python3 --version \
    && pip --version \
    && echo "All tools installed successfully"
