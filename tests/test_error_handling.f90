!> \file test_error_handling.f90
!! \brief Test error handling functionality

program test_error_handling
    use fyaml
    use test_utils
    implicit none

    call print_test_header("Error Handling")

    call test_file_not_found()
    call test_invalid_variable_access()
    call test_type_mismatch()

    call print_test_result()

    ! Exit with error code if tests failed
    if (tests_failed > 0) stop 1

contains

    subroutine test_file_not_found()
        type(fyaml_t) :: yml
        integer :: RC

        ! Try to read non-existent file
        call fyaml_read_file(yml, "non_existent_file.yml", RC)
        call assert_not_equal_int(fyaml_Success, RC, "Non-existent file error code")

        call fyaml_cleanup(yml)
    end subroutine test_file_not_found

    subroutine test_invalid_variable_access()
        type(fyaml_t) :: yml
        integer :: int_val, RC

        ! Try to get non-existent variable
        call fyaml_get(yml, "non_existent_var", int_val, RC)
        call assert_not_equal_int(fyaml_Success, RC, "Non-existent variable error code")

        call fyaml_cleanup(yml)
    end subroutine test_invalid_variable_access

    subroutine test_type_mismatch()
        type(fyaml_t) :: yml
        integer :: int_val, RC
        real(yp) :: real_val

        ! Add a string, try to get as integer
        call fyaml_add(yml, "string_var", "hello", "String variable", RC)
        call fyaml_get(yml, "string_var", int_val, RC)
        call assert_not_equal_int(fyaml_Success, RC, "Type mismatch error code")

        ! Add an integer, try to get as real (this might work due to type conversion)
        call fyaml_add(yml, "int_var", 42, "Integer variable", RC)
        call fyaml_get(yml, "int_var", real_val, RC)
        ! This test depends on implementation - might succeed or fail

        call fyaml_cleanup(yml)
    end subroutine test_type_mismatch

end program test_error_handling
