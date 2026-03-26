#!/usr/bin/env bash

# Load NVM for interactive shells if available.
if [[ -s /root/.nvm/nvm.sh ]]; then
  # shellcheck disable=SC1091
  source /root/.nvm/nvm.sh
fi

# -----------------------------------------------------------------------------
# Core aliases
# -----------------------------------------------------------------------------

alias cdx='codex --dangerously-bypass-approvals-and-sandbox'
alias cw='cd /workspace'

# -----------------------------------------------------------------------------
# Authentication helpers
# -----------------------------------------------------------------------------

cdxs() {
  codex login status
}

cdxl() {
  if codex login status >/dev/null 2>&1; then
    echo "✔ Codex authenticated"
  else
    echo "→ Starting Codex device code authentication"
    codex login --device-auth
  fi
}

cdxlo() {
  codex logout
}

# -----------------------------------------------------------------------------
# Session helpers
# -----------------------------------------------------------------------------

cdxr() {
  codex resume --dangerously-bypass-approvals-and-sandbox "$@"
}

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

cdxh() {
  cat <<'EOF'

Codex Shell Shortcuts
────────────────────────────────

Command   Description
────────  ─────────────────────────────────
cdx       Run Codex (full access)
cdxr      Resume Codex session
cdxs      Show authentication status
cdxl      Login if needed
cdxlo     Logout
cw        Go to /workspace
cdxh      Show this help

EOF
}
