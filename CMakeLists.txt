# Minimum CMake version required
cmake_minimum_required(VERSION 3.12)

# Project name and language
project(
    FYAML
    VERSION 0.2.0
    DESCRIPTION "A comprehensive Fortran library for parsing YAML files"
    HOMEPAGE_URL "https://github.com/fyaml/fyaml"
    LANGUAGES Fortran)

# Include standard CMake modules
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(CMakePrintHelpers)

# Set testing to OFF by default (users can enable with -DBUILD_TESTING=ON)
option(BUILD_TESTING "Build the testing tree" OFF)

# Include CTest only if testing is enabled
if(BUILD_TESTING)
    include(CTest)
    enable_testing()
endif()

# Set build type to Debug if not specified
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

cmake_print_variables(CMAKE_Fortran_COMPILER CMAKE_Fortran_COMPILER_ID CMAKE_BUILD_TYPE)

# Set default compiler options for Fortran
set(_fyaml_compiler_options "")

# Options for building (need to be defined early)
option(FYAML_BUILD_EXAMPLES "Build example programs" ON)
option(FYAML_ENABLE_COVERAGE "Enable code coverage" OFF)

# Coverage configuration (must be before add_subdirectory)
if(FYAML_ENABLE_COVERAGE)
    if(CMAKE_Fortran_COMPILER_ID MATCHES "GNU")
        message(STATUS "Enabling code coverage with GCC")
        list(APPEND _fyaml_compiler_options --coverage -fprofile-arcs -ftest-coverage -O0 -g)
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} --coverage")

        # Find gcov (comes with GCC)
        find_program(GCOV_PATH gcov)

        if(GCOV_PATH)
            message(STATUS "Found gcov: ${GCOV_PATH}")

            # Add custom target for coverage report using gcov
            add_custom_target(coverage
                COMMAND ${CMAKE_COMMAND} -E echo "Running tests to generate coverage data..."
                COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
                COMMAND ${CMAKE_COMMAND} -E echo "Generating coverage reports with gcov..."
                COMMAND find ${CMAKE_BINARY_DIR} -name "*.gcda" -exec ${GCOV_PATH} {} +
                COMMAND ${CMAKE_COMMAND} -E echo "Coverage files (.gcov) generated in build directory"
                COMMAND ${CMAKE_COMMAND} -E echo "Look for *.gcov files to see line-by-line coverage"
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                COMMENT "Generating code coverage report with gcov"
                VERBATIM
            )
        else()
            message(WARNING "gcov not found. It should be available with your GCC installation.")
        endif()
    else()
        message(WARNING "Code coverage only supported with GCC compiler")
    endif()
endif()