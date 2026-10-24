#!/usr/bin/env bash
set -Eeuo pipefail

export CODEX_CONTAINER="${CODEX_CONTAINER:-1}"
export CODEX_WORKSPACE="${CODEX_WORKSPACE:-/workspace}"
export CODEX_AUTO_UPDATE="${CODEX_AUTO_UPDATE:-1}"

mkdir -p "$CODEX_WORKSPACE" /root/.codex
cd "$CODEX_WORKSPACE"

if ! command -v codex >/dev/null 2>&1; then
  echo "Installing Codex CLI..."
  npm install -g @openai/codex
elif [[ "$CODEX_AUTO_UPDATE" == "1" ]]; then
  echo "Updating Codex CLI..."
  npm update -g @openai/codex || npm install -g @openai/codex
fi

codex --version || true

if [[ $# -eq 0 ]]; then
  exec bash -l
fi

exec "$@"
