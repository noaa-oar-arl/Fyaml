# Installation

This guide provides detailed instructions for installing FYAML on your system using various methods.

## System Requirements

### Minimum Requirements

- **Fortran Compiler**:
  - GCC gfortran 10.0+
  - Intel Fortran Compiler 2021.1+
  - NAG Fortran 7.0+
- **CMake**: 3.12 or higher
- **Operating System**: Linux, macOS, Windows (with MSYS2/MinGW)

### Recommended Requirements

- **Fortran Compiler**: GCC gfortran 11+ for best compatibility
- **CMake**: 3.20+ for enhanced features
- **Memory**: 1GB RAM (for compilation)
- **Disk Space**: 50MB for source + build

## Installation Methods

### Method 1: CMake Installation (Modern)

FYAML provides full CMake package support for easy integration into other projects.

#### Build and Install

```bash
git clone https://github.com/fyaml/fyaml.git
cd fyaml
mkdir build && cd build

# Configure
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release

# Build
make -j$(nproc)

# Test (optional)
make test

# Install
sudo make install
```

#### Using in Your Project

After installation, you can easily use FYAML in your CMake projects:

```cmake
cmake_minimum_required(VERSION 3.12)
project(my_project LANGUAGES Fortran)

# Find FYAML
find_package(FYAML REQUIRED)

# Create executable
add_executable(my_program main.f90)

# Link with FYAML
target_link_libraries(my_program FYAML::fyaml)
```

#### Installation Structure

FYAML installs the following files:

```
${CMAKE_INSTALL_PREFIX}/
├── lib/
│   ├── libfyaml.a                    # Static library
│   ├── cmake/FYAML/                  # CMake package files
│   │   ├── FYAMLConfig.cmake
│   │   ├── FYAMLConfigVersion.cmake
│   │   └── FYAMLTargets.cmake
│   └── pkgconfig/fyaml.pc           # pkg-config file
└── include/
    └── *.mod                        # Fortran module files
```

#### Alternative: pkg-config

You can also use pkg-config to compile:

```bash
gfortran $(pkg-config --cflags fyaml) main.f90 $(pkg-config --libs fyaml) -o my_program
```

### Method 2: Build from Source (Traditional)

This is the most flexible method and ensures you get the latest features.

#### Step 1: Clone the Repository

```bash
git clone https://github.com/your-username/fyaml.git
cd fyaml
```

#### Step 2: Create Build Directory

```bash
mkdir build && cd build
```

#### Step 3: Configure with CMake

```bash
# Basic configuration
cmake ..

# Or with custom options
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DFYAML_BUILD_TESTS=ON \
      ..
```

#### Step 4: Build the Library

```bash
make -j$(nproc)  # Linux
make -j$(sysctl -n hw.ncpu)  # macOS
```

#### Step 5: Run Tests (Optional but Recommended)

```bash
make test
```

#### Step 6: Install (Optional)

```bash
sudo make install
```

### Method 3: Fortran Package Manager (fpm)

If you're using the Fortran Package Manager:

#### Add to Your Project

```toml
# fpm.toml
[dependencies]
fyaml = { git = "https://github.com/your-username/fyaml.git" }
```

#### Build Your Project

```bash
fpm build
```

### Method 4: Manual Integration

For projects without CMake or fpm:

#### Download Source

```bash
# Download and extract source
curl -L https://github.com/your-username/fyaml/archive/main.tar.gz | tar xz
cd fyaml-main
```

#### Copy Source Files

```bash
# Copy source files to your project
cp src/*.f90 /path/to/your/project/
```

#### Compile in Dependency Order

```bash
# Compile modules in correct order
gfortran -c src/fyaml_precision.f90
gfortran -c src/fyaml_constants.f90
gfortran -c src/fyaml_types.f90
gfortran -c src/fyaml_error.f90
gfortran -c src/fyaml_string_utils.f90
gfortran -c src/fyaml_utils.f90
gfortran -c src/fyaml.f90

# Create library archive
ar rcs libfyaml.a *.o
```

## Platform-Specific Instructions

### Linux (Ubuntu/Debian)

#### Install Dependencies

```bash
# Update package list
sudo apt update

# Install build tools
sudo apt install build-essential cmake gfortran

# Optional: Install git if not present
sudo apt install git
```

#### Build FYAML

```bash
git clone https://github.com/your-username/fyaml.git
cd fyaml
mkdir build && cd build
cmake ..
make -j$(nproc)
make test
```

### Linux (RHEL/CentOS/Fedora)

#### Install Dependencies

```bash
# RHEL/CentOS 8+
sudo dnf install gcc-gfortran cmake make git

# Older versions
sudo yum install gcc-gfortran cmake make git
```

#### Build FYAML

```bash
git clone https://github.com/your-username/fyaml.git
cd fyaml
mkdir build && cd build
cmake ..
make -j$(nproc)
make test
```

### macOS

#### Install Dependencies

Using Homebrew (recommended):

```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install gcc cmake git
```

Using MacPorts:

```bash
sudo port install gcc12 +gfortran cmake git
```

#### Build FYAML

```bash
git clone https://github.com/your-username/fyaml.git
cd fyaml
mkdir build && cd build

# Use Homebrew gfortran
export FC=/opt/homebrew/bin/gfortran-13  # Adjust version as needed
cmake ..
make -j$(sysctl -n hw.ncpu)
make test
```

