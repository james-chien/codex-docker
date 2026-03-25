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
alias cdxn='codex'
alias cw='cd /workspace'

# -----------------------------------------------------------------------------
# Authentication helpers
# -----------------------------------------------------------------------------

cdxs() {
  codex login status
}

cdxl() {
  if codex login status >/dev/null 2>&1; then
    echo "Codex is already authenticated."
  else
    echo "Starting Codex device authentication..."
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
  codex resume "$@"
}

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

cdxh() {
  cat <<EOF

Codex shell shortcuts

Core
  cdx        run codex (bypass approvals)
  cdxn       run codex normally
  cdxr       resume a Codex session

Auth
  cdxs       show authentication status
  cdxl       login if needed
  cdxlo      logout

Workspace
  cw         cd /workspace

Help
  cdxh       show this help

EOF
}
