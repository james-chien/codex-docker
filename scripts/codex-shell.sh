#!/usr/bin/env bash

[[ -n "${CODEX_SHELL_LOADED:-}" ]] && return
export CODEX_SHELL_LOADED=1

export CODEX_WORKSPACE="${CODEX_WORKSPACE:-/workspace}"

alias cdx='codex --dangerously-bypass-approvals-and-sandbox'
alias cdxr='codex resume --dangerously-bypass-approvals-and-sandbox'
alias cw='cd "$CODEX_WORKSPACE"'

cdx_in_container() {
  [[ "${CODEX_CONTAINER:-}" == "1" || -f "/.dockerenv" ]]
}

cdx_version() {
  if command -v codex >/dev/null 2>&1; then
    codex --version 2>/dev/null || printf '%s\n' "installed"
  else
    printf '%s\n' "not found"
  fi
}

cdx_auth_status() {
  if ! command -v codex >/dev/null 2>&1; then
    printf '%s\n' "codex not found"
    return
  fi

  if codex login status >/dev/null 2>&1; then
    printf '%s\n' "authenticated"
  else
    printf '%s\n' "not authenticated"
  fi
}

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

cdx_doctor() {
  cat <<EOF

Codex
  Version     $(cdx_version)
  Auth        $(cdx_auth_status)
  Config      /root/.codex
  Workspace   ${CODEX_WORKSPACE}
  Runtime     $(cdx_in_container && echo docker || echo host)

Languages
  Bundler     $(bundle --version 2>/dev/null || echo "not found")
  Cargo       $(cargo --version 2>/dev/null || echo "not found")
  Composer    $(composer --version 2>/dev/null || echo "not found")
  Go          $(go version 2>/dev/null || echo "not found")
  Java        $(java --version 2>/dev/null | head -n 1 || echo "not found")
  Node        $(node --version 2>/dev/null || echo "not found")
  npm         $(npm --version 2>/dev/null || echo "not found")
  PHP         $(php --version 2>/dev/null | head -n 1 || echo "not found")
  Pip         $(pip --version 2>/dev/null || echo "not found")
  Python      $(python --version 2>/dev/null || echo "not found")
  Ruby        $(ruby --version 2>/dev/null || echo "not found")
  Rust        $(rustc --version 2>/dev/null || echo "not found")
  Swift       $(swift --version 2>/dev/null | head -n 1 || echo "not found")
  Yarn        $(yarn --version 2>/dev/null || echo "not found")

EOF
}

cdx_help_table() {
  cat <<EOF
  Command      Description
  ───────      ─────────────────────────────────────────
  cdx          Run Codex with full workspace access
  cdxr         Resume a Codex session with full access
  cdxs         Show Codex authentication status
  cdxl         Login with device authentication if needed
  cdxlo        Logout from Codex
  cdxv         Show Codex version
  cdxdoctor    Show Codex + language environment info
  cw           Go to ${CODEX_WORKSPACE}
  cdxh         Show this help
EOF
}

cdxv() {
  cdx_version
}

cdxdoctor() {
  cdx_doctor
}

cdxh() {
  cat <<EOF

╭──────────────────────────────────────────────╮
│                  Codex Shell                 │
╰──────────────────────────────────────────────╯

  Codex      $(cdx_version)
  Workspace  ${CODEX_WORKSPACE}
  Config     /root/.codex

EOF

  cdx_help_table
  printf '\n'
}

cdx_welcome() {
  [[ $- != *i* ]] && return
  [[ -n "${CODEX_WELCOME_SHOWN:-}" ]] && return
  export CODEX_WELCOME_SHOWN=1

  cat <<EOF

╭──────────────────────────────────────────────╮
│                  Codex Shell                 │
╰──────────────────────────────────────────────╯
  Runtime    $(cdx_in_container && echo docker || echo host)
  Codex      $(cdx_version)
  Workspace  ${CODEX_WORKSPACE}
  Config     /root/.codex
  Auth       $(cdx_auth_status)

EOF

  cdx_help_table
  printf '\n'
}

cdx_welcome
