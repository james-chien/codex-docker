<p align="center">
  <img src=".github/banner.png" alt="Codex Docker Banner" width="80%" />
</p>

# Codex Docker

![Docker](https://img.shields.io/badge/docker-ready-blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

A lightweight **Docker development environment for OpenAI Codex**.

Run the Codex CLI in a clean, reproducible container without installing runtimes or managing dependencies locally.  
Your **workspace and authentication persist between runs**, making it easy to work with Codex in an isolated environment.

## ✨ Overview

Setting up AI developer tools locally often requires managing multiple runtimes, CLI dependencies, and authentication state.

This repository provides a **ready-to-use containerized Codex environment**.  
When the container starts, you enter an interactive shell where **Codex and several programming runtimes are already available**.

## 🚀 Features

- Preconfigured **Codex CLI environment**
- No local installation of Node.js or Codex required
- **Persistent authentication** between container runs
- Interactive development shell
- Simple Docker Compose setup
- Workspace automatically mounted from the host machine
- Helpful shell shortcuts for common Codex commands

## 🧰 Included Toolchain

The container includes several runtimes commonly used in AI-assisted development workflows.

### Languages & Runtimes

| Language | Purpose |
|--------|--------|
| Node.js | JavaScript / TypeScript development |
| Python | scripting and AI tooling |
| Rust | systems programming |
| Go | backend and CLI development |
| Swift | Apple platform development |
| Ruby | scripting and web tooling |
| PHP | web development |
| Bun | modern JavaScript runtime |
| C++ | high-performance systems programming |
| Elixir | concurrent and distributed systems |
| Java | JVM ecosystem development |

### Build & Development Tools

| Tool | Purpose |
|------|--------|
| Bazel | build and test automation system |

These tools allow Codex to generate and run code across multiple ecosystems.

## ⚡ Quick Start

Clone the repository:

```bash
git clone https://github.com/james-chien/codex-docker.git
cd codex-docker
```

Build and start the container:

```bash
docker compose up -d --build
docker exec -it codex bash -l
```

You are now inside the Codex development container.

## 💻 Using Codex

The container provides several shortcut commands.

| Command | Description |
|--------|-------------|
| `cdx`  | Run Codex (approval bypass mode) |
| `cdxn` | Run Codex normally |
| `cdxr` | Resume a Codex session |
| `cdxs` | Show authentication status |
| `cdxl` | Login if needed |
| `cdxlo` | Logout |
| `cdxh` | Show helper commands |
| `cw` | Change directory to `/workspace` |

## 🤝 Contributing

Contributions are welcome.

Please read **CONTRIBUTING.md** for contribution guidelines.

## 📝 Changelog

Project history and release notes are maintained in **CHANGELOG.md**.

## 📄 License

MIT
