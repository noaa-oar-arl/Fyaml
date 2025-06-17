# Testing

This document describes the testing framework and methodology used in the FYAML project.

## Testing Philosophy

FYAML follows a comprehensive testing approach to ensure reliability and correctness:

1. **Unit Tests**: Test individual components in isolation
2. **Integration Tests**: Test how components work together
3. **Functional Tests**: Test end-to-end functionality
4. **Performance Tests**: Evaluate performance characteristics
5. **Conformance Tests**: Ensure compliance with the YAML specification

## Test Organization

The tests are organized in the `tests/` directory:

```
tests/
├── CMakeLists.txt                # Test configuration
├── test_utils.f90                # Common test utilities
├── test_basic_types.f90          # Tests for basic YAML types
├── test_arrays.f90               # Tests for array handling
├── test_anchors.f90              # Tests for anchors and aliases
├── test_booleans.f90             # Tests for boolean handling
├── test_categories.f90           # Tests for category handling
├── test_config_merging.f90       # Tests for config merging
├── test_config_printing.f90      # Tests for config output
├── test_error_handling.f90       # Tests for error handling
├── test_file_parsing.f90         # Tests for file parsing
├── test_integration.f90          # End-to-end integration tests
├── test_large_file.f90           # Performance tests with large files
├── test_sorting.f90              # Tests for map key sorting
├── test_species_parsing.f90      # Tests for species file parsing
├── test_string_utils.f90         # Tests for string utilities
└── test_strings.f90              # Tests for string handling
```

## Running Tests

### Running All Tests

From the build directory:

```bash
ctest
```

Or:

```bash
make test
```

### Running Specific Tests

To run a specific test:

```bash
ctest -R test_arrays
```

To run tests with verbose output:

```bash
ctest -V -R test_arrays
```

### Running Tests with Different Compilers

You can set up different build directories for different compilers:

```bash
mkdir build-gfortran && cd build-gfortran
FC=gfortran cmake .. -DCMAKE_BUILD_TYPE=Debug -DFYAML_BUILD_TESTS=ON
make && ctest

mkdir build-ifort && cd build-ifort
FC=ifort cmake .. -DCMAKE_BUILD_TYPE=Debug -DFYAML_BUILD_TESTS=ON
make && ctest
```

## Writing Tests

### Test Structure

Each test program follows a similar structure:

```fortran
program test_feature
  use fyaml
  use test_utils  ! Common testing utilities
  implicit none

  logical :: test_passed

  ! Run the tests
  test_passed = test_case_1() .and. &
                test_case_2() .and. &
                test_case_3()

  ! Report overall result
  if (test_passed) then
    write(*,*) "All tests passed!"
    stop 0  ! Success
  else
    write(*,*) "Some tests failed!"
    stop 1  ! Failure
  end if

contains

  logical function test_case_1() result(success)
    ! Test implementation
    success = .true.  ! Default to success

    ! Test logic
    ! ...

    if (expected_value /= actual_value) then
      write(*,*) "Test case 1 failed: Expected ", expected_value, &
                 " but got ", actual_value
      success = .false.
    end if
  end function test_case_1

  ! More test cases...

end program test_feature
```

### Test Utilities

The `test_utils` module provides common utilities for testing:

```fortran
module test_utils
  implicit none

  ! Constants for test file paths
  character(len=*), parameter :: TEST_DATA_DIR = "../test_data/"

  ! Assertion helpers
  public :: assert_equal, assert_true, assert_false

  ! File helpers
  public :: create_temp_file, delete_temp_file

contains

  ! Implementation of utility functions
  ! ...

end module test_utils
```

### Adding a New Test

1. Create a new test file in the `tests/` directory:

   ```bash
   touch tests/test_new_feature.f90
   ```

2. Add the test to `tests/CMakeLists.txt`:

   ```cmake
   # Add test executable
   add_executable(test_new_feature test_new_feature.f90)
   target_link_libraries(test_new_feature PRIVATE fyaml test_utils)

   # Register with CTest
   add_test(NAME test_new_feature COMMAND test_new_feature)
   ```

3. Implement your test using the standard structure.

### Test Data

Reference test files are stored in the `test_data/` directory:

```
test_data/
├── example_config.yml
├── anchors.yml
├── arrays.yml
├── categories.yml
└── error_cases/
    ├── duplicate_keys.yml
    ├── invalid_syntax.yml
    └── circular_reference.yml
```

Use these files in your tests:

```fortran
logical function test_file_parsing() result(success)
  use fyaml
  implicit none

  type(fyaml_config) :: config
  logical :: status

  success = .true.

  ! Parse test file
  status = fyaml_parse_file(config, TEST_DATA_DIR // "example_config.yml")
  if (.not. status) then
    write(*,*) "Failed to parse example config file"
    success = .false.
    return
  end if

  ! Test assertions
  ! ...

end function test_file_parsing
```

## Continuous Integration

FYAML uses GitHub Actions for continuous integration:

- Tests are run on every push and pull request
- Multiple compilers are tested (GCC, Intel)
- Multiple platforms are tested (Linux, macOS)

## Test Coverage

To generate test coverage reports:

1. Build with coverage flags:

   ```bash
   cmake .. -DCMAKE_BUILD_TYPE=Debug -DFYAML_BUILD_TESTS=ON -DFYAML_ENABLE_COVERAGE=ON
   make
   ```

2. Run the tests:

   ```bash
   make test
   ```

3. Generate coverage report:

   ```bash
   make coverage
   ```

## Performance Testing

Performance tests are included to ensure FYAML remains efficient:

- `test_large_file.f90`: Tests parsing of large YAML files
- `test_benchmark.f90`: Micro-benchmarks for critical operations

Run performance tests separately:

```bash
ctest -R test_large_file
```

## Conformance Testing

FYAML aims to conform to the YAML 1.2 specification:

- `test_spec_conformance.f90`: Tests conformance with the YAML spec
- Test cases are based on examples from the YAML specification

## Troubleshooting Tests

If tests are failing:

1. Run with verbose output:
   ```bash
   ctest -V -R failing_test
   ```

2. Check for compiler-specific issues:
   ```bash
   FC=different_compiler cmake .. -DCMAKE_BUILD_TYPE=Debug -DFYAML_BUILD_TESTS=ON
   make && ctest
   ```

3. Use debug mode:
   ```fortran
   ! Enable debug output in your test
   call fyaml_set_debug(.true.)
   ```
