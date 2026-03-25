# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project documentation
- Docker environment for running the OpenAI Codex CLI
- Interactive shell environment with helper commands
- Support for persistent Codex authentication

### Changed
- Improved developer workflow using Docker Compose
- Simplified onboarding with Quick Start instructions

## [0.1.0] - 2026-03-26

### Added
- Initial release of **Codex Docker**
- Dockerfile for building a reproducible Codex environment
- Docker Compose configuration
- Shell helper commands for Codex:
  - `cdx`
  - `cdxn`
  - `cdxr`
  - `cdxs`
  - `cdxl`
  - `cdxlo`
  - `cdxh`
  - `cw`
- Persistent authentication using mounted `.codex` directory
- Mounted workspace for local project development
