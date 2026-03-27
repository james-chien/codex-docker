FROM ghcr.io/openai/codex-universal:latest

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV CODEX_CONTAINER=1
ENV CODEX_WORKSPACE=/workspace

WORKDIR /workspace

# Install Bubblewrap, GitHub CLI, and Codex CLI
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bubblewrap \
        wget \
        ca-certificates \
        gnupg \
    \
    # Add GitHub CLI apt repo
    && mkdir -p /etc/apt/keyrings \
    && wget -nv -O /tmp/githubcli.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && install -m 0644 /tmp/githubcli.gpg /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && rm /tmp/githubcli.gpg \
    \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    \
    # Install gh
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    \
    # Install Codex CLI (requires NVM from base image)
    && source /root/.nvm/nvm.sh \
    && npm install -g @openai/codex \
    \
    # Verify installs
    && bwrap --version \
    && gh --version \
    && codex --version \
    \
    # Cleanup
    && npm cache clean --force \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Shell helpers
COPY --chmod=0644 scripts/codex-shell.sh /etc/profile.d/codex-shell.sh
RUN printf '%s\n' 'source /etc/profile.d/codex-shell.sh' >> /root/.bashrc

# Entrypoint
COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "-l"]
