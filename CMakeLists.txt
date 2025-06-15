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
include(CTest)

# Enable testing with CTest
enable_testing()

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

# First ensure we're setting platform-specific flags
if(APPLE)
    # Get MacOS SDK path
    execute_process(
        COMMAND xcrun --show-sdk-path
        OUTPUT_VARIABLE SDKROOT
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    # Add MacOS specific compiler and linker flags
    list(APPEND _fyaml_compiler_options
        "-L${SDKROOT}/usr/lib"
        "-L/usr/local/lib"
        "-L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib"
        "-isysroot ${SDKROOT}"
    )

    # Set linker flags for macOS
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-no_compact_unwind -L${SDKROOT}/usr/lib")

    # Additional system paths
    include_directories(
        "${SDKROOT}/usr/include"
        "/usr/local/include"
    )
endif()

# Add debug flags for Fortran
if(CMAKE_Fortran_COMPILER_ID MATCHES "GNU" AND CMAKE_BUILD_TYPE MATCHES "Debug")
  list(
    APPEND
    _fyaml_compiler_options
    -Og
    # -Bstatic
    -Wall
    -Wextra
    -pedantic
    -fcheck=all
    -ffpe-trap=invalid,zero,overflow
    -fimplicit-none
    -fbacktrace
    -fmax-errors=0)
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "Intel" AND CMAKE_BUILD_TYPE MATCHES "Debug")
  list(
    APPEND
    _fyaml_compiler_options
    -O0
    -warn
    all
    -check
    all
    -implicitnone
    -fpe0
    -traceback
    -error-limit
    0
    -diag-disable
    6379,10448)
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "IntelLLVM" AND CMAKE_BUILD_TYPE MATCHES "Debug")
  # Intel ifx compiler (oneAPI)
  list(
    APPEND
    _fyaml_compiler_options
    -O0
    -warn
    all
    -check
    all
    -implicitnone
    -fpe0
    -traceback)
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "NVHPC" AND CMAKE_BUILD_TYPE MATCHES "Debug")
  # NVIDIA HPC SDK (nvfortran)
  list(
    APPEND
    _fyaml_compiler_options
    -O0
    -Minform=warn
    -Mchkptr
    -Mchkstk
    -traceback)
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "LFortran" AND CMAKE_BUILD_TYPE MATCHES "Debug")
  # LFortran compiler
  list(
    APPEND
    _fyaml_compiler_options
    --show-stacktrace)
endif()

# Add release flags for better optimization
if(CMAKE_BUILD_TYPE MATCHES "Release")
  if(CMAKE_Fortran_COMPILER_ID MATCHES "GNU")
    list(APPEND _fyaml_compiler_options -O3 -ffast-math)
  elseif(CMAKE_Fortran_COMPILER_ID MATCHES "Intel")
    list(APPEND _fyaml_compiler_options -O3 -xHost)
  elseif(CMAKE_Fortran_COMPILER_ID MATCHES "IntelLLVM")
    list(APPEND _fyaml_compiler_options -O3 -xHost)
  elseif(CMAKE_Fortran_COMPILER_ID MATCHES "NVHPC")
    list(APPEND _fyaml_compiler_options -O3 -fast)
  endif()
endif()

# Set the Fortran standard
set(CMAKE_Fortran_STANDARD 2003)
set(CMAKE_Fortran_STANDARD_REQUIRED ON)

# Add the source files from the src directory
add_subdirectory(src)

# Add tests if testing is enabled
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

# Installation and packaging configuration
# Set installation directories
set(CMAKE_INSTALL_CONFIGDIR ${CMAKE_INSTALL_LIBDIR}/cmake/FYAML)

# Create package config files
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FYAMLConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/FYAMLConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_CONFIGDIR}
    PATH_VARS CMAKE_INSTALL_INCLUDEDIR CMAKE_INSTALL_LIBDIR
)

# Create version file
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/FYAMLConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

# Install config files
install(
    FILES
        ${CMAKE_CURRENT_BINARY_DIR}/FYAMLConfig.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/FYAMLConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_CONFIGDIR}
)

# Export targets
install(
    EXPORT FYAMLTargets
    FILE FYAMLTargets.cmake
    NAMESPACE FYAML::
    DESTINATION ${CMAKE_INSTALL_CONFIGDIR}
)

# Export targets for build tree
export(
    EXPORT FYAMLTargets
    FILE ${CMAKE_CURRENT_BINARY_DIR}/FYAMLTargets.cmake
    NAMESPACE FYAML::
)

# Create pkg-config file
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/fyaml.pc.in
    ${CMAKE_CURRENT_BINARY_DIR}/fyaml.pc
    @ONLY
)

# Install pkg-config file
install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/fyaml.pc
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)

# Register package in user's package registry
export(PACKAGE FYAML)

# Print installation summary
message(STATUS "FYAML installation configuration:")
message(STATUS "  Version: ${PROJECT_VERSION}")
message(STATUS "  Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "  Library directory: ${CMAKE_INSTALL_FULL_LIBDIR}")
message(STATUS "  Include directory: ${CMAKE_INSTALL_FULL_INCLUDEDIR}")
message(STATUS "  CMake config directory: ${CMAKE_INSTALL_FULL_LIBDIR}/cmake/FYAML")


