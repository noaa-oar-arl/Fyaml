# Contributing

Thank you for considering contributing to FYAML! This document provides guidelines and instructions for contributing to the project.

## Getting Started

### Prerequisites

To contribute to FYAML, you will need:

- Fortran compiler (gfortran >= 9.0, Intel Fortran >= 19.0, or other compliant compiler)
- CMake >= 3.12
- Git
- (Optional) Python for running certain tests and utilities

### Setting Up Your Development Environment

1. Fork the repository on GitHub.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/yourusername/fyaml.git
   cd fyaml
   ```

3. Set up the upstream remote:
   ```bash
   git remote add upstream https://github.com/original-owner/fyaml.git
   ```

4. Create a branch for your work:
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Building for Development

FYAML uses CMake as its build system. To build the project in development mode:

```bash
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug -DFYAML_BUILD_TESTS=ON
make
```

Run the tests to make sure everything is working:

```bash
make test
```

## Contribution Guidelines

### Code Style

FYAML follows a consistent coding style:

- **Indentation**: 2 spaces (no tabs)
- **Naming Convention**:
  - Module names: `lowercase_with_underscores`
  - Types: `lowercase_with_underscores_type`
  - Variables and functions: `lowercase_with_underscores`
  - Constants and parameters: `UPPERCASE_WITH_UNDERSCORES`
- **Line Length**: Try to keep lines under 100 characters
- **Comments**: Use ! for comments, provide a brief description for each subroutine/function
- **Documentation**: Follow Doxygen-style comments for public interfaces

### Pull Request Process

1. Update the documentation if necessary.
2. Add or update tests as needed.
3. Make sure all tests pass before submitting your PR.
4. Update the CHANGELOG.md with details of changes.
5. Submit your pull request with a clear description of the changes.

### Commit Messages

Write clear, concise commit messages:

```
category: Brief summary of changes (under 50 chars)

More detailed explanatory text, if necessary. Wrap it to about 72
characters. The blank line separating the summary from the body is
critical.

- Bullet points are okay
- Typically a hyphen or asterisk is used, followed by a single space
```

Categories include:
- `fix`: Bug fixes
- `feat`: New features
- `docs`: Documentation changes
- `test`: Adding or modifying tests
- `refactor`: Code changes that neither fix bugs nor add features
- `perf`: Performance improvements
- `style`: Formatting, missing semicolons, etc.
- `chore`: Maintenance tasks

### Adding Tests

All new features or bug fixes should include tests:

1. Place tests in the `tests/` directory.
2. Follow the naming convention: `test_<feature>.f90`.
3. Update `tests/CMakeLists.txt` to include your test.

```fortran
! Example test structure
program test_new_feature
  use fyaml
  implicit none

  ! Test variables
  logical :: status

  ! Test case 1
  print *, "Testing feature A..."
  status = test_feature_a()
  if (.not. status) then
    stop 1  ! Non-zero exit code indicates failure
  end if

  ! Test case 2
  print *, "Testing feature B..."
  status = test_feature_b()
  if (.not. status) then
    stop 1
  end if

  print *, "All tests passed!"

contains

  logical function test_feature_a() result(success)
    ! Test implementation
    success = .true.
  end function

  ! Additional test functions

end program
```

### Documentation

Documentation is crucial for FYAML. When adding or modifying features:

1. Update docstrings in the code.
2. Update relevant Markdown files in the `docs/` directory.
3. Add examples if relevant.

### Reporting Bugs

When reporting bugs, please include:

1. A clear description of the bug
2. Steps to reproduce
3. Expected behavior
4. Actual behavior
5. Environment information (compiler version, etc.)

## Development Workflow

### Adding a New Feature

1. Ensure there's an issue that describes the feature.
2. Discuss the implementation approach if needed.
3. Implement the feature with tests and documentation.
4. Submit a pull request.

### Fixing a Bug

1. Reproduce the bug locally.
2. Write a test that exposes the bug.
3. Fix the bug and verify the test passes.
4. Submit a pull request.

### Code Review Process

All submissions require review before merging:

1. Maintainers will review your PR.
2. Address any feedback or requested changes.
3. Once approved, the PR will be merged.

## Release Process

FYAML follows semantic versioning (MAJOR.MINOR.PATCH):

- MAJOR version: Incompatible API changes
- MINOR version: New functionality in a backward-compatible manner
- PATCH version: Backward-compatible bug fixes

### Release Steps (for maintainers)

1. Update version numbers in relevant files.
2. Update CHANGELOG.md with the release notes.
3. Create a tagged release on GitHub.

## Communication

- Use GitHub Issues for bug reports and feature requests
- Use Pull Requests for submitting changes
- For larger discussions, consider opening a discussion thread

## License

By contributing to FYAML, you agree that your contributions will be licensed under the project's license.
