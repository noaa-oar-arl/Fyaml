!> \file test_basic_types.f90
!! \brief Test basic data types functionality in FYAML

program test_basic_types
    use fyaml
    use test_utils
    implicit none

    call print_test_header("Basic Types")

    call test_integer_operations()
    call test_real_operations()
    call test_string_operations()
    call test_boolean_operations()

    call print_test_result()

    ! Exit with error code if tests failed
    if (tests_failed > 0) stop 1

contains

    subroutine test_integer_operations()
        type(fyaml_t) :: yml
        integer :: value, RC

        ! Test adding and getting integer
        call fyaml_add(yml, "test_int", 42, "Test integer", RC)
        call assert_equal_int(fyaml_Success, RC, "Add integer return code")

        call fyaml_get(yml, "test_int", value, RC)
        call assert_equal_int(fyaml_Success, RC, "Get integer return code")
        call assert_equal_int(42, value, "Integer value retrieval")

        ! Test different integer value
        call fyaml_add(yml, "test_int2", 100, "Test integer 2", RC)
        call fyaml_get(yml, "test_int2", value, RC)
        call assert_equal_int(100, value, "Second integer value")

        ! Test negative integer
        call fyaml_add(yml, "negative_int", -25, "Negative integer", RC)
        call fyaml_get(yml, "negative_int", value, RC)
        call assert_equal_int(-25, value, "Negative integer")

        ! Test zero
        call fyaml_add(yml, "zero_int", 0, "Zero integer", RC)
        call fyaml_get(yml, "zero_int", value, RC)
        call assert_equal_int(0, value, "Zero integer")

        call fyaml_cleanup(yml)
    end subroutine test_integer_operations

    subroutine test_real_operations()
        type(fyaml_t) :: yml
        real(yp) :: value
        integer :: RC

        ! Test adding and getting real
        call fyaml_add(yml, "test_real", 3.14159_yp, "Test real", RC)
        call assert_equal_int(fyaml_Success, RC, "Add real return code")

        call fyaml_get(yml, "test_real", value, RC)
        call assert_equal_int(fyaml_Success, RC, "Get real return code")
        call assert_equal_real(3.14159_yp, value, "Real value retrieval")

        ! Test scientific notation
        call fyaml_add(yml, "sci_real", 1.23e-10_yp, "Scientific notation", RC)
        call fyaml_get(yml, "sci_real", value, RC)
        call assert_equal_real(1.23e-10_yp, value, "Scientific notation real")

        ! Test negative real
        call fyaml_add(yml, "negative_real", -2.718_yp, "Negative real", RC)
        call fyaml_get(yml, "negative_real", value, RC)
        call assert_equal_real(-2.718_yp, value, "Negative real")

        ! Test zero real
        call fyaml_add(yml, "zero_real", 0.0_yp, "Zero real", RC)
        call fyaml_get(yml, "zero_real", value, RC)
        call assert_equal_real(0.0_yp, value, "Zero real")

        call fyaml_cleanup(yml)
    end subroutine test_real_operations

    subroutine test_string_operations()
        type(fyaml_t) :: yml
        character(len=fyaml_StrLen) :: value
        integer :: RC

        ! Test adding and getting string
        call fyaml_add(yml, "test_string", "Hello World", "Test string", RC)
        call assert_equal_int(fyaml_Success, RC, "Add string return code")

        call fyaml_get(yml, "test_string", value, RC)
        call assert_equal_int(fyaml_Success, RC, "Get string return code")
        call assert_equal_string("Hello World", value, "String value retrieval")

        ! Test empty string
        call fyaml_add(yml, "empty_string", "", "Empty string", RC)
        call fyaml_get(yml, "empty_string", value, RC)
        call assert_equal_string("", value, "Empty string")

        ! Test string with special characters
        call fyaml_add(yml, "special_string", "String with quotes", "Special chars", RC)
        call fyaml_get(yml, "special_string", value, RC)
        call assert_equal_string("String with quotes", value, "Special characters in string")

        ! Test long string
        call fyaml_add(yml, "long_string", &
            "This is a very long string that tests the ability of FYAML to handle longer text content", &
            "Long string", RC)
        call fyaml_get(yml, "long_string", value, RC)
        call assert_equal_string( &
            "This is a very long string that tests the ability of FYAML to handle longer text content", &
            value, "Long string")

        call fyaml_cleanup(yml)
    end subroutine test_string_operations

    subroutine test_boolean_operations()
        type(fyaml_t) :: yml
        logical :: value
        integer :: RC

        ! Test adding and getting boolean true
        call fyaml_add(yml, "test_bool_true", .true., "Test boolean true", RC)
        call assert_equal_int(fyaml_Success, RC, "Add boolean true return code")

        call fyaml_get(yml, "test_bool_true", value, RC)
        call assert_equal_int(fyaml_Success, RC, "Get boolean true return code")
        call assert_true(value, "Boolean true value retrieval")

        ! Test adding and getting boolean false
        call fyaml_add(yml, "test_bool_false", .false., "Test boolean false", RC)
        call fyaml_get(yml, "test_bool_false", value, RC)
        call assert_false(value, "Boolean false value retrieval")

        ! Test another boolean
        call fyaml_add(yml, "test_bool_another", .true., "Another boolean", RC)
        call fyaml_get(yml, "test_bool_another", value, RC)
        call assert_true(value, "Another boolean value")

        call fyaml_cleanup(yml)
    end subroutine test_boolean_operations

end program test_basic_types
