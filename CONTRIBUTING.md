# Contributing to Codex Docker

## Report an Issue

Include the expected behavior, the actual result, and the commands needed to reproduce it. Share your host OS and CPU architecture, Docker and Compose versions, and relevant output. For a custom image, include the runtime selection and Codex version. For startup failures, include the terminal output or `docker compose logs codex` if the service ran in the background. Remove credentials and private workspace details before sharing logs.

## Set Up and Make Changes

Follow the [quick start](README.md#quick-start) to build the image and open an interactive shell.

- Update [docker.config.json](docker.config.json) for default runtime or Codex version changes. Update the [generator](scripts/generate-dockerfile.mts) for changes to the build instructions. Refresh the checked-in Dockerfile with `node scripts/generate-dockerfile.mts --force docker.config.json Dockerfile`.
- Use `docker/scripts/NN-runtime.sh` for build-time tools and system dependencies. Keep these installers and [entrypoint.sh](entrypoint.sh) compatible with POSIX `sh`.
- Use [scripts/codex-shell.sh](scripts/codex-shell.sh) for interactive Bash behavior. Match the indentation in the surrounding code.
- Update the README when a change affects setup, supported tools, configuration, or shell shortcuts. See [AGENTS.md](AGENTS.md) for repository conventions.

Keep local Codex state, npm caches, workspace files, and credentials out of commits.

## Verify Your Changes

From the repository root, use Node.js 22.18 or newer and Bash to run the offline suite and check the checked-in Dockerfile. The tests stub package installs and downloads.

```bash
node --test tests/*.test.mts
node scripts/generate-dockerfile.mts --check
```

For changes to the generator, toolchains, or startup, also run the [Docker smoke test](README.md#docker-smoke-test) to verify both the default and minimal images.

For changes to Compose, validate the configuration and build the service image.

```bash
docker compose config --quiet
docker compose build codex
```

- **Toolchain changes.** Run the affected tool in the built image. For example, `docker compose run --rm --entrypoint /usr/bin/env codex uv --version` verifies uv without running Codex startup.
- **Bash helper changes.** Open an interactive shell using the README quick start. Exercise the affected shortcut, then open a nested Bash shell if the change affects initialization.
- **Startup changes.** Run `docker compose run --rm codex` through the normal entrypoint. Confirm that it reaches the requested shell and that `codex --version` succeeds.

## Submit a Pull Request

Use a short commit subject that describes the change, such as `Fix Codex startup version check`. In the pull request, explain what changed and why, link the related issue if there is one, and list the checks you ran and their results. Call out any checks you could not run and any changes contributors need to make to their local setup.
