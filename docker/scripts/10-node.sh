#!/bin/sh
set -eu

# Install the JavaScript package manager, runtime toolkit, and compiler.
npm install --global pnpm@latest bun@latest typescript@latest

pnpm --version
bun --version
tsc --version
