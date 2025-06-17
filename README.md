# FYAML - Fortran YAML Parser

![Build Status](https://github.com/fyaml/fyaml/workflows/CI/badge.svg)
![Coverage](https://github.com/fyaml/fyaml/workflows/Code%20Coverage/badge.svg)

A comprehensive and modern Fortran library for parsing YAML configuration files. FYAML provides an easy-to-use interface for reading YAML files in Fortran applications, supporting all major YAML features including nested structures, arrays, anchors, and aliases.

## Quality Assurance

FYAML maintains high code quality standards:

- ⚠️ **Zero Warnings**: Compiles cleanly with strict compiler flags (`-Wall -Wextra -pedantic`)
- 🧪 **Comprehensive Testing**: 89.4% code coverage with 18 specialized test programs
- 🔄 **Continuous Integration**: Automated testing across multiple platforms and compilers
- 📊 **Performance Tested**: Handles large files and complex structures efficiently
- 🎯 **API Complete**: All public functions thoroughly tested with edge cases
- 🔧 **Multi-Compiler**: Tested with GCC, Intel ifx/ifort, NVIDIA HPC, and LFortran

## Features

- 🚀 **Modern Fortran**: Written in standard-compliant Fortran 2003+
- 📝 **YAML Compliance**: Supports YAML 1.2 specification
- 🔧 **Easy Integration**: Simple CMake and pkg-config support
- 📦 **Package Manager Ready**: Spack package available for HPC environments
- 🧪 **Well Tested**: Comprehensive test suite with 89.4% overall coverage
- ⚠️ **Warning-Free**: Zero compiler warnings with strict compilation flags
- 🏭 **Multi-Compiler**: Supports GCC, Intel (ifx/ifort), NVIDIA HPC SDK, LFortran
- 📚 **Documented**: Complete API documentation and user guides
- 🔗 **Anchors & Aliases**: Full support for YAML references
- 📊 **Arrays & Objects**: Handle complex nested data structures
- ⚡ **Performance**: Optimized for large configuration files
- 🔍 **Robust Testing**: 18 test programs covering all API functions and edge cases

## Quick Start

### Installation

#### From Source

```bash
git clone https://github.com/fyaml/fyaml.git
cd fyaml
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make install
```

#### Using Spack

[Spack](https://spack.io/) is the preferred method for HPC and scientific computing environments:

```bash
# Basic installation
spack install fyaml

# With variants
spack install fyaml +tests +shared

# Load into environment
spack load fyaml
```

See [SPACK_SETUP.md](SPACK_SETUP.md) for detailed Spack installation instructions.

#### Package Managers

- **Spack**: `spack install fyaml` (recommended for HPC)
- **Source**: CMake-based build system
- **Future**: Additional package managers coming soon

### Basic Usage

```fortran
program example
    use fyaml
    implicit none

    type(fyaml_t) :: yml
    integer :: max_iterations, rc
    real(fyaml_yp) :: tolerance
    character(len=fyaml_StrLen) :: output_file
    integer, dimension(3) :: grid_size

    ! Add configuration values
    call fyaml_add(yml, "solver%max_iterations", 1000, "Maximum iterations", rc)
    call fyaml_add(yml, "solver%tolerance", 1.0e-6_fyaml_yp, "Convergence tolerance", rc)
    call fyaml_add(yml, "output%file", "results.dat", "Output filename", rc)
    call fyaml_add(yml, "grid%size", [100, 100, 50], "Grid dimensions", rc)

    ! Read configuration values back
    call fyaml_get(yml, "solver%max_iterations", max_iterations, rc)
    call fyaml_get(yml, "solver%tolerance", tolerance, rc)
    call fyaml_get(yml, "output%file", output_file, rc)
    call fyaml_get(yml, "grid%size", grid_size, rc)

    ! Clean up
    call fyaml_cleanup(yml)
end program
```

## Compiler Support

FYAML is tested and verified to work with multiple Fortran compilers:

| Compiler | Vendor | Versions Tested | CI Status |
|----------|---------|----------------|-----------|
| **GFortran** | GNU | 11, 12, 13, 14 | ✅ Fully Tested |
| **ifx** | Intel | 2025.0+ | ✅ Fully Tested |
| **ifort** | Intel (Classic) | 2021.10+ | ✅ Fully Tested |
| **nvfortran** | NVIDIA HPC SDK | 25.1+ | ✅ Fully Tested |
| **LFortran** | LFortran | 0.45.0+ | ⚠️ Manual Testing |

**Cross-Platform Testing:**
- 🐧 **Linux**: Ubuntu 24.04 (primary CI platform)
- 🍎 **macOS**: macOS 14+ (GCC) - CI tested
- 🪟 **Windows**: Windows Server 2022 (GCC) - Manual testing

Primary compilers (GCC, Intel, NVIDIA HPC) are automatically tested in CI with both Debug and Release configurations.

## Building and Testing

### Standard Build (Library Only)

By default, FYAML builds only the library without tests, making it suitable for production use and package installation:

```bash
mkdir build && cd build
cmake ..
make
```

### With Tests

To build and run the comprehensive test suite:

```bash
cmake .. -DBUILD_TESTING=ON
make
ctest --output-on-failure
```

### Legacy Test Option

For compatibility with older scripts, you can also use:

```bash
cmake .. -DFYAML_BUILD_TESTS=ON  # Legacy alias for BUILD_TESTING
make
ctest --output-on-failure
```

**Test Suite Overview:**
- 🧪 **18 comprehensive test programs** covering all functionality
- ✅ **100% test pass rate** - all tests consistently pass
- 🔍 **API Coverage**: Complete testing of `fyaml_add`, `fyaml_get`, `fyaml_update`, `fyaml_add_get`
- 📊 **Data Types**: Full coverage for integers, reals, booleans, strings (scalars and arrays)
- 🎯 **Edge Cases**: Comprehensive testing of boundary conditions and error paths
- 📈 **Array Testing**: Various sizes, patterns, and multidimensional-like structures

### Code Coverage

To generate code coverage reports:

```bash
# Install coverage tools (Ubuntu/Debian)
sudo apt-get install lcov

# Configure with coverage
cmake .. -DFYAML_ENABLE_COVERAGE=ON -DCMAKE_BUILD_TYPE=Debug

# Build and run tests
make
ctest

# Generate coverage report
make coverage
```

This will create an HTML coverage report in `coverage-html/` that you can open in your browser.

### GitHub Actions

The project includes automated testing and deployment:

- **CI Workflow**: Automatically builds with tests enabled (`-DBUILD_TESTING=ON`) and tests on multiple platforms and compilers
- **Coverage Workflow**: Generates coverage reports and uploads them as artifacts
- **Documentation**: Automatically builds and deploys to GitHub Pages on every push to main

**Note**: While tests are disabled by default for end-user builds, they are automatically enabled in all CI/CD workflows to ensure code quality and compatibility across different platforms and compilers.

Coverage reports are automatically generated for pull requests and can be downloaded as artifacts from the GitHub Actions page. Documentation is automatically published at https://noaa-oar-arl.github.io/fyaml/

## CMake Integration

### Using find_package

```cmake
find_package(FYAML REQUIRED)
target_link_libraries(your_target PRIVATE FYAML::fyaml)
```

### Using pkg-config

```cmake
find_package(PkgConfig REQUIRED)
pkg_check_modules(FYAML REQUIRED fyaml)
target_link_libraries(your_target PRIVATE ${FYAML_LIBRARIES})
target_include_directories(your_target PRIVATE ${FYAML_INCLUDE_DIRS})
```

## Documentation

- 📖 **[User Guide](https://noaa-oar-arl.github.io/fyaml/user-guide/)**: Complete usage examples
- 🔧 **[API Reference](https://noaa-oar-arl.github.io/fyaml/api/)**: Detailed function documentation
- 🏗️ **[Developer Guide](https://noaa-oar-arl.github.io/fyaml/developer/)**: Contributing and architecture
- 🚀 **[Getting Started](https://noaa-oar-arl.github.io/fyaml/getting-started/)**: Installation and first steps
- 📦 **[Spack Installation](SPACK_SETUP.md)**: HPC package manager integration

## Examples

See the `examples/` directory for complete working examples:

- `example.f90`: Simple configuration parsing and basic usage
- Advanced features: Anchors, arrays, and complex structures (see test files)
- CMake integration: Example project setup

**Key Test Programs:**
- `test_api_functions.f90`: Comprehensive API testing (461 lines, 99.8% coverage)
- `test_comprehensive_arrays.f90`: Complete array testing (174 lines, 100% coverage)
- `test_edge_cases.f90`: Boundary conditions and error handling (65 lines, 100% coverage)
- Plus 15 additional specialized test programs covering all functionality

## Contributing

We welcome contributions! Please see our [Contributing Guide](https://fyaml.github.io/fyaml/developer/contributing/) for details on:

- Code style and standards
- Testing requirements
- Pull request process
- Development setup

### Recent Improvements

**Code Quality Enhancements:**
- ✅ Eliminated all compiler warnings (intent overlap, unused variables, string truncation)
- 📈 Increased test coverage from ~44% to 89.4% overall
- 🎯 Enhanced main API coverage to 74.4% (fyaml.f90)
- 🧪 Added 3 major comprehensive test suites

**New Test Coverage:**
- `test_api_functions.f90`: Complete API function testing with all data types
- `test_comprehensive_arrays.f90`: Extensive array testing (single to large arrays)
- `test_edge_cases.f90`: Boundary conditions and error path validation
- Full round-trip testing: add → get → update → verify workflows

### Development Setup

```bash
# Clone and setup development environment
git clone https://github.com/fyaml/fyaml.git
cd fyaml

# Install dependencies (Ubuntu/Debian)
sudo apt-get install gfortran cmake

# macOS with Homebrew
brew install gcc cmake

# Build with all options enabled
mkdir build && cd build
cmake .. -DBUILD_TESTING=ON -DFYAML_ENABLE_COVERAGE=ON
make

# Run full test suite
ctest --output-on-failure

# Generate coverage report (requires GCC)
make coverage
```

### Coverage Testing

FYAML includes comprehensive coverage testing using `gcov`. To run coverage analysis:

```bash
# Using the provided script (macOS with Homebrew)
./scripts/run_coverage.sh

# Or manually
mkdir build-coverage && cd build-coverage
cmake .. -DFYAML_ENABLE_COVERAGE=ON -DBUILD_TESTING=ON
make coverage
```

**Current Coverage Statistics:**
- 📊 **Overall Project**: 89.4% coverage (2,474 of 2,767 lines executed)
- 🎯 **Main API Module**: 74.4% coverage (fyaml.f90 - 484 of 651 lines executed)
- ✅ **Test Files**: Near 100% coverage across all test programs
- 🔍 **Key Modules**: High coverage across all critical components

Coverage reports are generated as `.gcov` files showing line-by-line execution data. Lines marked with `#####` indicate code that wasn't executed and may need additional test coverage.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/fyaml/fyaml/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/fyaml/fyaml/discussions)
- 📧 **Email**: [maintainers@fyaml.org](mailto:maintainers@fyaml.org)

## Acknowledgments

- Thanks to all contributors who have helped improve FYAML
- Inspired by modern YAML parsers in other languages
- Built with modern Fortran best practices
