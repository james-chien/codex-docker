#!/usr/bin/env bash
set -Eeuo pipefail

cd /workspace

# If arguments were provided, run them.
# Otherwise, start an interactive login shell.
if [[ $# -gt 0 ]]; then
  exec "$@"
else
  exec bash -l
fi
