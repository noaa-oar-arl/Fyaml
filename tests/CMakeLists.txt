set(_srcs
    test_utils.F90)

add_compile_options(${_fyaml_compiler_options})

add_compile_definitions(SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}")

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

foreach(test IN ITEMS
    test_basic_loading test_basic_types test_sequences
    test_nested_access test_get_value test_get_values
    test_multiple_docs test_root_keys test_anchors_aliases)
    # Add executable
    add_executable(${test} ${test}_main.F90)
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
    # Add test
    add_test(
        NAME ${test}
        COMMAND ${test})
endforeach()
