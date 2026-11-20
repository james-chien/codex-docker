#!/bin/sh
set -eu

# Install C and C++ build tools
apt-get -o APT::Update::Error-Mode=any update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    make \
    cmake \
    libc6-dev \
    binutils

# Clean up APT package lists
rm -rf /var/lib/apt/lists/*

# Verify the installation
make --version
cmake --version
