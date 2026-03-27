#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p /workspace
cd /workspace

if [[ $# -gt 0 ]]; then
  exec "$@"
else
  exec bash -l
fi
