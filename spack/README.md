# FYAML Spack Package

This directory contains the Spack package definition for FYAML.

## Files

- `package.py` - Spack package definition for FYAML
- `test_installation.sh` - Test script to verify Spack installation
- `README.md` - This file

## Usage

### Installing FYAML with Spack

See [../SPACK_SETUP.md](../SPACK_SETUP.md) for complete installation instructions.

Quick start:

```bash
# Add custom repository (if FYAML is not in main Spack repo yet)
spack repo create fyaml-repo
cp package.py fyaml-repo/packages/fyaml/package.py
spack repo add fyaml-repo

# Install FYAML
spack install fyaml

# Load into environment
spack load fyaml
```

### Testing Installation

After installing FYAML with Spack:

```bash
# Load FYAML
spack load fyaml

# Run test script
./test_installation.sh
```

### Package Variants

| Variant | Default | Description |
|---------|---------|-------------|
| `+tests` / `~tests` | `~tests` | Build and run test suite |
| `+examples` / `~examples` | `+examples` | Build example programs |
| `+shared` / `~shared` | `+shared` | Build shared libraries |

### Examples

```bash
# Install with all features
spack install fyaml +tests +examples +shared

# Install minimal version
spack install fyaml ~tests ~examples ~shared

# Install with specific compiler
spack install fyaml %gcc@13

# Install for HPC environment
spack install fyaml %intel@2025.0 +shared
```

## Contributing to Spack

To contribute this package to the main Spack repository:

1. Fork the Spack repository: https://github.com/spack/spack
2. Copy `package.py` to `var/spack/repos/builtin/packages/fyaml/package.py`
3. Test the package:
   ```bash
   spack install fyaml
   spack test fyaml
   ```
4. Submit a pull request to Spack

## Package Development

### Testing the Package

```bash
# Check package definition
spack info fyaml

# Check dependencies
spack spec fyaml

# Install in development mode
spack dev-build fyaml

# Run Spack's built-in tests
spack test fyaml
```

### Package Maintenance

When updating FYAML versions:

1. Update the `version()` entries in `package.py`
2. Update SHA256 checksums for new releases
3. Test with multiple compilers and configurations
4. Update compatibility information

### Compiler Support

The package is tested with:

- GCC 11, 12, 13, 14
- Intel ifx (2025.0+)
- Intel ifort (2021.10+)
- NVIDIA HPC SDK (25.1+)

### Dependencies

- CMake 3.12 or later
- Fortran compiler (2003 standard or later)

## Integration Examples

### CMake Project

```cmake
find_package(FYAML REQUIRED)
add_executable(my_app main.f90)
target_link_libraries(my_app FYAML::fyaml)
```

### Environment Modules

```bash
# Generate modules
spack module tcl refresh fyaml

# Load via modules
module load fyaml
```

### Containerized Builds

```dockerfile
FROM spack/ubuntu-jammy:latest
RUN spack install fyaml +shared %gcc@13
RUN spack load fyaml
```