### Windows

#### Using MSYS2/MinGW-w64

1. **Install MSYS2** from [msys2.org](https://www.msys2.org/)

2. **Open MSYS2 MINGW64 terminal** and install dependencies:

```bash
pacman -S mingw-w64-x86_64-gcc-fortran mingw-w64-x86_64-cmake mingw-w64-x86_64-make git
```

3. **Build FYAML**:

```bash
git clone https://github.com/your-username/fyaml.git
cd fyaml
mkdir build && cd build
cmake -G "MinGW Makefiles" ..
mingw32-make
mingw32-make test
```

#### Using Visual Studio with Intel Fortran

1. **Install Intel Fortran Compiler** integrated with Visual Studio
2. **Use CMake GUI** or command line with Intel toolchain
3. **Generate Visual Studio solution**:

```cmd
cmake -G "Visual Studio 16 2019" -T "Intel Fortran" ..
cmake --build . --config Release
ctest -C Release
```

## CMake Configuration Options

### Standard Options

| Option | Default | Description |
|--------|---------|-------------|
| `CMAKE_BUILD_TYPE` | `Debug` | Build type: Debug, Release, RelWithDebInfo |
| `CMAKE_INSTALL_PREFIX` | `/usr/local` | Installation directory |
| `CMAKE_Fortran_COMPILER` | Auto-detected | Fortran compiler to use |

### FYAML-Specific Options

| Option | Default | Description |
|--------|---------|-------------|
| `FYAML_BUILD_TESTS` | `ON` | Build test suite |
| `FYAML_BUILD_EXAMPLES` | `ON` | Build example programs |
| `FYAML_INSTALL_MODULES` | `ON` | Install Fortran module files |
| `FYAML_USE_DOUBLE_PRECISION` | `ON` | Use double precision for reals |

### Example Custom Configuration

```bash
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$HOME/.local \
      -DFYAML_BUILD_TESTS=OFF \
      -DFYAML_USE_DOUBLE_PRECISION=OFF \
      ..
```

## Verification

### Test Installation

Create a simple test program:

```fortran
! test_install.f90
program test_install
    use fyaml
    implicit none
    write(*,*) "FYAML installation successful!"
end program
```

Compile and run:

```bash
# If installed system-wide
gfortran -o test_install test_install.f90 -lfyaml

# If built locally
gfortran -I../build/include -L../build/src -o test_install test_install.f90 -lfyaml

./test_install
```

### Run Full Test Suite

```bash
cd build
make test

# Or run specific tests
ctest -R "test_basic"
ctest --verbose
```

## Integration with Your Project

### Using CMake

```cmake
# CMakeLists.txt
find_package(FYAML REQUIRED)

add_executable(myapp main.f90)
target_link_libraries(myapp FYAML::fyaml)
```

### Using pkg-config

```bash
# Compile using pkg-config
gfortran $(pkg-config --cflags fyaml) -o myapp main.f90 $(pkg-config --libs fyaml)
```

### Manual Linking

```bash
# Direct linking
gfortran -I/usr/local/include -L/usr/local/lib -o myapp main.f90 -lfyaml
```

## Performance Optimization

### Release Build

Always use Release mode for production:

```bash
cmake -DCMAKE_BUILD_TYPE=Release ..
```

### Compiler Optimization

Enable additional optimizations:

```bash
export FFLAGS="-O3 -march=native -mtune=native"
cmake ..
```

### Link-Time Optimization

For maximum performance:

```bash
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
      ..
```

## Troubleshooting

### Common Issues

#### Compiler Not Found

```
Error: CMAKE_Fortran_COMPILER not set
```

**Solution:**
```bash
export FC=gfortran  # or ifort, etc.
cmake ..
```

#### Module Path Issues

```
Error: Can't open module file 'fyaml.mod'
```

**Solution:**
```bash
# Ensure module path is correct
gfortran -I/path/to/fyaml/modules ...
```

#### Linking Errors

```
Error: undefined reference to fyaml_init
```

**Solution:**
```bash
# Ensure library is linked
gfortran ... -L/path/to/fyaml/lib -lfyaml
```

### Getting Help

1. **Check Requirements**: Verify all dependencies are installed
2. **Clean Build**: Remove `build/` directory and rebuild
3. **Verbose Output**: Use `make VERBOSE=1` for detailed build info
4. **Check Issues**: Search [GitHub Issues](https://github.com/your-username/fyaml/issues)
5. **Create Issue**: Report new problems with full error details

### Environment Variables

Useful environment variables for debugging:

```bash
export FC=gfortran                    # Force Fortran compiler
export FFLAGS="-g -O0 -fcheck=all"   # Debug flags
export CMAKE_VERBOSE_MAKEFILE=ON     # Verbose CMake output
export CTEST_OUTPUT_ON_FAILURE=1     # Show test failures
```

## Next Steps

After successful installation:

1. **[Quick Start](quick-start.md)** - Write your first FYAML program
2. **[Examples](examples.md)** - Explore usage patterns
3. **[User Guide](../user-guide/basic-usage.md)** - Comprehensive documentation
4. **[API Reference](../api/overview.md)** - Complete function reference
