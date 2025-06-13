#!/bin/bash

# FYAML Coverage Testing Script
# This script sets up the proper environment and runs coverage testing

set -e

echo "=== FYAML Coverage Testing ==="
echo ""

# Set up environment for consistent toolchain
export PATH="/opt/homebrew/bin:$PATH"
export FC="/opt/homebrew/bin/gfortran"

# Check if the required tools are available
if ! command -v /opt/homebrew/bin/gfortran &> /dev/null; then
    echo "Error: Homebrew gfortran not found. Please install it with:"
    echo "  brew install gcc"
    exit 1
fi

if ! command -v /opt/homebrew/bin/gcov-14 &> /dev/null; then
    echo "Error: gcov-14 not found. It should be installed with GCC from Homebrew."
    exit 1
fi

echo "✓ Using gfortran: $(which gfortran)"
echo "✓ Using gcov: /opt/homebrew/bin/gcov-14"
echo ""

# Clean and build
echo "=== Cleaning and configuring ==="
rm -rf build-coverage
mkdir build-coverage
cd build-coverage

cmake \
    -DFYAML_ENABLE_COVERAGE=ON \
    -DBUILD_TESTING=ON \
    -DCMAKE_Fortran_COMPILER=/opt/homebrew/bin/gfortran \
    -DGCOV_PATH=/opt/homebrew/bin/gcov-14 \
    ..

echo ""
echo "=== Building with coverage ==="
make -j$(sysctl -n hw.ncpu)

echo ""
echo "=== Running coverage ==="
make coverage

echo ""
echo "=== Coverage Summary ==="
echo "Generated coverage files:"
ls -la *.gcov | grep -E "(fyaml|src).*\.gcov$" | head -10

echo ""
echo "✓ Coverage analysis complete!"
echo "  Check the *.gcov files in build-coverage/ for detailed line-by-line coverage"
echo "  Lines marked with ##### were not executed and need more test coverage"
