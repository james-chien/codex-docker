#!/bin/sh
set -eu

# Download the complete installer before running it.
installer=$(mktemp)
trap 'rm -f "$installer"' EXIT
curl --fail --silent --show-error --location \
    --output "$installer" https://astral.sh/uv/install.sh
UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh "$installer"

uv --version
