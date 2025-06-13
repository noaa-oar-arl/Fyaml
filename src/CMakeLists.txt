# CMakeLists.txt for FYAML source directory

# Define the source files for the FYAML library
set(FYAML_SOURCES
    fyaml_precision.f90
    fyaml_constants.f90
    fyaml_types.f90
    fyaml_error.f90
    fyaml_string_utils.f90
    fyaml_utils.f90
    fyaml.f90
)

# Create the FYAML library
add_library(fyaml STATIC ${FYAML_SOURCES})

# Create an alias for the library that can be used by tests and examples
add_library(FYAML::fyaml ALIAS fyaml)

# Set compiler options for the library
target_compile_options(fyaml PRIVATE ${_fyaml_compiler_options})

# Disable specific warnings for placeholder implementations
if(CMAKE_Fortran_COMPILER_ID MATCHES "GNU")
    target_compile_options(fyaml PRIVATE -Wno-unused-dummy-argument)
endif()

# Set the module output directory
set_target_properties(fyaml PROPERTIES
    Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/include
    OUTPUT_NAME fyaml
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
    EXPORT_NAME fyaml
)

# Set interface include directories so other targets can find the modules
target_include_directories(fyaml PUBLIC
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

# Install the library and modules
install(
    TARGETS fyaml
    EXPORT FYAMLTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Install Fortran module files
install(
    DIRECTORY ${CMAKE_BINARY_DIR}/include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING PATTERN "*.mod"
)
