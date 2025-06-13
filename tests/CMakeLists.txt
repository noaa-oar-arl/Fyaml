# CMakeLists.txt for FYAML tests

# Test configuration
set(FYAML_TEST_DATA_DIR "${CMAKE_SOURCE_DIR}/test_data")

# First create the test utilities library
add_library(test_utils STATIC test_utils.f90)
target_link_libraries(test_utils FYAML::fyaml)
target_include_directories(test_utils PRIVATE ${CMAKE_BINARY_DIR}/include)
target_compile_options(test_utils PRIVATE ${_fyaml_compiler_options})

# Create test executables and register them with CTest
function(add_fyaml_test test_name source_file)
    add_executable(${test_name} ${source_file})
    target_link_libraries(${test_name} FYAML::fyaml test_utils)
    target_include_directories(${test_name} PRIVATE ${CMAKE_BINARY_DIR}/include)

    # Set compiler options for tests
    target_compile_options(${test_name} PRIVATE ${_fyaml_compiler_options})

    # Register test with CTest
    add_test(NAME ${test_name} COMMAND ${test_name})

    # Set test environment to include data directory
    set_tests_properties(${test_name} PROPERTIES
        ENVIRONMENT "FYAML_TEST_DATA_DIR=${FYAML_TEST_DATA_DIR}"
    )
endfunction()

# Basic functionality tests
add_fyaml_test(test_basic_types test_basic_types.f90)
add_fyaml_test(test_arrays test_arrays.f90)
add_fyaml_test(test_strings test_strings.f90)
add_fyaml_test(test_booleans test_booleans.f90)

# File parsing tests
add_fyaml_test(test_file_parsing test_file_parsing.f90)
add_fyaml_test(test_categories test_categories.f90)
add_fyaml_test(test_anchors test_anchors.f90)

# Advanced functionality tests
add_fyaml_test(test_species_parsing test_species_parsing.f90)
add_fyaml_test(test_config_merging test_config_merging.f90)
add_fyaml_test(test_config_printing test_config_printing.f90)

# Utility function tests
add_fyaml_test(test_string_utils test_string_utils.f90)
add_fyaml_test(test_error_handling test_error_handling.f90)

# Performance tests
add_fyaml_test(test_large_file test_large_file.f90)
add_fyaml_test(test_sorting test_sorting.f90)

# Integration test
add_fyaml_test(test_integration test_integration.f90)

# API coverage test
add_fyaml_test(test_api_functions test_api_functions.f90)

# Edge cases and error path tests
add_fyaml_test(test_edge_cases test_edge_cases.f90)

# Comprehensive array tests
add_fyaml_test(test_comprehensive_arrays test_comprehensive_arrays.f90)

# Custom test target to run all tests
add_custom_target(run_tests
    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
    DEPENDS test_basic_types test_arrays test_strings test_booleans
            test_file_parsing test_categories test_anchors
            test_species_parsing test_config_merging test_config_printing
            test_string_utils test_error_handling
            test_large_file test_sorting test_integration test_api_functions
            test_edge_cases test_comprehensive_arrays
    COMMENT "Running FYAML test suite"
)
