#!/usr/bin/env bash
set -Eeuo pipefail

cd /workspace

# Load NVM if present so Node/Codex are available consistently.
if [[ -s /root/.nvm/nvm.sh ]]; then
  # shellcheck disable=SC1091
  source /root/.nvm/nvm.sh
fi

print_line() {
  printf '%s\n' "────────────────────────────────────────"
}

print_header() {
  print_line
  printf '%s\n' " Codex container is ready"
  print_line
}

print_auth_status() {
  if codex login status >/dev/null 2>&1; then
    printf '%s\n' " Status : authenticated"
  else
    printf '%s\n' " Status : not authenticated"
    printf '%s\n' " Tip    : run 'cdxlogin' to start device authentication"
  fi
}

print_shortcuts() {
  printf '%s\n' " Shortcuts:"
  printf '%s\n' "   cdx   -> run codex (bypass approvals)"
  printf '%s\n' "   cdxn  -> run codex normally"
  printf '%s\n' "   cdxr  -> resume a codex session"
  printf '%s\n' "   cdxs  -> auth status"
  printf '%s\n' "   cdxl  -> login if needed"
  printf '%s\n' "   cdxlo -> logout"
  printf '%s\n' "   cw    -> cd /workspace"
  printf '%s\n' "   cdxh  -> show help"
}

print_header
print_auth_status
print_shortcuts
print_line

# If arguments were provided, run them.
# Otherwise, start an interactive login shell.
if [[ $# -gt 0 ]]; then
  exec "$@"
else
  exec bash -l
fi
