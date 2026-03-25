# Contributing

Thank you for your interest in contributing to **Codex Docker**.

This repository aims to provide a clean, reproducible Docker environment for running the OpenAI Codex CLI. Contributions that improve reliability, usability, or developer experience are welcome.

## How to Contribute

You can contribute in several ways:

- Reporting bugs
- Suggesting improvements
- Improving documentation
- Fixing issues
- Adding new features

Before submitting changes, please check existing issues to avoid duplicate work.

## Development Workflow

1. **Fork the repository**

2. **Create a feature branch**

```bash
git checkout -b feature/your-feature-name
```

3. **Make your changes**

Keep changes focused and minimal.

4. **Test your changes**

Ensure the container builds and runs correctly:

```bash
docker compose build
docker compose up
```

Verify that Codex works inside the container.

5. **Commit your changes**

Use clear, descriptive commit messages.

Example:

```
fix: correct shell helper path
docs: improve README quick start section
```

6. **Open a Pull Request**

Provide a clear description of:
	
- what changed
- why the change is needed
- any relevant context

## Code Guidelines

Please follow these guidelines when contributing:

### Keep it simple

This project intentionally keeps the environment minimal and easy to maintain.

Avoid adding unnecessary complexity or large dependencies.

### Follow existing conventions

Match the existing style used in:
	
- Dockerfile
- shell scripts
- documentation

### Shell scripts

- use bash
- be portable and simple
- avoid unnecessary dependencies

## Documentation

Documentation improvements are always welcome.

Examples:
	
- improving clarity in the README
- adding usage examples
- fixing typos or formatting issues

## Reporting Issues

When reporting a bug, please include:
	
- operating system
- Docker version
- steps to reproduce the issue
- relevant logs or error messages

This helps maintainers diagnose problems quickly.

## Pull Request Checklist

Before submitting a pull request, please ensure:
	
- The container builds successfully
- Changes are tested locally
- Documentation is updated if needed
- Commit messages are clear

## Questions

If you have questions or ideas for improvements, feel free to open an issue for discussion.

Thank you for helping improve **Codex Docker**.
