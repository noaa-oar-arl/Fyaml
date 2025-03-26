set(_srcs
    yaml_types.F90
    yaml_parser.F90
    fyaml.F90)

add_library(fyaml ${_srcs})
set_target_properties(fyaml PROPERTIES
    Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/include
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR})
target_link_libraries(fyaml PRIVATE ${_fyaml_compiler_options})

# Install the library
install(TARGETS fyaml
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)

# Install module files
install(DIRECTORY ${CMAKE_BINARY_DIR}/include/
    DESTINATION include
    FILES_MATCHING PATTERN "*.mod")
