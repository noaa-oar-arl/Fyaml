# Minimum CMake version required
cmake_minimum_required(VERSION 3.10)

# Project name and language
project(
    Fyaml
    VERSION 0.1.0
    LANGUAGES Fortran)

include(CMakePrintHelpers)

# Set build type to Debug if not specified
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

cmake_print_variables(CMAKE_Fortran_COMPILER CMAKE_Fortran_COMPILER_ID CMAKE_BUILD_TYPE)

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

# Set default compiler options for Fortran
set(_fyaml_compiler_options "")
set(_fyaml_link_options "")

if(CMAKE_Fortran_COMPILER_ID MATCHES "GNU")
  list(APPEND _fyaml_compiler_options -ffree-line-length-none)
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
endif()
if(CMAKE_Fortran_COMPILER_ID MATCHES "IntelLLVM" AND CMAKE_BUILD_TYPE MATCHES "Debug")
  list(APPEND _fyaml_link_options -check;all)
endif()

# Set the Fortran standard
set(CMAKE_Fortran_STANDARD 2003)
set(CMAKE_Fortran_STANDARD_REQUIRED ON)

# Add the source files from the src directory
add_subdirectory(src)
add_subdirectory(tests)
add_subdirectory(example)
