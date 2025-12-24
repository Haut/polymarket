# Contributing

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Install dependencies with `opam install . --deps-only`
4. Build the project with `dune build`
5. Run tests with `dune runtest`

## Development Workflow

1. Create a new branch for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and ensure:
   - Code compiles without errors: `dune build`
   - Tests pass: `dune runtest`
   - Code is properly formatted: `dune fmt`

3. Commit your changes with clear, descriptive messages

4. Push to your fork and submit a pull request

## Pull Request Guidelines

- Provide a clear description of the changes
- Reference any related issues
- Ensure all tests pass
- Keep pull requests focused on a single concern
- Update documentation if needed

## Reporting Issues

When reporting issues, please include:

- A clear, descriptive title
- Steps to reproduce the issue
- Expected vs actual behavior
- Environment details (OS, OCaml version, etc.)

## Code Style

- Follow existing code conventions in the project
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and concise

## Questions?

Feel free to open an issue for any questions or concerns.
