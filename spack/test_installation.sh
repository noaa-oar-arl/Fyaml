#!/bin/bash
# Simple test script for FYAML Spack installation
# This script verifies that FYAML was installed correctly by Spack

set -e

echo "Testing FYAML Spack installation..."

# Check if FYAML_ROOT is set (should be set by 'spack load fyaml')
if [ -z "$FYAML_ROOT" ]; then
    echo "Warning: FYAML_ROOT not set. Try 'spack load fyaml' first."
    echo "Attempting to find FYAML installation..."

    # Try to find fyaml via spack
    if command -v spack >/dev/null 2>&1; then
        FYAML_ROOT=$(spack location -i fyaml 2>/dev/null || echo "")
    fi

    if [ -z "$FYAML_ROOT" ]; then
        echo "Error: Cannot locate FYAML installation"
        exit 1
    fi
fi

echo "FYAML installation found at: $FYAML_ROOT"

# Check for library files
echo "Checking for library files..."
if [ -f "$FYAML_ROOT/lib/libfyaml.a" ] || [ -f "$FYAML_ROOT/lib/libfyaml.so" ]; then
    echo "✓ FYAML library found"
else
    echo "✗ FYAML library not found"
    exit 1
fi

# Check for module files
echo "Checking for Fortran module files..."
if ls "$FYAML_ROOT/include"/*.mod >/dev/null 2>&1; then
    echo "✓ Fortran module files found:"
    ls "$FYAML_ROOT/include"/*.mod | xargs -n1 basename
else
    echo "✗ Fortran module files not found"
    exit 1
fi

# Check for CMake config
echo "Checking for CMake configuration..."
if [ -f "$FYAML_ROOT/lib/cmake/FYAML/FYAMLConfig.cmake" ]; then
    echo "✓ CMake configuration found"
else
    echo "✗ CMake configuration not found"
    exit 1
fi

# Check for pkg-config
echo "Checking for pkg-config..."
if [ -f "$FYAML_ROOT/lib/pkgconfig/fyaml.pc" ]; then
    echo "✓ pkg-config file found"

    # Test pkg-config
    if PKG_CONFIG_PATH="$FYAML_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH" pkg-config --exists fyaml; then
        echo "✓ pkg-config test passed"
        echo "  Version: $(PKG_CONFIG_PATH="$FYAML_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH" pkg-config --modversion fyaml)"
    else
        echo "✗ pkg-config test failed"
    fi
else
    echo "✗ pkg-config file not found"
fi

# Create a simple test program
echo "Creating test program..."
cat > test_fyaml.f90 << 'EOF'
program test_fyaml
    use fyaml
    implicit none

    type(fyaml_t) :: yml
    integer :: test_int, rc

    write(*,*) 'Testing FYAML basic functionality...'

    ! Add a simple value
    call fyaml_add(yml, "test_key", 42, "Test integer", rc)
    if (rc /= fyaml_Success) then
        write(*,*) 'Error adding value'
        stop 1
    end if

    ! Get the value back
    call fyaml_get(yml, "test_key", test_int, rc)
    if (rc /= fyaml_Success) then
        write(*,*) 'Error getting value'
        stop 1
    end if

    if (test_int /= 42) then
        write(*,*) 'Error: Expected 42, got ', test_int
        stop 1
    end if

    write(*,*) 'FYAML test passed successfully!'
    write(*,*) 'Retrieved value:', test_int

    call fyaml_cleanup(yml)
end program
EOF

# Compile test program
echo "Compiling test program..."
if PKG_CONFIG_PATH="$FYAML_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH" gfortran test_fyaml.f90 $(pkg-config --cflags --libs fyaml) -o test_fyaml; then
    echo "✓ Compilation successful"
else
    echo "✗ Compilation failed"
    exit 1
fi

# Run test program
echo "Running test program..."
if ./test_fyaml; then
    echo "✓ Test program executed successfully"
else
    echo "✗ Test program failed"
    exit 1
fi

# Clean up
rm -f test_fyaml test_fyaml.f90

echo ""
echo "🎉 All FYAML Spack installation tests passed!"
echo ""
echo "FYAML is ready to use. To use it in your projects:"
echo "  1. Load the module: spack load fyaml"
echo "  2. In CMake: find_package(FYAML REQUIRED)"
echo "  3. Link: target_link_libraries(your_target FYAML::fyaml)"
echo "  4. With pkg-config: gfortran \$(pkg-config --cflags --libs fyaml)"
