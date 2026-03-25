FROM ghcr.io/openai/codex-universal:latest

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /workspace

# Ensure NVM is available during build, then install Codex CLI globally.
RUN source /root/.nvm/nvm.sh \
    && npm install -g @openai/codex \
    && npm cache clean --force

# Shell helpers / shortcuts for interactive sessions.
COPY scripts/codex-shell.sh /etc/profile.d/codex-shell.sh
RUN chmod 0644 /etc/profile.d/codex-shell.sh \
    && echo 'source /etc/profile.d/codex-shell.sh' >> /root/.bashrc

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "-l"]
