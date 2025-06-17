!> \file test_arrays.f90
!! \brief Test array functionality in FYAML

program test_arrays
    use fyaml
    use test_utils
    implicit none

    call print_test_header("Arrays")

    call test_integer_arrays()
    call test_real_arrays()
    call test_string_arrays()
    call test_boolean_arrays()
    call test_dynamic_arrays()

    call print_test_result()

    ! Exit with error code if tests failed
    if (tests_failed > 0) stop 1

contains

    subroutine test_integer_arrays()
        type(fyaml_t) :: yml
        integer, parameter :: n = 5
        integer :: int_array(n), retrieved_array(n)
        integer :: RC, i

        ! Initialize test array
        do i = 1, n
            int_array(i) = i * 10
        end do

        ! Test adding integer array
        call fyaml_add(yml, "int_array", int_array, "Test integer array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add integer array return code")

        ! Test retrieving integer array
        call fyaml_get(yml, "int_array", retrieved_array, RC)
        call assert_equal_int(fyaml_Success, RC, "Get integer array return code")

        ! Verify each element
        do i = 1, n
            call assert_equal_int(int_array(i), retrieved_array(i), "Integer array element")
        end do

        ! Test another array with different values
        int_array = [100, 200, 300, 400, 500]
        call fyaml_add(yml, "int_array2", int_array, "Second integer array", RC)
        call fyaml_get(yml, "int_array2", retrieved_array, RC)
        do i = 1, n
            call assert_equal_int(int_array(i), retrieved_array(i), "Second integer array element")
        end do

        call fyaml_cleanup(yml)
    end subroutine test_integer_arrays

    subroutine test_real_arrays()
        type(fyaml_t) :: yml
        integer, parameter :: n = 4
        real(yp) :: real_array(n), retrieved_array(n)
        integer :: RC, i

        ! Initialize test array
        real_array = [1.1_yp, 2.2_yp, 3.3_yp, 4.4_yp]

        ! Test adding real array
        call fyaml_add(yml, "real_array", real_array, "Test real array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add real array return code")

        ! Test retrieving real array
        call fyaml_get(yml, "real_array", retrieved_array, RC)
        call assert_equal_int(fyaml_Success, RC, "Get real array return code")

        ! Verify each element
        do i = 1, n
            call assert_equal_real(real_array(i), retrieved_array(i), "Real array element")
        end do

        call fyaml_cleanup(yml)
    end subroutine test_real_arrays

    subroutine test_string_arrays()
        type(fyaml_t) :: yml
        integer, parameter :: n = 3
        character(len=fyaml_NamLen) :: string_array(n), retrieved_array(n)
        integer :: RC, i

        ! Initialize test array
        string_array(1) = "first"
        string_array(2) = "second"
        string_array(3) = "third"

        ! Test adding string array
        call fyaml_add(yml, "string_array", string_array, "Test string array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add string array return code")

        ! Test retrieving string array
        call fyaml_get(yml, "string_array", retrieved_array, RC)
        call assert_equal_int(fyaml_Success, RC, "Get string array return code")

        ! Verify each element
        do i = 1, n
            call assert_equal_string(string_array(i), retrieved_array(i), "String array element")
        end do

        call fyaml_cleanup(yml)
    end subroutine test_string_arrays

    subroutine test_boolean_arrays()
        type(fyaml_t) :: yml
        integer, parameter :: n = 4
        logical :: bool_array(n), retrieved_array(n)
        integer :: RC, i

        ! Initialize test array
        bool_array = [.true., .false., .true., .false.]

        ! Test adding boolean array
        call fyaml_add(yml, "bool_array", bool_array, "Test boolean array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add boolean array return code")

        ! Test retrieving boolean array
        call fyaml_get(yml, "bool_array", retrieved_array, RC)
        call assert_equal_int(fyaml_Success, RC, "Get boolean array return code")

        ! Verify each element
        do i = 1, n
            call assert_equal_logical(bool_array(i), retrieved_array(i), "Boolean array element")
        end do

        call fyaml_cleanup(yml)
    end subroutine test_boolean_arrays

    subroutine test_dynamic_arrays()
        type(fyaml_t) :: yml
        integer, parameter :: n = 6
        integer :: dynamic_array(n)
        integer :: RC, i

        ! Initialize test array
        do i = 1, n
            dynamic_array(i) = i * i
        end do

        ! Test adding dynamic array
        call fyaml_add(yml, "dynamic_array", dynamic_array, "Test dynamic array", RC, dynamic_size=.true.)
        call assert_equal_int(fyaml_Success, RC, "Add dynamic array return code")

        call fyaml_cleanup(yml)
    end subroutine test_dynamic_arrays

end program test_arrays
