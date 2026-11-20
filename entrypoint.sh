#!/bin/sh
set -eu

requested_version=${CODEX_VERSION:-latest}
installed_version=

if command -v codex >/dev/null 2>&1; then
    installed_version=$(codex --version) || installed_version=
fi

if [ -z "$installed_version" ] ||
    { [ "$requested_version" != latest ] && [ "${installed_version##* }" != "$requested_version" ]; }; then
    printf '==> Installing Codex CLI (%s)\n' "$requested_version"
    npm install --global "@openai/codex@$requested_version"
    installed_version=$(codex --version)
fi

if [ "$requested_version" != latest ] && [ "${installed_version##* }" != "$requested_version" ]; then
    printf 'Expected Codex CLI %s, got %s\n' "$requested_version" "$installed_version" >&2
    exit 1
fi
printf '%s\n' "$installed_version"

if [ "$#" -eq 0 ]; then
    set -- /bin/bash
fi

# Start the requested command
exec "$@"
