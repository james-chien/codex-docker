#!/usr/bin/env bash

[[ -n "${CODEX_SHELL_LOADED:-}" ]] && return
export CODEX_SHELL_LOADED=1

CODEX_WORKSPACE="${CODEX_WORKSPACE:-/workspace}"

# Load NVM for interactive shells if available.
if [[ -s /root/.nvm/nvm.sh ]]; then
  # shellcheck disable=SC1091
  source /root/.nvm/nvm.sh
fi

alias cdx='codex --dangerously-bypass-approvals-and-sandbox'
alias cw="cd ${CODEX_WORKSPACE}"

cdxs() {
  codex login status
}

cdxl() {
  if codex login status >/dev/null 2>&1; then
    printf '%s\n' "✔ Codex authenticated"
  else
    printf '%s\n' "→ Starting Codex device authentication..."
    codex login --device-auth
  fi
}

cdxlo() {
  codex logout
}

cdxr() {
  codex resume --dangerously-bypass-approvals-and-sandbox "$@"
}

cdx_in_container() {
  [[ "${CODEX_CONTAINER:-}" == "1" || -f "/.dockerenv" ]]
}

cdx_help_table() {
  cat <<EOF
  Command   Description
  ───────   ──────────────────────────────────
  cdx       Run Codex (full access)
  cdxr      Resume Codex session
  cdxs      Show authentication status
  cdxl      Login if needed
  cdxlo     Logout
  cw        Go to ${CODEX_WORKSPACE}
  cdxh      Show this help
EOF
}

cdxh() {
  cat <<'EOF'

╭──────────────────────────────────────────────╮
│                  Codex Shell                 │
╰──────────────────────────────────────────────╯

EOF

  cdx_help_table
  printf '\n'
}

cdx_welcome() {
  [[ $- != *i* ]] && return
  [[ -n "${CODEX_WELCOME_SHOWN:-}" ]] && return
  export CODEX_WELCOME_SHOWN=1

  local auth_status="not authenticated"
  local runtime="host"

  if codex login status >/dev/null 2>&1; then
    auth_status="authenticated"
  fi

  if cdx_in_container; then
    runtime="docker"
  fi

  cat <<EOF

╭──────────────────────────────────────────────╮
│                  Codex Shell                 │
╰──────────────────────────────────────────────╯
  Runtime    ${runtime}
  Workspace  ${CODEX_WORKSPACE}
  Auth       ${auth_status}

EOF

  cdx_help_table
  printf '\n'
}

cdx_welcome
