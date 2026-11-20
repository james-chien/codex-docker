# Changelog

## Unreleased

### Added

- Added a JSON-configured Dockerfile generator with toolchain selection and Codex CLI version pinning.
- Added a read-only Dockerfile freshness check and a Docker smoke test for the default and minimal images.
- Added `cdxcheck` to validate container prerequisites and `cdxupdate` to install the latest or a specified Codex CLI release.
- Added an offline TypeScript regression suite for the entrypoint, Bash helpers, and installer failure paths.
- Added build-time checks for Ruby YAML, PHP extensions, and Swift build tools.
- Added [contribution guidelines](CONTRIBUTING.md) covering issue reports, local verification, and pull requests.
- Added [repository guidelines](AGENTS.md) covering project layout, shell conventions, and development commands.

### Changed

- Startup reuses a working Codex CLI and installs the configured release if the CLI is missing, broken, or differs from the configured pin.
- Published the Compose development port on loopback by default, added host IP and port overrides, and switched to Compose-generated container names.
- Gave the Codex health check a longer startup grace period for the npm install and retained command output for diagnostics.
- Updated the [README](README.md) to document the toolchains supplied by the upstream images and build scripts, persistent mounts, port forwarding, and Bash shortcuts.
- Expanded `cdxdoctor` to report Bun, CMake, Make, pnpm, TypeScript, and uv. Version checks now capture stderr and distinguish missing commands from failed version checks.
- Used the Debian Trixie Swift image when Swift is selected and added build-time checks for the assembled toolchains.

### Fixed

- Made runtime installers fail on incomplete APT updates or a failed uv download.
- Nested Bash sessions now load the Codex helpers even when their parent shell has already loaded them.
- Sourcing the helpers in a noninteractive Bash shell now succeeds with `set -e`. Interactive sessions display the welcome banner once.
- Fixed the Codex version check in the entrypoint so startup can reach the requested command.
- Restored the GCC shared-library search configuration and added the PHP Readline runtime dependency.
