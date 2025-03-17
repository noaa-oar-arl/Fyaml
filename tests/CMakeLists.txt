set(_srcs
    test_utils.F90)

add_compile_options(${_fyaml_compiler_options})

# Set up module and include directories
set(TEST_MODULE_DIR ${CMAKE_CURRENT_BINARY_DIR}/modules)
file(MAKE_DIRECTORY ${TEST_MODULE_DIR})

enable_testing()

# Build test_utils library first
add_library(test_utils OBJECT ${_srcs})
target_link_libraries(test_utils PUBLIC fyaml)  # Changed to PUBLIC
target_include_directories(test_utils PUBLIC
    $<BUILD_INTERFACE:${TEST_MODULE_DIR}>
    $<TARGET_PROPERTY:fyaml,Fortran_MODULE_DIRECTORY>)  # Get fyaml module dir
set_target_properties(test_utils PROPERTIES
    Fortran_MODULE_DIRECTORY ${TEST_MODULE_DIR})

# Individual test executables
add_executable(test_basic_loading test_basic_loading_main.F90)
add_executable(test_basic_types test_basic_types_main.F90)
add_executable(test_sequences test_sequences_main.F90)
add_executable(test_nested_access test_nested_access_main.F90)
add_executable(test_get_value test_get_value_main.F90)
add_executable(test_get_values test_get_values_main.F90)
add_executable(test_multiple_docs test_multiple_docs_main.F90)
add_executable(test_root_keys test_root_keys_main.F90)
add_executable(test_anchors_aliases test_anchors_aliases_main.F90)

foreach(test IN ITEMS
    test_basic_loading test_basic_types test_sequences
    test_nested_access test_get_value test_get_values
    test_multiple_docs test_root_keys test_anchors_aliases)
    # Link with test_utils and fyaml
    target_link_libraries(${test} PRIVATE test_utils)  # fyaml comes transitively
    # Set include paths for modules
    target_include_directories(${test} PRIVATE
        ${CMAKE_BINARY_DIR}/modules
        ${TEST_MODULE_DIR})
    set_target_properties(${test} PROPERTIES
        Fortran_MODULE_DIRECTORY ${TEST_MODULE_DIR})
    # Add dependencies
    add_dependencies(${test} test_utils)
endforeach()

# Copy test files
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/test_example.yaml
               ${CMAKE_CURRENT_BINARY_DIR}/test_example.yaml COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/test_example_multi_doc.yaml
               ${CMAKE_CURRENT_BINARY_DIR}/test_example_multi_doc.yaml COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/test_example_anchors.yaml
               ${CMAKE_CURRENT_BINARY_DIR}/test_example_anchors.yaml COPYONLY)

# Add tests
foreach(test IN ITEMS
    basic_loading basic_types sequences
    nested_access get_value get_values
    multiple_docs root_keys anchors_aliases)
    add_test(
        NAME test_${test}
        COMMAND test_${test}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
endforeach()
