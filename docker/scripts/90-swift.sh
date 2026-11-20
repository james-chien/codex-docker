#!/bin/sh
set -eu

# Install Swift compiler and linker dependencies
apt-get -o APT::Update::Error-Mode=any update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    clang \
    lld \
    binutils \
    libc6-dev \
    libstdc++-14-dev \
    libncurses6 \
    libtinfo6 \
    libsqlite3-0

# Clean up APT package lists
rm -rf /var/lib/apt/lists/*

clang --version
ld.lld --version
