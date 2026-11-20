# Repository Guidelines

## Project Structure

- `docker.config.json` and `scripts/generate-dockerfile.mts` define the checked-in `Dockerfile`. Update the source files and regenerate the Dockerfile when changing the image definition.
- `docker/scripts/` contains numbered installers for build-time tools and runtime dependencies. `entrypoint.sh` sets up the Codex CLI at startup. `scripts/codex-shell.sh` provides interactive Bash shortcuts and diagnostics.
- `compose.yaml` defines the `codex` service, mounts `./workspace` at `/workspace`, and publishes port 8000 on loopback by default. `tests/` contains the offline TypeScript test suite.

## Build and Development

Run commands from the repository root.

- `docker compose config --quiet` validates the Compose configuration.
- `docker compose build codex` builds the development image and runs the toolchain installers.
- `docker compose run --rm codex` starts a disposable interactive shell through the normal entrypoint.
- `node scripts/generate-dockerfile.mts --force docker.config.json Dockerfile` refreshes the checked-in Dockerfile.

## Coding Style and Verification

Use POSIX shell syntax in `entrypoint.sh` and `docker/scripts/*.sh`. Keep Bash-specific helpers in `scripts/codex-shell.sh`. Match the surrounding indentation and keep numbered installers in the form `NN-runtime.sh`, such as `20-python.sh`.

Use Node.js 22.18 or newer. Run `node --test tests/*.test.mts` for offline regression tests and `node scripts/generate-dockerfile.mts --check` to check generated output. Use `node scripts/smoke-test-docker.mts` with a running Docker daemon to test default and minimal image builds and startup. For runtime changes, also exercise the affected tool.

## Commits and Pull Requests

Use a short, descriptive commit subject, such as “Fix Codex startup version check.” In the pull request, summarize the affected runtime or startup behavior, link any related issue, and list the checks you ran. Keep local Codex state, npm caches, and credentials out of commits and image builds.
