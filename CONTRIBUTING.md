# Contributing to Fyaml

Thank you for your interest in contributing to Fyaml! This document outlines the process and guidelines for contributing.

## Development Setup

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/your-username/Fyaml.git
   cd Fyaml
   ```

2. Set up development environment:
   ```bash
   pre-commit install
   ```

3. Configure and build the project:
   ```bash
   cmake -B build -DCMAKE_BUILD_TYPE=Debug
   cmake --build build
   ```

## Coding Standards
- Use 2 spaces for indentation
- Follow modern Fortran best practices:
  * Use modules instead of common blocks
  * Explicit typing (no implicit typing)
  * Use pure/elemental procedures where appropriate
  * Include intent specifiers for all dummy arguments
  * Document all public interfaces using FORD syntax
  * Maximum line length of 80 characters

### Submitting Changes
1. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following the coding standards
3. Add tests for any new functionality
4. Update documentation as needed
5. Run the test suite:
   ```bash
   ctest --test-dir build/tests --output-on-failure
   ```
   Or if your CMake is older than 3.20:
   ```bash
   (cd build/tests && ctest --output-on-failure)
   ```

### Submit a Pull Request with:
- Clear description of changes
- Any related issues referenced
- Test results included
- Documentation updates if applicable

### Testing Guidelines
- Write unit tests for all new functionality
- Use pFUnit for unit testing when possible
- Maintain test coverage above 80%
- Include both success and failure test cases
- Test edge cases and error conditions

### Documentation
- Use FORD documentation syntax (see https://forddocs.readthedocs.io/en/stable/)
- Document all public interfaces
- Include examples in documentation
- Update README.md if adding new features
- Maintain up-to-date examples

### Code Review Process
- All changes require review
- Address review feedback promptly
- Keep pull requests focused and small
- Maintain a clean commit history

### Getting Help
- Open an issue for bugs or feature requests
- Join our discussion forum

### License
By contributing, you agree that your contributions will be licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for full text.
