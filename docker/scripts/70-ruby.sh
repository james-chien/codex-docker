#!/bin/sh
set -eu

# Install Ruby runtime dependencies
apt-get -o APT::Update::Error-Mode=any update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libyaml-0-2

# Clean up APT package lists
rm -rf /var/lib/apt/lists/*

ruby -ryaml -e 'YAML.safe_load("ready: true")'
