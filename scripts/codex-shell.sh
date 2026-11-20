#!/usr/bin/env bash

# Load once per Bash session
declare -F cdx_welcome >/dev/null && return 0

# Configure Codex environment
export CODEX_WORKSPACE="${CODEX_WORKSPACE:-/workspace}"
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

# Codex shortcuts
alias cdx='codex'
alias cdxr='codex resume'
alias cdxfull='codex --dangerously-bypass-approvals-and-sandbox'
alias cdxrfull='codex resume --dangerously-bypass-approvals-and-sandbox'
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

# Some tools print version information to stderr.
cdx_tool_version() {
  local output
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '%s\n' "not found"
    return
  fi

  if output="$("$@" 2>&1)" && [[ -n "$output" ]]; then
    printf '%s\n' "${output%%$'\n'*}"
  else
    printf '%s\n' "version unavailable"
  fi
}

cdx_doctor() {
  cat <<EOF
Codex
  Version     $(cdx_version)
  Auth        $(cdx_auth_status)
  Config      ${CODEX_HOME}
  Workspace   ${CODEX_WORKSPACE}
  Runtime     $(cdx_in_container && echo docker || echo host)

Languages
  Bundler     $(cdx_tool_version bundle --version)
  Bun         $(cdx_tool_version bun --version)
  Cargo       $(cdx_tool_version cargo --version)
  CMake       $(cdx_tool_version cmake --version)
  Composer    $(cdx_tool_version composer --version)
  GCC         $(cdx_tool_version gcc --version)
  Go          $(cdx_tool_version go version)
  Java        $(cdx_tool_version java --version)
  Make        $(cdx_tool_version make --version)
  Node        $(cdx_tool_version node --version)
  npm         $(cdx_tool_version npm --version)
  PHP         $(cdx_tool_version php --version)
  Pip         $(cdx_tool_version pip --version)
  pnpm        $(cdx_tool_version pnpm --version)
  Python      $(cdx_tool_version python --version)
  Ruby        $(cdx_tool_version ruby --version)
  Rust        $(cdx_tool_version rustc --version)
  Swift       $(cdx_tool_version swift --version)
  TypeScript  $(cdx_tool_version tsc --version)
  uv          $(cdx_tool_version uv --version)
  Yarn        $(cdx_tool_version yarn --version)
EOF
}

cdx_help_table() {
  cat <<EOF
  Command      Description
  ───────      ─────────────────────────────────────────
  cdx          Run Codex with normal protections
  cdxr         Resume a Codex session
  cdxfull      Run Codex without approvals or sandbox
  cdxrfull     Resume without approvals or sandbox
  cdxs         Show Codex authentication status
  cdxl         Login with device authentication if needed
  cdxlo        Logout from Codex
  cdxv         Show Codex version
  cdxdoctor    Show Codex + language environment info
  cdxcheck     Check the Codex CLI, workspace, and state directory
  cdxupdate    Update Codex to latest or a specified version
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

cdxcheck() {
  local status=0

  if ! command -v codex >/dev/null 2>&1; then
    printf '%s\n' 'Codex CLI is missing from PATH.' >&2
    status=1
  elif ! command codex --version; then
    printf '%s\n' 'Codex CLI version check failed.' >&2
    status=1
  fi

  if [[ ! -d "$CODEX_WORKSPACE" || ! -w "$CODEX_WORKSPACE" || ! -x "$CODEX_WORKSPACE" ]]; then
    printf 'Workspace is unavailable or unwritable: %s\n' "$CODEX_WORKSPACE" >&2
    status=1
  fi
  if [[ ! -d "$CODEX_HOME" || ! -w "$CODEX_HOME" || ! -x "$CODEX_HOME" ]]; then
    printf 'Codex state directory is unavailable or unwritable: %s\n' "$CODEX_HOME" >&2
    status=1
  fi

  if (( status == 0 )); then
    printf '%s\n' 'Codex CLI, workspace, and state checks passed.'
  fi
  return "$status"
}

cdxupdate() {
  local version="${1-latest}"
  local version_pattern='^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'

  if (( $# > 1 )) || [[ "$version" != latest && ! "$version" =~ $version_pattern ]]; then
    printf '%s\n' 'Usage: cdxupdate [latest|major.minor.patch]' >&2
    return 2
  fi

  command npm install --global "@openai/codex@$version" || return "$?"
  hash -r
  command codex --version
}

cdxh() {
  cat <<EOF
╭──────────────────────────────────────────────╮
│                 Codex Shell                  │
╰──────────────────────────────────────────────╯
  Codex      $(cdx_version)
  Workspace  ${CODEX_WORKSPACE}
  Config     ${CODEX_HOME}
EOF

  cdx_help_table
  printf '\n'
}

cdx_welcome() {
  [[ $- == *i* ]] || return 0
  [[ -z "${cdx_welcome_shown:-}" ]] || return 0

  cdx_welcome_shown=1

  cat <<EOF
╭──────────────────────────────────────────────╮
│                 Codex Shell                  │
╰──────────────────────────────────────────────╯
  Runtime    $(cdx_in_container && echo docker || echo host)
  Codex      $(cdx_version)
  Workspace  ${CODEX_WORKSPACE}
  Config     ${CODEX_HOME}
  Auth       $(cdx_auth_status)
EOF

  cdx_help_table
  printf '\n'
}

cdx_welcome
