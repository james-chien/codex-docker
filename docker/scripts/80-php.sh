#!/bin/sh
set -eu

# Install PHP runtime dependencies
apt-get -o APT::Update::Error-Mode=any update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libxml2 \
    libsqlite3-0 \
    libonig5 \
    libreadline8t64 \
    libargon2-1 \
    libsodium23

# Clean up APT package lists
rm -rf /var/lib/apt/lists/*

php -r '
    foreach (["libxml", "pdo_sqlite", "sqlite3", "readline", "sodium"] as $extension) {
        if (!extension_loaded($extension)) {
            fwrite(STDERR, "Missing PHP extension: $extension\n");
            exit(1);
        }
    }
'
